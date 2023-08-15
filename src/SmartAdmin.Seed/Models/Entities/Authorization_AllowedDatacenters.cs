using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
       public class Authorization_AllowedDatacenters
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AllowedDatacentersId { get; set; }
        public string UserId { get; set; }
        public int DatacenterId { get; set; }

        public int CountryId { get; set; }
        
    }
}
