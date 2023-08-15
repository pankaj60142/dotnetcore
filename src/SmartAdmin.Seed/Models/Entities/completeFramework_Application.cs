using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class completeFramework_Application
    {
        public ApplicationADGroup ApplicationADGroup {get;set;}
        public ADGroup adgroup { get; set; }
        public Application application { get; set; }
        public List<Contact> contact { get; set; }
        public Databases databases { get; set; }
        public Document document { get; set; }
        public ApplicationDatabase applicationDatabase { get; set; }
        public ApplicationDocument applicationDocument { get; set; }
        public lkpCity lkpCity { get; set; }
        public lkpCountry lkpCountry { get; set; }
        public lkpState lkpState { get; set; }
        public lkpDepartment lkpDepartment { get; set; }
        public lkpDataCenter lkpDataCenter { get; set; }
       
    }
}
