using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class lkpAllCountries
    {

        [Key]
        public string CountryCode { get; set; }
        public string latitude { get; set; }
        public string longitude { get; set; }
        public string CountryName { get; set; }
        public int? MapId { get; set; }



    }
}
