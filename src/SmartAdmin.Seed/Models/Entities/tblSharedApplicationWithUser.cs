using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartAdmin.Seed.Models.Entities
{
    public class tblSharedApplicationWithUser
    {

        [Key]
        public int SharedApplicationWithUserId { get; set; }

        public int SharedApplicationId { get; set; }

        public string WhoSharedId { get; set; }


        public string SharedWithUserEmail { get; set; }


        public int CompanyId { get; set; }


        public DateTime SharedAt { get; set; }




    }
}


