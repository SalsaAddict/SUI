using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Newtonsoft.Json;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using System.Xml;
using System.IO;
using System.Text;

namespace SUI
{

    public class Exec : IHttpHandler
    {

        public void ProcessRequest(HttpContext Context)
        {
            Context.Response.ContentType = "text/json";
            Procedure Procedure = null;
            try
            {
                if (!Procedure.TryParse(Context, out Procedure)) throw new InvalidOperationException("sui:Invalid request");
                if (string.IsNullOrWhiteSpace(Procedure.Token)) throw new UnauthorizedAccessException("sui:You must login to continue");
                Security.VerifyUser(Procedure.Token);
                using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
                {
                    Connection.Open();
                    using (SqlTransaction Transaction = Connection.BeginTransaction(IsolationLevel.Serializable))
                    {
                        try
                        {
                            using (SqlCommand Command = new SqlCommand(Procedure.Name, Connection, Transaction))
                            {
                                Command.CommandType = CommandType.StoredProcedure;
                                foreach (Parameter Parameter in Procedure.Parameters)
                                {
                                    if (Parameter.XML)
                                        Command.Parameters.AddWithValue(Parameter.Name, JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Parameter.Value), "object").InnerXml);
                                    else
                                        Command.Parameters.AddWithValue(Parameter.Name, Parameter.Value);
                                }
                                Command.Parameters.AddWithValue("UserId", Security.UserIdFromToken(Procedure.Token));
                                if (Procedure.Type == "object")
                                {
                                    using (XmlReader Reader = Command.ExecuteXmlReader())
                                    {
                                        XmlDocument Document = new XmlDocument();
                                        Document.Load(Reader);
                                        string jsonData = JsonConvert.SerializeXmlNode(Document, Newtonsoft.Json.Formatting.Indented);
                                        new Response(JsonConvert.DeserializeObject(jsonData)).Write(Context);
                                    }
                                }
                                else
                                {
                                    using (SqlDataReader Reader = Command.ExecuteReader((Procedure.Type == "singleton") ? CommandBehavior.SingleRow : CommandBehavior.SingleResult))
                                    {
                                        using (DataTable Table = new DataTable())
                                        {
                                            Table.Load(Reader);
                                            string jsonData = JsonConvert.SerializeObject(Table, Newtonsoft.Json.Formatting.Indented);
                                            new Response(JsonConvert.DeserializeObject(jsonData)).Write(Context);
                                        }
                                    }
                                }
                                Transaction.Commit();
                            }
                        }
                        catch (Exception Exception) { Transaction.Rollback(); throw Exception; }
                    }
                    Connection.Close();
                }
            }
            catch (UnauthorizedAccessException Exception) { Logging.LogError(Context, Procedure, Exception, true); }
            catch (Exception Exception) { Logging.LogError(Context, Procedure, Exception, false); }
        }

        public bool IsReusable { get { return false; } }

    }

}