using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models
{
    public class SharedApplicationDetailModel
    {
        public int SharedApplicationWithUserId { get; set; }
     
        public int SharedApplicationId { get; set; }

        public string FileName { get; set; }

        public string WhoShared { get; set; }
       
        public string SharedWithUserEmail { get; set; }
      
    }
}
