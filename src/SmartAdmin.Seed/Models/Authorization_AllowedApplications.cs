using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models
{
    public class Authorization_AllowedApplications
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int AllowedApplicationId { get; set;}
        public string UserId { get; set; }
        public int ApplicationId { get; set;}


    }
}
