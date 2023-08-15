using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Framework_Databases_Location
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Framework_Database_LocationID { get; set; }
        public int CityId { get; set; }
        public int CountryId { get; set; }
        public int StateId { get; set; }
        public int DepartmentId { get; set; }
        public int DataCenterId { get; set; }
        public int DatabaseID { get; set; }
    }
}
