using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Services
{
    public class AuthMessageSenderOptions
    {
        public string SendGridUser { get; set; }
        public string SendGridKey { get; set; }

        public string SendGridEmail { get; set; }
        
    }

    public class AppSettingsOptions
    {
        public string HostURL { get; set; }
        

    }
}
