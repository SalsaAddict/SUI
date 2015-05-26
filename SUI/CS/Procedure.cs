using Newtonsoft.Json;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Web;

namespace SUI
{

    public class Procedure
    {

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("parameters")]
        public List<Parameter> Parameters { get; set; }

        [JsonProperty("type")]
        public string Type { get; set; }

        [JsonProperty("token")]
        public string Token { get; set; }

        public static bool TryParse(HttpContext Context, out Procedure Result)
        {
            Result = null;
            try
            {
                using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                {
                    Result = JsonConvert.DeserializeObject<Procedure>(Reader.ReadToEnd());
                    return true;
                }
            }
            catch { return false; }
        }

    }

}