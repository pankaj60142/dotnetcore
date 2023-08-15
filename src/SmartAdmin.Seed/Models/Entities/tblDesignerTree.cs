using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SmartAdmin.Seed.Models.Entities
{
    public class tblDesignerTree
    {

     
        public int id { get; set; }
        public string parent { get; set; }

        public int parentint { get; set; }
        
        public string text { get; set; }

        public int FolderLevel { get; set; }

        public int CompanyId { get; set; }

        public bool Active { get; set; }
        public DateTime? CreatedAt { get; set; }
        public DateTime? ModifiedAt { get; set; }
        public string CreatedBy { get; set; }
        public string ModifiedBy { get; set; }



      

    }
}
