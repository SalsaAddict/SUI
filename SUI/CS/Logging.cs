using Newtonsoft.Json;
using System;
using System.Data;
using System.Data.SqlClient;
using System.Diagnostics;
using System.Web;
using System.Web.Configuration;

namespace SUI
{

    public static class Logging
    {

        public static readonly string UnexpectedError = "An unexpected error occurred.";
        public static readonly string LoggingError = "Unable to log error message.";

        public static void LogError(HttpContext Context, Procedure Procedure, Exception Exception, bool Reauthenticate)
        {

            string Message;
            if (Exception.Message.StartsWith("sui:"))
            {
                string[] Split = Exception.Message.Split(":".ToCharArray());
                Message = Split[1];
            }
            else if (Exception.Message.Contains("Cannot insert duplicate key"))
            {
                Message = "A similar record already exists.";
            }
            else { Message = UnexpectedError; }

            string IPAddress = Context.Request.UserHostAddress;
            if (string.IsNullOrWhiteSpace(IPAddress)) IPAddress = "Unknown";

            int UserId;
            try { UserId = Security.UserIdFromToken(Procedure.Token); }
            catch { UserId = 0; }

            string ProcedureXML;
            try { ProcedureXML = JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Procedure), "Procedure").InnerXml; }
            catch { ProcedureXML = null; }
            if (string.IsNullOrWhiteSpace(ProcedureXML)) ProcedureXML = null;

            try
            {
                using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
                {
                    Connection.Open();
                    using (SqlCommand Command = new SqlCommand("apiErrorLog", Connection))
                    {
                        Command.CommandType = CommandType.StoredProcedure;
                        Command.Parameters.AddWithValue("IPAddress", IPAddress);
                        Command.Parameters.AddWithValue("Url", Context.Request.Path);
                        Command.Parameters.AddWithValue("UserId", UserId);
                        Command.Parameters.AddWithValue("Procedure", ProcedureXML);
                        Command.Parameters.AddWithValue("Exception", Exception.Message);
                        Command.Parameters.AddWithValue("Message", Message);
                        Command.Parameters.AddWithValue("StackTrace", new StackTrace(Exception, true).ToString());
                        Command.ExecuteNonQuery();
                    }
                    Connection.Close();
                }
            }
            catch (Exception Ex) { Message = Ex.Message; }

            new Response(Message, Reauthenticate).Write(Context);
            return;

        }

    }

}