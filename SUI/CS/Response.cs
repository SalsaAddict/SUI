using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Newtonsoft.Json;

namespace SUI
{
    
    public class Response
    {

        [JsonProperty("success")]
        public bool Success { get; private set; }

        [JsonProperty("data")]
        public object Data { get; private set; }

        [JsonProperty("error")]
        public string Error { get; private set; }

        [JsonProperty("reauthenticate")]
        public bool Reauthenticate { get; private set; }

        public Response(object Data)
        {
            this.Success = true;
            this.Data = Data;
            this.Error = null;
            this.Reauthenticate = false;
        }

        public Response(string Error, bool Reauthenticate = false)
        {
            this.Success = false;
            this.Data = null;
            this.Error = Error;
            this.Reauthenticate = Reauthenticate;
        }

        public void Write(HttpContext Context)
        {
            Context.Response.Clear();
            Context.Response.ContentType = "text/json";
            Context.Response.Write(JsonConvert.SerializeObject(this, Formatting.Indented));
        }

    }

}