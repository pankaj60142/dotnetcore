using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class lkpState
    {

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public Int32 StateId { get; set; }
        public Int32 CountryId { get; set; }
        public string StateName { get; set; }
        public string Latitude { get; set; }
        public string Longitude { get; set; }
        public bool Active { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ModifiedAt { get; set; }
        public int CreatedBy { get; set; }
        public int ModifiedBy { get; set; }
        public int CompanyId { get; set; }
         public int AllStateId { get; set; }
    }

    public class lkpStateForController
    {
        
        public Int32 CountryId { get; set; }
        public string StateName { get; set; }
        public string CountryName { get; set; }
    }
}
