using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models
{
    public class ApplicationTreeInGraph
    {
        public string id { get; set; }

        public string parentid { get; set; }
        
        public string text { get; set; }

        public string type { get; set; }
    }
}
