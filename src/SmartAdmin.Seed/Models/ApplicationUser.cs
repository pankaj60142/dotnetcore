#region Using

using Microsoft.AspNetCore.Identity;

#endregion

namespace SmartAdmin.Seed.Models
{
    // Add profile data for application users by adding properties to the ApplicationUser class
    public class ApplicationUser : IdentityUser
    {       
        public string CompanyName { get; set; }
        public int CompanyId { get; set; }

        public string FirstName { get; set; }
        public string LastName { get; set; }
    }
}
