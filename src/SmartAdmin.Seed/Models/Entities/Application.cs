using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Application
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]

        public int ApplicationID { get; set; }
        public string Name { get; set; }
        public string Ver { get; set; }
        public string ShortDescription { get; set; }
        public string LongDescription { get; set; }
        public string InstallationPath { get; set; }
        public DateTime? InstalledDate { get; set; }
        public string SupportPhone { get; set; }
        public string SupportEmail { get; set; }
        public string SupportAccountNo { get; set; }
        public DateTime? SupportExpirationDate { get; set; }
        public string SupportURL { get; set; }
        public int NumberOfLicenses { get; set; }
        public string Comment { get; set; }
        public int InstallerNameID { get; set; }
        public string Usrname { get; set; }
        public string Pass { get; set; }
        public int DeveloperTypeID { get; set; }
        public int DeveloperID { get; set; }
        public string CitrixApplicationName { get; set; }
        public string ApplicationURL { get; set; }
        public int ApplicationTypeID { get; set; }
        public bool IsVisibleInsideGGP { get; set; }
        public DateTime? CertificateExpiration { get; set; }
        public string SMTP { get; set; }
        public bool IsVisibleNonEmployee { get; set; }
        public string FirewallException { get; set; }
        public bool VProcessDependent { get; set; }
        public string LDAP { get; set; }
        public int Application_server { get; set; }
        public int Application_database { get; set; }
    }
}
