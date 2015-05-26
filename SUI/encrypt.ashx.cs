using System;
using System.Web;
using Newtonsoft.Json;

namespace SUI
{

    public class Encrypt : IHttpHandler
    {

        public void ProcessRequest(HttpContext Context)
        {
            Context.Response.ContentType = "text/plain";
            if (Context.Request.QueryString["pw"] != null)
            {
                string Password = Context.Request.QueryString["pw"];
                string Encrypted = Security.EncryptPassword(Password);
                bool Match = Security.VerifyPassword(Password, Encrypted);
                new Response(new { unencrypted = Password, encrypted = Encrypted, match = Match }).Write(Context);
                return;
            }
            else Logging.LogError(Context, null, new InvalidOperationException("sui:Nothing to encrypt"), false);
        }

        public bool IsReusable { get { return false; } }

    }

}