using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartAdmin.Seed.Models.Entities
{
    public class tblSharedFolderWithUser
    {

        [Key]
        public int SharedFolderWithUserId { get; set; }
      
        public int SharedFolderId { get; set; }

        public string WhoSharedId { get; set; }


        public string SharedWithUserEmail { get; set; }


        public int CompanyId { get; set; }


        public DateTime SharedAt { get; set; }




    }
}

