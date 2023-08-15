#region Using

using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

#endregion

namespace SmartAdmin.Seed.Models.AccountViewModels
{
    public class RegisterViewModel
    {
        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; }

        [Required]
        [StringLength(100, ErrorMessage = "The {0} must be at least {2} and at max {1} characters long.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; }

        [DataType(DataType.Password)]
        [Display(Name = "Confirm password")]
        [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; }


        //[Required]
        [Display(Name = "First Name")]
        public string FirstName { get; set; }

        //[Required]
        [Display(Name = "Last Name")]
        public string LastName { get; set; }

        //[Required]
        [Display(Name = "Company Name")]      
        public string CompanyName { get; set; }       



        //[Required]
        [Display(Name = "Allowed Modules")]
        public List<string> AllowedModules { get; set; }
        public RegisterViewModel()
        {
            AllowedModules = new List<string>();
        }
    }
}
