using Newtonsoft.Json;
using System;
using System.Web;
using System.IO;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;

namespace SUI
{

    public class Login : IHttpHandler
    {

        public void ProcessRequest(HttpContext Context)
        {
            LoginRequest Credentials;
            if (!LoginRequest.TryParse(Context, out Credentials)) { Logging.LogError(Context, null, new InvalidDataException("sui:Invalid login request"), true); return; }
            try
            {
                string Token = null;
                using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
                {
                    Connection.Open();
                    using (SqlCommand Command = new SqlCommand("apiUserLogin", Connection))
                    {
                        Command.CommandType = CommandType.StoredProcedure;
                        Command.Parameters.AddWithValue("Email", Credentials.Email);
                        using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.SingleRow))
                        {
                            if (Reader.HasRows)
                                if (Reader.Read())
                                    if (Security.VerifyPassword(Credentials.Password, Reader.GetString(1)))
                                        Token = Security.TokenFromUserId(Reader.GetInt32(0));
                        }
                    }
                    if (string.IsNullOrWhiteSpace(Token)) throw new UnauthorizedAccessException("sui:Invalid email address or password");
                    Security.VerifyUser(Token, true);
                    Connection.Close();
                }
                new Response(new { token = Token }).Write(Context);
                return;
            }
            catch (Exception Exception) { Logging.LogError(Context, null, Exception, true); }
        }

        public bool IsReusable { get { return false; } }

    }
}