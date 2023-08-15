using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class GGPDeveloper
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]

        public int GGPDeveloperID { get; set; }
        public string LeadDeveloper { get; set; }
        public string BusinessAnalyst { get; set; }
        public int ProgrammingLanguageID { get; set; }

    }
}
