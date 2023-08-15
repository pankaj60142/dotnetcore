using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class lkpAllStates
    {

        [Key]
        public int StateId { get; set; }
        public string Latitude { get; set; }
        public string Longitude { get; set; }
        public string StateName { get; set; }
        public string CountryCode { get; set; }
        
    }
}
