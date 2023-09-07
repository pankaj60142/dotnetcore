using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Completeserver
    {
       

        public Server server { get; set; }
        public Serverdatabase databases { get; set; }
        public Serverdocument document { get; set; }
        public lkpCity lkpCity { get; set; }
        public lkpCountry lkpCountry { get; set; }
        public lkpState lkpState { get; set; }
        public lkpDepartment lkpDepartment { get; set; }
        public lkpDataCenter lkpDataCenter { get; set; }

    
    }
}
