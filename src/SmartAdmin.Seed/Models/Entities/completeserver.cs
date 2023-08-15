using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class completeserver
    {
       

        public Server server { get; set; }
        public serverdatabase databases { get; set; }
        public serverdocument document { get; set; }
        public lkpCity lkpCity { get; set; }
        public lkpCountry lkpCountry { get; set; }
        public lkpState lkpState { get; set; }
        public lkpDepartment lkpDepartment { get; set; }
        public lkpDataCenter lkpDataCenter { get; set; }

    
    }
}
