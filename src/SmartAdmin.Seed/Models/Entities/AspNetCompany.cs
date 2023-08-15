using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class AspNetCompany
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int CompanyId { get; set; }
        public string CompanyName { get; set; }
        public string AllowedModules { get; set; }
        public bool? IsActive { get; set; }
       
    }
    public class lkpuserForController
    {
        public string UserId { get; set; }
        public string UserName { get; set; }
        public string Email { get; set; }
        public string Pass { get; set; }
        public string Role { get; set; }
        public string SelectedCountries { get; set; }
        public string SelectedStates { get; set; }
        public string SelectedCities { get; set; }
        public string SelectedDatacenters { get; set; }
        public string SelectedDepartments { get; set; }
        public string SelectedCountryNames { get; set; }
        public string SelectedStateNames { get; set; }
        public string SelectedCitiesNames { get; set; }
        public string SelectedDataCenterNames { get; set; }
        public string SelectedDepartmentNames { get; set; }
        public string SelectedApplicationNames { get; set; }

    }
}
