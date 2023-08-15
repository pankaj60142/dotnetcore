using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class lkpDataCenter
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int DataCenterId { get; set; }
        public string DataCenterName { get; set; }
        public int CityId { get; set; }
        public int CompanyId { get; set; }      
        public bool Active { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime ModifiedAt { get; set; }
        public int CreatedBy { get; set; }
        public int ModifiedBy { get; set; }
    }
    public class lkpdatacenterForController
    {
        public int CityId { get; set; }
        public string DataCenterName { get; set; }

    }
}
