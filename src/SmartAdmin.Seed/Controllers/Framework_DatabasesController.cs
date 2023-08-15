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
    public class Framework_DatabasesController : Controller
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


        //  private List<Documents> documents;
        #endregion
        public IActionResult Index()
        {
            return View();
        }

        public Framework_DatabasesController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            allStates = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            allcities = (from c in _context.lkpAllCities select c).ToList();
            city = (from c in _context.lkpCity select c).ToList();
            states = (from c in _context.lkpState select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
            datacenter = (from c in _context.lkpDataCenter select c).ToList();
            department = (from c in _context.lkpDepartment select c).ToList();
            //databases = (from c in _context.Databases select c).ToList();
            _userManager = userManager;
            //documents = (from c in _context.Documents select c).ToList();
        }

        public JsonStringResult GetCountryName()
        {
            try {
                var resultCountries = (from c in countries
                                       select c).ToList();


                var json = JsonConvert.SerializeObject(resultCountries);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountryName", "Framework_Databases", userid, _context);

                return new JsonStringResult("Unable to get Country Name");
            } }
        [HttpPost]
        public JsonStringResult EditData(int DatabaseID)
        {
            try {
                var result = (from s in _context.Databases
                              join x in _context.databaseDocument on s.DatabaseID equals x.DatabaseID
                              join y in _context.Framework_Databases_Location on s.DatabaseID equals y.DatabaseID
                              join z in _context.lkpCountry on y.CountryId equals z.CountryId

                              where s.DatabaseID == DatabaseID
                              select new
                              {
                                  s.DBTypeID,
                                  s.InstallerNameID,
                                  s.DatabaseID,
                                  s.DbaId,
                                  s.DBVersion,
                                  s.InstalledDate,
                                  s.Name,
                                  s.ServicePack,
                                  x.DocumentID,
                                  s.Comments,
                                  s.DBTechnology,
                                  y.CityId,
                                  y.CountryId,
                                  y.StateId,
                                  y.DepartmentId,
                                  y.DataCenterId,
                                  z.CountryName,
                                  z.Longitude,
                                  z.Latitude

                              }
                              ).ToList();





                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "EditData", "Framework_Databases", userid, _context);

                return new JsonStringResult("unable to save");
            } }
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
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "Framework_Databases", userid, _context);

                return new JsonStringResult("unable to get State Name");
            } }
        [HttpGet]
        public JsonStringResult GetDatabase()
        {
            try
            {
                var result = (from x in _context.Databases
                              join y in _context.lkpDBA on x.DbaId equals y.LookupId
                              join d in _context.databaseDocument on x.DatabaseID equals d.DatabaseID into tempDt
                              from z in tempDt.DefaultIfEmpty()
                              join a in _context.Document on z.DocumentID equals a.DocumentID into temdoc
                              from e in temdoc.DefaultIfEmpty()
                              select new
                              {

                                  DataBaseName = x.Name,
                                  x.ServicePack,
                                  x.Comments,
                                  x.DBVersion,
                                  x.DatabaseID,
                                  y.CodeValue,

                                  DocumentID = z == null ? 0 : z.DocumentID,
                                  DocumentName = e.Name ?? String.Empty
                              });
                //var result = (from a in _context.Databases

                //              join b in _context.lkpDBA on a.DbaId equals b.LookupId
                //              //leftJOIN c in _context.databaseDocument on a.DatabaseID equals c.DatabaseID
                //              //leftJOIN d in _context.Document on c.DocumentID equals d.DocumentID
                //              select new

                //              {

                //              a.DatabaseID,a.DBVersion,a.Comments,b.CodeValue,a.ServicePack,
                //                  DataBaseName = a.Name
                //              }).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDatabase", "Framework_Databases", userid, _context);

                return new JsonStringResult("Unable to get Database");
            }
            }

        [HttpGet]
        public JsonStringResult frmserver_DBAID()
        {
            try
            {
                var result = _context.lkpDBA.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }

            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_DBAID", "Framework_Databases", userid, _context);

                return new JsonStringResult("Unable to get DBA");
            }
            }


        [HttpGet]
        public JsonStringResult DatabaseDocument()
        {
            try
            {
                var result = from c in _context.Document
                             select c;
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DatabaseDocument", "Framework_Databases", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpPost]
        public ActionResult DeleteDataBase(int DatabaseID)
        {
            string message = "SUCCESS";

            try
            {
                var selectedDataBase = (from c in _context.Databases
                                    where c.DatabaseID == DatabaseID
                                    select c).FirstOrDefault();

                if (selectedDataBase == null)
                {

                    message = "Fail";
                }

                _context.Databases.Remove(selectedDataBase);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteDataBase", "Framework_Databases", userid, _context);


                return new JsonStringResult("Fail");
            }

        }
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
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteDataBase", "Framework_Databases", userid, _context);
                return new JsonStringResult("Unable get city name");
            }
        }
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
                ErrorLogExtension.RecordErrorLogException(ex, "GetDataCenterName","Framework_Databases", userid, _context);
                return new JsonStringResult("Unable get Data center name");
            }
            }


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
                ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentName", "Framework_Databases", userid, _context);
                return new JsonStringResult("Unable get Department Name");
            }
            }
        [HttpPost]
        public JsonStringResult SaveDatabase([FromBody]MulitpleModels framework_databases)
        {

           try 
                {

              
                var foundDatabase = (from c in _context.Databases where c.DatabaseID == framework_databases.databases.DatabaseID select c).FirstOrDefault();

 
                if (foundDatabase == null)
                {
                    Databases SelectedFramework_database = new Databases();
                    DatabaseDocument DatabaseDocument = new DatabaseDocument();
                    Framework_Databases_Location Framework_Databases_Location1 = new Framework_Databases_Location();



                    SelectedFramework_database.Name = framework_databases.databases.Name;
                    SelectedFramework_database.DbaId = framework_databases.databases.DbaId;
                    SelectedFramework_database.DBTypeID = framework_databases.databases.DBTypeID;
                    SelectedFramework_database.DBVersion = framework_databases.databases.DBVersion;
                    SelectedFramework_database.InstalledDate =framework_databases.databases.InstalledDate;
                    SelectedFramework_database.InstallerNameID = framework_databases.databases.InstallerNameID;
                    SelectedFramework_database.Comments = framework_databases.databases.Comments;
                    SelectedFramework_database.LastUpdated = DateTime.Now;
                    SelectedFramework_database.DBTechnology = framework_databases.databases.DBTechnology;

                    SelectedFramework_database.ServicePack = framework_databases.databases.ServicePack;
                     //document.DocumentID = framework_databases.document.DocumentID;
                    //document.Path = framework_databases.document.Path;
                    _context.Add(SelectedFramework_database);
                    _context.SaveChanges();

                    //--------------- Database document---------------------
                    DatabaseDocument.DocumentID = framework_databases.document.DocumentID;

                    DatabaseDocument.DatabaseID= SelectedFramework_database.DatabaseID;
                    _context.Add(DatabaseDocument);
                    _context.SaveChanges();

                    //--------------- Database document---------------------
                    //----------------DataBase LOcation---------------------
                    Framework_Databases_Location1.CityId= framework_databases.DatabaseLocation.CityId;
                    Framework_Databases_Location1.CountryId = framework_databases.DatabaseLocation.CountryId;
                    Framework_Databases_Location1.DataCenterId = framework_databases.DatabaseLocation.DataCenterId;
                    Framework_Databases_Location1.DepartmentId = framework_databases.DatabaseLocation.DepartmentId;
                    Framework_Databases_Location1.StateId = framework_databases.DatabaseLocation.StateId;
                    Framework_Databases_Location1.DatabaseID = SelectedFramework_database.DatabaseID;
                    
                    _context.Add(Framework_Databases_Location1);
                    _context.SaveChanges();
                    //-----------------Database Location---------------------

                }
                // found, Update it
                else
                 {
                    var foundDatabaseDocument = (from c in _context.databaseDocument where c.DatabaseID == framework_databases.databases.DatabaseID select c).FirstOrDefault();
                    var foundDatalocation = (from c in _context.Framework_Databases_Location where c.DatabaseID == framework_databases.databases.DatabaseID select c).FirstOrDefault();

                   

                    //-----------------update Databases---------------
                    foundDatabase.DbaId = framework_databases.databases.DbaId; 
                    foundDatabase.Name = framework_databases.databases.Name;
                    foundDatabase.InstalledDate = framework_databases.databases.InstalledDate;

                    foundDatabase.DBTypeID = framework_databases.databases.DBTypeID;
                    foundDatabase.DBVersion = framework_databases.databases.DBVersion;
                    foundDatabase.InstallerNameID = framework_databases.databases.InstallerNameID;
                    foundDatabase.DBVersion = framework_databases.databases.DBVersion;
                    foundDatabase.Comments = framework_databases.databases.Comments;
                    foundDatabase.DBTechnology = framework_databases.databases.DBTechnology;
                    foundDatabase.LastUpdated = DateTime.Now;
                    _context.SaveChanges();


                    //----------------------end-----------------------------
                    //---------------------update database document--------------

                    foundDatabaseDocument.DocumentID = framework_databases.document.DocumentID;
                    _context.SaveChanges();
                    //------------------------end----------------------------
                    //---------------------update database Location--------------

                    foundDatalocation.CountryId = framework_databases.DatabaseLocation.CountryId;
                    foundDatalocation.StateId = framework_databases.DatabaseLocation.StateId;
                    foundDatalocation.CityId = framework_databases.DatabaseLocation.CityId;
                    foundDatalocation.DepartmentId = framework_databases.DatabaseLocation.DepartmentId;
                    foundDatalocation.DataCenterId = framework_databases.DatabaseLocation.DataCenterId;
                    //------------------------end----------------------------
                    _context.SaveChanges();
                }

                string message = "SUCCESS";
                return new JsonStringResult(message);

            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveDatabase", "Framework_Databases", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);

            }
           
        }


        private int ParseInt(string value)
        {
            int number = 0;
            if (int.TryParse(value, out number))
                return number;
            else
                return 0;
        }
    }
}
