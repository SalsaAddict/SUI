using Newtonsoft.Json;

namespace SUI
{

    public class Parameter
    {

        [JsonProperty("name")]
        public string Name { get; set; }

        [JsonProperty("value")]
        public object Value { get; set; }

        [JsonProperty("xml")]
        public bool XML { get; set; }

    }

}