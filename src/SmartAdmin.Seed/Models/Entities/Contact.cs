using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Contact
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ContactID { get; set; }
        public string FirstName { get; set; }
        public string LastName {get;set;}
        public string MiddleInitial { get; set; }
        public string Email { get; set; }
        public string Phone { get; set; }
        public string Title { get; set; }
        public string LoginName { get; set; }
        public string SID { get; set; }
        public string EmployeeNo { get; set; }
        public bool IsValid { get; set; }
        public int ContactTypeID { get; set; }
        public int ApplicationID { get; set; }
    }
}
