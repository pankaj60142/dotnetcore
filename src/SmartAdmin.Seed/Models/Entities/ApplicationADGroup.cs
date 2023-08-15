using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class ApplicationADGroup
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]

       public int  ApplicationADGroupID { get; set; }
        public int ApplicationID { get; set; }
        public int ADGroupID { get; set; }

    }
}
