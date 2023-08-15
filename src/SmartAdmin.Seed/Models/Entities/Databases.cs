using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Databases 
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int DatabaseID { get; set; }
      public string Name { get; set; }
     public int DBTypeID { get; set; }
    public string DBVersion { get; set; }
      public int  InstallerNameID { get; set; }
        public DateTime InstalledDate { get; set; }
        public string ServicePack { get; set; }
        public int DbaId { get; set; }
        public bool IsDevDB { get; set; }  
        public bool IsTestDB { get; set; }
        public bool IsProdDB { get; set; }
        public string Comments { get; set; }
        public string LastUpdatedBy { get; set; }
        public DateTime LastUpdated { get; set; }
       public string DBTechnology { get; set; }





    }

}

