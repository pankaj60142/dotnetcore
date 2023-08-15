using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Extensions;
using SmartAdmin.Seed.Models;
using Microsoft.AspNetCore.Identity;
// For more information on enabling MVC for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class Framework_Application : Controller
    {
        
        #region Declaration
        private readonly ApplicationDbContext _context;
        private List<lkpAllStates> allStates;
        private List<lkpCountry> countries;
        private List<lkpAllCountries> allcountries;
        private List<lkpAllCities> allcities;
        private List<lkpState> states;
        private List<lkpCity> city;
        private List<lkpDataCenter> datacenter;
        private List<lkpDepartment> department;
        private readonly UserManager<ApplicationUser> _userManager;

        //  private List<Databases> databases;

        #endregion
        public Framework_Application(ApplicationDbContext db, UserManager<ApplicationUser> userManager)
        {
            _context = db;
            allStates = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            allcities = (from c in _context.lkpAllCities select c).ToList();
            city = (from c in _context.lkpCity select c).ToList();
            states = (from c in _context.lkpState select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
            datacenter = (from c in _context.lkpDataCenter select c).ToList();
            department = (from c in _context.lkpDepartment select c).ToList();
            _userManager = userManager;
            // databases = (from c in _context.Databases select c).ToList();
        }
        // GET: /<controller>/
        public IActionResult Index()
        {
            return View();  
        }
        public JsonStringResult GetCountryName()
        {
            try
            {
                var resultCountries = (from c in countries
                                       select c).ToList();


                var json = JsonConvert.SerializeObject(resultCountries);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get country name");
            } }
        [HttpPost]
        public JsonStringResult GetDepartmentName(int DataCenterId)

        {
            try {
                var result = (from s in _context.lkpDepartment
                              where s.DataCenterId == DataCenterId
                              select s
                ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get department name");
            } }


        [HttpPost]
        public JsonStringResult GetDataCenterName(int CityId)

        {
            try {

                var result = (from s in _context.lkpDataCenter
                              where s.CityId == CityId
                              select s
                ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get datacenter Name");
            } }
        [HttpPost]
        public JsonStringResult GetCityName(int StateId)

        {
            try {
                var result = (from s in _context.lkpCity
                              where s.StateId == StateId
                              select s
                ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get City Name");
            }
            }
        [HttpGet]
        public JsonStringResult GetDatabases()
        {
            try
            {

                var result = _context.Databases.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult GetDocument()
        {
            try
            {

                var result = _context.Document.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }


        [HttpGet]
        public JsonStringResult GetServer()
        {
            try
            {

                var result = _context.Server.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult GetDeveloper()
        {
            try
            {

                var result = _context.ggpDeveloper.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDeveloper", "ggpDeveloper", userid, _context);

               
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult GetInstaller()
        {
            try
            {

                var result = _context.lkpInstaller.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetInstaller", "lkpInstaller", userid, _context);

               
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult GetAdGroup()
        {
            try
            {

                var result = _context.ADGroup.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetAdGroup", "ADGroup", userid, _context);

                
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }



        [HttpPost]
        public JsonStringResult GetStateName(int CountryId)
        {
            try {
                var result = (from s in _context.lkpState
                              where s.CountryId == CountryId
                              select s
                ).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get State Name");
            } }

        [HttpPost]
        public JsonStringResult EditData(int ApplicationID)
        {
            try {
                var result = (from x in _context.Application
                              join aag in _context.ApplicationADGroup on x.ApplicationID equals aag.ApplicationID
                              join ac in _context.Contact on x.ApplicationID equals ac.ApplicationID
                              //  join ac in _context. on ac.ApplicationID equals x.ApplicationID
                              join ad in _context.ApplicationDatabase on x.ApplicationID equals ad.ApplicationID
                              join ado in _context.applicationDocument on x.ApplicationID equals ado.ApplicationID
                              join fal in _context.framework_Applicationlocation on x.ApplicationID equals fal.ApplicationID

                              where x.ApplicationID == ApplicationID
                              select new
                              {
                                  fal.CountryId,
                                  fal.StateId,
                                  fal.CityId,
                                  fal.DataCenterId,
                                  fal.DepartmentId,
                                  ado.DocumentID,
                                  ad.DatabaseID,
                                  aag.ADGroupID,
                                  x.ApplicationID,
                                  x.Name,
                                  x.Ver,
                                  x.ShortDescription,
                                  x.LongDescription,
                                  x.InstalledDate,
                                  x.SupportPhone,
                                  x.SupportAccountNo,
                                  x.SupportURL,
                                  x.SupportExpirationDate,

                                  x.NumberOfLicenses,
                                  x.Comment,
                                  x.Usrname,
                                  x.Pass,
                                  x.DeveloperTypeID,
                                  x.DeveloperID,
                                  x.CitrixApplicationName,

                                  x.ApplicationURL,
                                  x.ApplicationTypeID,
                                  x.SMTP,
                                  x.FirewallException,
                                  x.LDAP,
                                  x.IsVisibleInsideGGP,

                                  x.CertificateExpiration,
                                  x.IsVisibleNonEmployee,
                                  x.Application_server,
                                  x.Application_database,
                                  x.InstallationPath,
                                  ac.ContactID,
                                  ac.ContactTypeID,
                                  ac.Email,
                                  ac.EmployeeNo,
                                  ac.Phone,
                                  ac.FirstName,
                                  ac.LastName,
                                  ac.MiddleInitial,
                                  ac.LoginName,
                                  ac.SID


                              }
                               ).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to save");
            }
            }





        [HttpPost]

        public JsonStringResult SaveDataapplication([FromBody] completeFramework_Application frmApplication)
        {
            try

            {
                var found = (from c in _context.Application where c.ApplicationID == frmApplication.application.ApplicationID select c).FirstOrDefault();
                if (found == null)
                {
                    Application pro = new Application();
                    ADGroup adgroup = new ADGroup();

                    ApplicationDatabase applicationDatabase = new ApplicationDatabase();
                    ApplicationDocument applicationDocument = new ApplicationDocument();
                    ApplicationADGroup applicationADGroup = new ApplicationADGroup();
                    framework_applicationlocation framework_Applicationlocation = new framework_applicationlocation();

                    pro.Application_server = frmApplication.application.Application_server;
                    pro.Application_database = frmApplication.application.Application_database;
                    pro.Name = frmApplication.application.Name;
                    pro.Ver = frmApplication.application.Ver;
                    pro.ShortDescription = frmApplication.application.ShortDescription;
                    pro.LongDescription = frmApplication.application.LongDescription;
                    pro.InstallationPath = frmApplication.application.InstallationPath;
                     pro.InstalledDate = DateTime.Now;
                    pro.SupportPhone = frmApplication.application.SupportPhone;
                    // pro.SupportEmail = frmApplication.application.SupportEmail;
                    pro.SupportAccountNo = frmApplication.application.SupportAccountNo;
                    pro.SupportExpirationDate = DateTime.Now;
                    pro.SupportURL = frmApplication.application.SupportURL;
                    pro.NumberOfLicenses = frmApplication.application.NumberOfLicenses;
                    pro.Comment = frmApplication.application.Comment;
                    pro.InstallerNameID = frmApplication.application.InstallerNameID;
                    pro.Usrname = frmApplication.application.Usrname;
                    pro.Pass = frmApplication.application.Pass;
                    pro.DeveloperTypeID = frmApplication.application.DeveloperTypeID;
                    pro.DeveloperID = frmApplication.application.DeveloperID;
                    pro.CitrixApplicationName = frmApplication.application.CitrixApplicationName;
                    pro.ApplicationURL = frmApplication.application.ApplicationURL;
                    pro.ApplicationTypeID = frmApplication.application.ApplicationTypeID;
                    pro.IsVisibleInsideGGP = frmApplication.application.IsVisibleInsideGGP;
                    pro.CertificateExpiration = DateTime.Now;
                    pro.SMTP = frmApplication.application.SMTP;
                    pro.IsVisibleNonEmployee = frmApplication.application.IsVisibleNonEmployee;
                    pro.FirewallException = frmApplication.application.FirewallException;
                    pro.LDAP = frmApplication.application.LDAP;

                    _context.Add(pro);
                    _context.SaveChanges();
                 
                    //--------------------------ADgroup---------------- >
                    applicationADGroup.ApplicationID = pro.ApplicationID;
                    applicationADGroup.ADGroupID = frmApplication.ApplicationADGroup.ADGroupID;
                    _context.Add(applicationADGroup);


                    //adgroup.GroupName = frmApplication.adgroup.GroupName;
                    //adgroup.GroupPath = frmApplication.adgroup.GroupPath;
                  //----------------------------EndADGroup------------ >


                 //-----------------------------applicationcontact------------->
                    foreach (var c in frmApplication.contact)
                    {
                        Contact contact = new Contact();
                        contact.FirstName = c.FirstName;
                        contact.LastName = c.LastName;
                        contact.MiddleInitial = c.MiddleInitial;
                        contact.Email = c.Email;
                        contact.Phone = c.Phone;
                        contact.Title = c.Title;
                        contact.LoginName = c.LoginName;
                        contact.SID = c.SID;
                        contact.IsValid = c.IsValid;
                        contact.ContactTypeID = c.ContactTypeID;
                        contact.ApplicationID = pro.ApplicationID;
                        _context.Contact.Add(contact);
                    }
                    _context.SaveChanges();


                //    -------------------------EndApplicationContact----------------->

                 // --------------------------Database------------------ >

                    applicationDatabase.ApplicationID = pro.ApplicationID;
                    applicationDatabase.DatabaseID = frmApplication.databases.DatabaseID;
                    _context.Add(applicationDatabase);
                    _context.SaveChanges();
                    //------------------Endofdatabase----------------------->

                    //----------------------------Document------------------->

                    applicationDocument.ApplicationID = pro.ApplicationID;
                    applicationDocument.DocumentID = frmApplication.document.DocumentID;
                    _context.Add(applicationDocument);
                    _context.SaveChanges();
                    ////--------------------------EndofDocument

                    ////------------------------Save Country City Dataceneter etc --------------------->
                   // framework_Applicationlocation.Framework_applicationlocationID = 999;
                    framework_Applicationlocation.ApplicationID = pro.ApplicationID;
                    framework_Applicationlocation.CountryId = frmApplication.lkpCountry.CountryId;
                    framework_Applicationlocation.StateId = frmApplication.lkpState.StateId;
                    framework_Applicationlocation.CityId = frmApplication.lkpCity.CityId;
                    framework_Applicationlocation.DataCenterId = frmApplication.lkpDataCenter.DataCenterId;
                    framework_Applicationlocation.DepartmentId = frmApplication.lkpDepartment.DepartmentId;

                    _context.framework_Applicationlocation.Add(framework_Applicationlocation);
                    _context.SaveChanges();
                    //-------------------------end region---------------------------- >







                    _context.SaveChanges();




                }

                else
                {
                    var foundApplicationADGroup = (from c in _context.ApplicationADGroup where c.ApplicationID == frmApplication.application.ApplicationID select c).FirstOrDefault();
                    var foundDatabase = (from c in _context.ApplicationDatabase where c.ApplicationID == frmApplication.application.ApplicationID select c).FirstOrDefault();
                    var foundDatabasedoc = (from c in _context.applicationDocument where c.ApplicationID == frmApplication.application.ApplicationID select c).FirstOrDefault();
                    var foundDatalocation=(from c in _context.framework_Applicationlocation where c.ApplicationID== frmApplication.application.ApplicationID select c ).FirstOrDefault();

                    found.Application_server = frmApplication.application.Application_server;
                    found.Application_database = frmApplication.application.Application_database;
                    found.Name = frmApplication.application.Name;
                    found.Ver = frmApplication.application.Ver;
                    found.ShortDescription = frmApplication.application.ShortDescription;
                    found.LongDescription = frmApplication.application.LongDescription;
                    found.InstallationPath = frmApplication.application.InstallationPath;
                      found.InstalledDate = DateTime.Now;
                    found.SupportPhone = frmApplication.application.SupportPhone;
                    //  found.SupportEmail = frmApplication.application.SupportEmail;
                    found.SupportAccountNo = frmApplication.application.SupportAccountNo;
                    found.SupportExpirationDate = DateTime.Now;
                    found.SupportURL = frmApplication.application.SupportURL;
                    found.NumberOfLicenses = frmApplication.application.NumberOfLicenses;
                    //found.Comment = frmApplication.application.Comment;
                    //found.InstallerNameID = frmApplication.application.InstallerNameID;
                    //found.Usrname = frmApplication.application.Usrname;
                    //found.Pass = frmApplication.application.Pass;
                    //found.DeveloperTypeID = frmApplication.application.DeveloperTypeID;
                    //found.DeveloperID = frmApplication.application.DeveloperID;
                    //found.CitrixApplicationName = frmApplication.application.CitrixApplicationName;
                    //found.ApplicationURL = frmApplication.application.ApplicationURL;
                    //found.ApplicationTypeID = frmApplication.application.ApplicationTypeID;
                    //found.IsVisibleInsideGGP = frmApplication.application.IsVisibleInsideGGP;
                    //found.CertificateExpiration = DateTime.Now;
                    //found.SMTP = frmApplication.application.SMTP;
                    //found.IsVisibleNonEmployee = frmApplication.application.IsVisibleNonEmployee;
                    //found.FirewallException = frmApplication.application.FirewallException;
                    //found.LDAP = frmApplication.application.LDAP;
                   

                   

                    //----------------------AdGroup---------->
                    foundApplicationADGroup.ADGroupID = frmApplication.ApplicationADGroup.ADGroupID;

                    //-----------------end-------------------->


                    //DatabaseApp

                    foundDatabase.DatabaseID = frmApplication.databases.DatabaseID;
                    //------------------end-----------------


                    //DatabaseDocument

                    foundDatabasedoc.DocumentID = frmApplication.document.DocumentID;

                    //--------------end-------------------------

                    //---------------------update database Location--------------

                    foundDatalocation.CountryId = frmApplication.lkpCountry.CountryId;
                    foundDatalocation.StateId = frmApplication.lkpState.StateId;
                    foundDatalocation.CityId = frmApplication.lkpCity.CityId;
                    foundDatalocation.DataCenterId = frmApplication.lkpDataCenter.DataCenterId;
                    foundDatalocation.DepartmentId = frmApplication.lkpDepartment.DepartmentId;

                    //------------------------end----------------------------

                    _context.SaveChanges();

                }
                string message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);

            }
        }

        [HttpGet]
        public JsonStringResult GetDatabase()
        {
            //var result = (from x in _context.Databases
            //              join y in _context.lkpDBA on x.DbaId equals y.LookupId
            //              join d in _context.databaseDocument on x.DatabaseID equals d.DatabaseID into tempDt
            //              from z in tempDt.DefaultIfEmpty()
            //              join a in _context.Document on z.DocumentID equals a.DocumentID into temdoc
            //              from e in temdoc.DefaultIfEmpty()
            //              select new
            //              {

            //                  DataBaseName = x.Name,
            //                  x.ServicePack,
            //                  x.Comments,
            //                  x.DBVersion,
            //                  x.DatabaseID,
            //                  y.CodeValue,

            //                  DocumentID = z == null ? 0 : z.DocumentID,
            //                  DocumentName = e.Name ?? String.Empty
            //              });

            try {
                var result = (from x in _context.Application


                              select new
                              {
                                  x.ApplicationID,
                                  x.Name,
                                  x.Usrname,


                              });



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);
                   
                return new JsonStringResult("Unable to get application");
            } }

        public JsonStringResult Addcontact([FromBody] Contact contact)
        {
            try
            {
                Contact addcontact = new Contact();

                addcontact.FirstName = contact.FirstName;
                addcontact.LastName = contact.LastName;
                addcontact.MiddleInitial = contact.MiddleInitial;
                addcontact.Phone = contact.Phone;
                addcontact.SID = contact.SID;
                addcontact.Title = contact.Title;
                addcontact.Email = contact.Email;
                addcontact.EmployeeNo = contact.EmployeeNo;
                addcontact.IsValid = contact.IsValid;
                addcontact.ContactTypeID = contact.ContactTypeID;
                addcontact.LoginName = contact.LoginName;

                _context.Add(addcontact);
                _context.SaveChanges();
                return new JsonStringResult("SUCCESS");

            }

            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

               
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);

            }
        }

        [HttpPost]
        public JsonStringResult GetInsertedContact()
        {



            try {

                var result = (from c in _context.Contact select c).ToList();

                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);


            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                return new JsonStringResult("Unable to get contact");
            } }


    }
}

