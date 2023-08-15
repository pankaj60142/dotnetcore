using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;
using JetBrains.Annotations;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using SmartAdmin.Seed.Extensions;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.AccountViewModels;
using SmartAdmin.Seed.Services;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Data;
using System.Collections.Generic;
using Newtonsoft.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Hosting;
using System.IO;

namespace SmartAdmin.Seed.Controllers
{
    public class ConfirmationController : Controller
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
        #endregion

        //private readonly ILogger _logger;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;


        public ConfirmationController(UserManager<ApplicationUser> userManager, ApplicationDbContext context, IWebHostEnvironment env)
        {
            _userManager = userManager;
            _env = env;
            //_signInManager = signInManager;
            //_emailSender = emailSender;
            //_logger = logger;

            _context = context;
            allStates = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            allcities = (from c in _context.lkpAllCities select c).ToList();
            city = (from c in _context.lkpCity select c).ToList();
            states = (from c in _context.lkpState select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
            datacenter = (from c in _context.lkpDataCenter select c).ToList();
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public JsonStringResult GetRoleId(string UserId, string RoleId)

        {
            try
            {

                if (RoleId == "Country")
                {
                    var result = (from f in _context.Users
                                  join AllowedCountries in _context.Authorization_AllowedCountries on f.Id equals AllowedCountries.UserId
                                  where f.Id == UserId
                                  select new { f.UserName, f.Email, AllowedCountries.CountryId }).ToList();
                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }
                else if (RoleId == "DataCenter")
                {
                    var result = (from f in _context.Users
                                  join AllowedCountries in _context.Authorization_AllowedCountries on f.Id equals AllowedCountries.UserId
                                  join AllowedStates in _context.Authorization_AllowedStates on f.Id equals AllowedStates.UserId
                                  join Allowedcities in _context.Authorization_AllowedCities on f.Id equals Allowedcities.UserId
                                  join AllowedDataCenters in _context.Authorization_AllowedDatacenters on f.Id equals AllowedDataCenters.UserId
                                  where f.Id == UserId
                                  select new { f.UserName, f.Email, AllowedCountries.CountryId, AllowedStates.StateId, Allowedcities.CityId, AllowedDataCenters.DatacenterId }).ToList();
                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }
                else if (RoleId == "Department")
                {
                    var result = (from f in _context.Users
                                  join AllowedCountries in _context.Authorization_AllowedCountries on f.Id equals AllowedCountries.UserId
                                  join AllowedStates in _context.Authorization_AllowedStates on f.Id equals AllowedStates.UserId
                                  join Allowedcities in _context.Authorization_AllowedCities on f.Id equals Allowedcities.UserId
                                  join AllowedDataCenters in _context.Authorization_AllowedDatacenters on f.Id equals AllowedDataCenters.UserId
                                  join AllowedDepartments in _context.Authorization_AllowedDepartments on f.Id equals AllowedDepartments.UserId
                                  where f.Id == UserId
                                  select new { f.UserName, f.Email, AllowedCountries.CountryId, AllowedStates.StateId, Allowedcities.CityId, AllowedDataCenters.DatacenterId, AllowedDepartments.DepartmentId }).ToList();
                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }
                else if(RoleId=="Admin")
                {
                    var result = (from f in _context.Users
                                
                                  where f.Id == UserId
                                  select new { f.UserName, f.Email }).ToList();
                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }


                return null;
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetRoleId", "Confirmation", userid, _context);

                var message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        [HttpPost]
        public JsonStringResult FillUsersGrid(int compid)
        {

            try
            {
                var result = (from f in _context.Users
                                  //  join allcountries in countries on c.CountryName equals allcountries.CountryName
                              join u in _context.UserRoles on f.Id equals u.UserId
                              join r in _context.Roles on u.RoleId equals r.Id
                              where f.CompanyId == compid
                              select new { f.Email,f.CompanyName, u.RoleId, f.Id, f.NormalizedUserName, r.Name }).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "FillUsersGrid", "Confirmation", userid, _context);


                return new JsonStringResult("Unable to fill User");
            }
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
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountryName", "Confirmation", userid, _context);

                
                return new JsonStringResult("Unable to get country");
            }
            }
        [HttpPost]
        public JsonStringResult GetStateName(string SelectedCountryIds1, int compid)
        {
            try
            {
                string countryids = Regex.Replace(SelectedCountryIds1, @"[^,\d]", "0");

                int[] ids = countryids.Split(',').Select(int.Parse).ToArray();

             
               var result = (from s in _context.lkpState.AsEnumerable()
                              join AllStates in _context.lkpAllStates.AsEnumerable() on s.AllStateId equals AllStates.StateId
                              where (ids.Contains(s.CountryId)) && s.CompanyId == compid
                              select new { s.StateId ,s.StateName ,s.CountryId , AllStates.CountryCode }
                              ).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "Confirmation", userid, _context);

                
                return new JsonStringResult("[]");
            }

        }


        public JsonStringResult GetCityName(string SelectedStates, int compid)

        {

            try
            {
                string stateids = Regex.Replace(SelectedStates, @"[^,\d]", "0");

                int[] ids = stateids.Split(',').Select(int.Parse).ToArray();

                var result = (from c in _context.lkpCity
                              where ids.Contains(c.StateId)
                              select c
                              ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCityName", "Confirmation", userid, _context);

                

                return new JsonStringResult("[]");
            }
        }

        public JsonStringResult GetDataCenterName(string SelectedCites, int compid)

        {
            try
            {
                string cityids = Regex.Replace(SelectedCites, @"[^,\d]", "");
                int[] ids = cityids.Split(',').Select(int.Parse).ToArray();

                var result = (from c in _context.lkpDataCenter
                              where ids.Contains(c.CityId) && c.CompanyId == compid
                              select c
                              ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDataCenterName", "Confirmation", userid, _context);

                return new JsonStringResult("[]");
            }
        }

        public JsonStringResult GetDepartmentName(string SelectedDataCenter, int compid)

        {
            try
            {
                string datacenterids = Regex.Replace(SelectedDataCenter, @"[^,\d]", "");
                int[] ids = datacenterids.Split(',').Select(int.Parse).ToArray();

                var result = (from c in _context.lkpDepartment
                              where ids.Contains(c.DataCenterId) && c.CompanyId == compid
                              select c
                              ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentName", "Confirmation", userid, _context);

                
                return new JsonStringResult("[]");
            }
        }

        public JsonStringResult GetApplicationName(string SelectedDepartments, int compid)

        {
            try
            {
                string Applicationids = Regex.Replace(SelectedDepartments, @"[^,\d]", "");
                int[] ids = Applicationids.Split(',').Select(int.Parse).ToArray();
                
                var result = (from c in _context.lkpApplication.AsEnumerable()
                              where ids.Contains(c.DepartmentId) && c.ComapnyId == compid
                              select c
                              ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetApplicationName", "Confirmation", userid, _context);


                return new JsonStringResult("[]");
            }
        }

        //public IActionResult CompanyUser()
        //{
        //    return View();
        //}

        [HttpGet]
        [AllowAnonymous]
        public IActionResult UserRoles(string returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult CompanyUser(string returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }

        [HttpGet]
        [AllowAnonymous]
        public IActionResult UserSecurity(string returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;
            return View();
        }
        
        private int GetCountryIdFromDataCenter(int DataCeneterId)
        {
            var result = (from c in _context.lkpCity
                          join s in _context.lkpState on c.StateId equals s.StateId
                          join co in _context.lkpCountry on s.StateId equals co.CountryId
                          join dc in _context.lkpDataCenter on c.CityId equals dc.CityId
                          select co.CountryId);

            if(result!=null)
            {
                if(result.Count() > 0)
                {
                    return result.FirstOrDefault();
                }
            }

            return 0;

        }
        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SaveUser([FromBody] lkpuserForController users)

        {


            if (!ModelState.IsValid)
            {
                var errors = ModelState.Select(x => x.Value.Errors)
                        .Where(y => y.Count > 0)
                        .ToList();


                return new JsonStringResult("Errors occured while saving user");
            }
            try
            {

                var userexists = (from u in _context.Users where u.Id == users.UserId select u).FirstOrDefault();

                if (userexists != null)
                {
                    var roles = _context.UserRoles.Where(x => x.UserId == users.UserId);
                    if (roles != null)
                    {
                        _context.UserRoles.RemoveRange(roles);

                        var countries = _context.Authorization_AllowedCountries.Where(x => x.UserId == users.UserId);
                        _context.Authorization_AllowedCountries.RemoveRange(countries);
                        var states = _context.Authorization_AllowedStates.Where(x => x.UserId == users.UserId);
                        _context.Authorization_AllowedStates.RemoveRange(states);
                        var Cities = _context.Authorization_AllowedCities.Where(x => x.UserId == users.UserId);
                        _context.Authorization_AllowedCities.RemoveRange(Cities);

                        var DataCentersid = _context.Authorization_AllowedDatacenters.Where(x => x.UserId == users.UserId);
                        _context.Authorization_AllowedDatacenters.RemoveRange(DataCentersid);
                        var Departments = _context.Authorization_AllowedDepartments.Where(x => x.UserId == users.UserId);

                        _context.Authorization_AllowedDepartments.RemoveRange(Departments);
                       

                        await _context.SaveChangesAsync();
                    }
                }




                var user = await _userManager.GetUserAsync(HttpContext.User);
                var companyid = user.CompanyId;
                var companyname = user.CompanyName;
                

                ApplicationUser user_1 = null;

                if (userexists!=null)
                {
                    user_1 = userexists;
                }
                else
                {
                     user_1 = new ApplicationUser
                    {
                        UserName = users.UserName,
                        Email = users.Email,
                        EmailConfirmed = true,
                        CompanyName = companyname,
                        CompanyId = companyid


                        //CountryName="Pakistan",
                        // CountryId="Pak123"
                    };
                }
                IdentityResult result=null;


                

                if (userexists != null)
                    
                {
                    
                    user_1.UserName = users.UserName;
                    user_1.Email = users.Email;
                    user_1.EmailConfirmed = true;
                    user_1.CompanyName = companyname;
                    user_1.CompanyId = companyid;
                    user_1.PasswordHash = _userManager.PasswordHasher.HashPassword(user_1, users.Pass);
                    result = await _userManager.UpdateAsync(user_1);
                }
                else
                {
                    result = await _userManager.CreateAsync(user_1, users.Pass);
                }

                if (result.Succeeded)
                {


                    var resultRole = await _userManager.AddToRoleAsync(user_1, users.Role);
                    //if (users.Role == "Admin")
                    //{
                    //  return new JsonStringResult("User withh admin privileges created successfully");
                    //}
                    //else
                    //{
                        if (resultRole.Succeeded)
                        {
                            //_context.Authorization_AllowedCountries.RemoveRange(_context.Authorization_AllowedCountries.Where(x=>x.UserId== user_1.Id));
                            //_context.SaveChanges();


                            //Add selected countries for the newly created user in Authorization_AllowedCountries table so that it could be accessed later
                            //split multiple countries id and save each countryid through a loop in Authorization_AllowedCountries table

                            if (users.SelectedCountries != "")
                            {
                                string countryids = Regex.Replace(users.SelectedCountries, @"[^,\d]", "0");
                                List<int> cntry = countryids.Split(',').Select(int.Parse).ToList();

                                foreach (int c in cntry)
                                {
                                    if (c != 0)
                                    {
                                        Authorization_AllowedCountries allowedcountries = new Authorization_AllowedCountries();
                                        allowedcountries.CountryId = c;
                                        allowedcountries.UserId = user_1.Id;
                                        _context.Add(allowedcountries);
                                    }
                                }
                            }


                            //Add selected states for the newly created user in Authorization_AllowedStates table so that it could be accessed later
                            //split multiple state id and save each stateid through a loop in Authorization_AllowedStates table

                            if (users.SelectedStates != "")
                            {
                                string stateids = Regex.Replace(users.SelectedStates, @"[^,\d]", "0");
                                List<int> st = stateids.Split(',').Select(int.Parse).ToList();

                                foreach (int c in st)
                                {
                                    if (c != 0)
                                    {
                                        Authorization_AllowedStates allowedstates = new Authorization_AllowedStates();
                                        allowedstates.StateId = c;
                                        allowedstates.UserId = user_1.Id;
                                        _context.Add(allowedstates);
                                    }
                                }
                            }

                            //Add selected cities for the newly created user in Authorization_AllowedCities table so that it could be accessed later
                            //split multiple city id and save each stateid through a loop in Authorization_AllowedCities table

                            if (users.SelectedCities != "")
                            {
                                string stateids = Regex.Replace(users.SelectedCities, @"[^,\d]", "0");
                                List<int> st = stateids.Split(',').Select(int.Parse).ToList();

                                foreach (int c in st)
                                {
                                    if (c != 0)
                                    {
                                        Authorization_AllowedCities allowedcities = new Authorization_AllowedCities();
                                        allowedcities.CityId = c;
                                        allowedcities.UserId = user_1.Id;
                                        _context.Add(allowedcities);
                                    }
                                }
                            }

                            //Add selected datacenters for the newly created user in Authorization_AllowedDatacenters table so that it could be accessed later
                            //split multiple datacenter id and save each stateid through a loop in Authorization_AllowedDatacenters table

                            if (users.SelectedDatacenters != "")
                            {
                                string datacenterids = Regex.Replace(users.SelectedDatacenters, @"[^,\d]", "0");
                                List<int> dc = datacenterids.Split(',').Select(int.Parse).ToList();

                                foreach (int c in dc)
                                {
                                    if (c != 0)
                                    {
                                        Authorization_AllowedDatacenters alloweddatacenters = new Authorization_AllowedDatacenters();
                                        alloweddatacenters.DatacenterId = c;
                                        alloweddatacenters.UserId = user_1.Id;
                                    alloweddatacenters.CountryId = GetCountryIdFromDataCenter(c);
                                        _context.Add(alloweddatacenters);
                                    }
                                }
                            }

                            //Add selected departments for the newly created user in Authorization_AllowedDepartments table so that it could be accessed later
                            //split multiple department id and save each stateid through a loop in Authorization_AllowedDepartments table

                            if (users.SelectedDepartments != "")
                            {
                                string departmentids = Regex.Replace(users.SelectedDepartments, @"[^,\d]", "0");
                                List<int> dp = departmentids.Split(',').Select(int.Parse).ToList();

                                foreach (int c in dp)
                                {
                                    if (c != 0)
                                    {
                                        Authorization_AllowedDepartments alloweddepartments = new Authorization_AllowedDepartments();
                                        alloweddepartments.DepartmentId = c;
                                        alloweddepartments.UserId = user_1.Id;
                                        _context.Add(alloweddepartments);
                                    }
                                }
                            }
                        if (users.SelectedApplicationNames != "")
                        {
                            string ApplicationName = Regex.Replace(users.SelectedApplicationNames, @"[^,\d]", "0");
                            List<int> ap = ApplicationName.Split(',').Select(int.Parse).ToList();

                            foreach (int c in ap)
                            {
                                if (c != 0)
                                {
                                    Authorization_AllowedApplications allowedApplications = new Authorization_AllowedApplications();
                                    allowedApplications.ApplicationId = c;
                                    allowedApplications.UserId = user_1.Id;
                                    _context.Add(allowedApplications);
                                }
                            }
                        }





                        _context.SaveChanges();
                           
                            var CountryNames = users.SelectedCountryNames;

                            String[] CountryNamesList = CountryNames.Split(",");
                            String[] StateIds = users.SelectedStates.Split(",");
                            string[] CityIds = users.SelectedCities.Split(",");
                            string[] DatacenterIds = users.SelectedDatacenters.Split(",");
                            string[] DepartmentsIds = users.SelectedDepartments.Split(",");
                            string[] ApplicationIds = users.SelectedApplicationNames.Split(",");
                        string contentRootPath = _env.ContentRootPath;
                            string webRootPath = _env.WebRootPath;
                            string folderPath = webRootPath + "\\App_Users\\"+users.UserName+"\\countries\\";
                            Directory.CreateDirectory(folderPath);
                            //if (users.Role == "Admin")
                            //{
                            //    var Countries = from countries in _context.lkpCountry
                            //                    where countries.CompanyId == user.CompanyId
                            //                    select countries.CountryName;
                            //    foreach (var c in Countries)
                            //    {
                            //        Directory.CreateDirectory(folderPath + "//" + c);

                            //        var States = from st in _context.lkpState
                            //                     join allstate in _context.lkpAllStates on st.AllStateId equals allstate.StateId
                            //                     where  allstate.CountryCode == c
                            //                     select st.StateName;

                            //        foreach(var s in States)
                            //        {
                            //            Directory.CreateDirectory(folderPath + c+ "\\" + s);
                            //        var cities = from city in _context.lkpCity
                            //                     join State in _context.lkpState on city.StateId equals State.StateId
                            //                      where State.StateName == s && city.CompanyId == user.CompanyId
                            //                     select city.CityName;
                            //        foreach(var ci in cities)
                            //        {
                            //            Directory.CreateDirectory(folderPath + c + "\\" + s+"\\"+ci);
                            //            var Datacenters = from da in _context.lkpDataCenter
                            //                              join City in _context.lkpCity on da.CityId equals City.CityId
                            //                              where City.CityName ==ci && da.CompanyId == user.CompanyId
                            //                              select da.DataCenterName;
                            //            foreach (var dac in Datacenters)
                            //            {
                            //                Directory.CreateDirectory(folderPath + c + "\\" + s + "\\" + ci+"\\"+dac);
                            //                var Departments = from dep in _context.lkpDepartment
                            //                                  join DataC in _context.lkpDataCenter on dep.DataCenterId equals DataC.DataCenterId
                            //                                  where DataC.DataCenterName == dac && dep.CompanyId == user.CompanyId
                            //                                  select dep.DepartmentName;
                            //                foreach( var de in Departments)
                            //                {
                            //                    Directory.CreateDirectory(folderPath + c + "\\" + s + "\\" + ci + "\\" + dac+"\\"+de);
                            //                }


                            //            }
                            //                }
                            //        }

                            //    }
                            //}
                            //else
                            //{
                            //    for (int x = 0; x < CountryNamesList.Length; x++)
                            //    {
                            //        Directory.CreateDirectory(folderPath + CountryNamesList[x]);
                            //        foreach (var s in StateIds)
                            //        {
                            //            var statename = from st in _context.lkpState
                            //                            join allstate in _context.lkpAllStates on st.AllStateId equals allstate.StateId
                            //                            where st.StateId.ToString() == s && allstate.CountryCode == CountryNamesList[x]
                            //                            select st.StateName;

                            //            if (statename.FirstOrDefault() != null)
                            //            {
                            //                Directory.CreateDirectory(folderPath + CountryNamesList[x] + "\\" + statename.FirstOrDefault());

                            //                foreach (var c in CityIds)
                            //                {
                            //                    var CityName = from ci in _context.lkpCity
                            //                                   join State in _context.lkpState on ci.StateId equals State.StateId

                            //                                   where ci.StateId.ToString() == s && ci.CityId.ToString() == c
                            //                                   select ci.CityName;
                            //                    if (CityName.FirstOrDefault() != null)
                            //                    {
                            //                        Directory.CreateDirectory(folderPath + CountryNamesList[x] + "\\" + statename.FirstOrDefault() + "\\" + CityName.FirstOrDefault());
                            //                        foreach (var dc in DatacenterIds)
                            //                        {
                            //                            var DataCenterName = from datacenter in _context.lkpDataCenter
                            //                                                 join city in _context.lkpCity on datacenter.CityId equals city.CityId
                            //                                                  where datacenter.CityId.ToString() == c && datacenter.DataCenterId.ToString() == dc
                            //                                                 select datacenter.DataCenterName;
                            //                            if (DataCenterName.FirstOrDefault() != null)
                            //                            {
                            //                                Directory.CreateDirectory(folderPath + CountryNamesList[x] + "\\" + statename.FirstOrDefault() + "\\" + CityName.FirstOrDefault() + "\\" + DataCenterName.FirstOrDefault());

                            //                                foreach (var de in DepartmentsIds)
                            //                                {
                            //                                    var DepartmentName = from department in _context.lkpDepartment
                            //                                                         join datacenter in _context.lkpDataCenter on department.DataCenterId equals datacenter.DataCenterId
                            //                                                         where department.DataCenterId.ToString() == dc && department.DepartmentId.ToString() == de
                            //                                                         select department.DepartmentName;
                            //                                    if (DepartmentName.FirstOrDefault() != null)
                            //                                    {
                            //                                        Directory.CreateDirectory(folderPath + CountryNamesList[x] + "\\" + statename.FirstOrDefault() + "\\" + CityName.FirstOrDefault() + "\\" + DataCenterName.FirstOrDefault() + "\\" + DepartmentName.FirstOrDefault());
                            //                                    foreach(var app in ApplicationIds)
                            //                                    {
                            //                                        var ApplicationName = from application in _context.lkpApplication
                            //                                                               join department in _context.lkpDepartment on application.DepartmentId equals department.DepartmentId
                            //                                                               where application.DepartmentId.ToString() == de && application.ApplicationId.ToString() == app
                            //                                                               select application.ApplicationName;
                            //                                        if(ApplicationName.FirstOrDefault()!=null)
                            //                                        {
                            //                                            Directory.CreateDirectory(folderPath + CountryNamesList[x] + "\\" + statename.FirstOrDefault() + "\\" + CityName.FirstOrDefault() + "\\" + DataCenterName.FirstOrDefault() + "\\" + DepartmentName.FirstOrDefault() + "\\" + ApplicationName.FirstOrDefault());

                            //                                        }
                            //                                    }
                            //                                    }
                            //                                }
                            //                            }

                            //                        }
                            //                    }
                            //                }


                            //            }


                            //        }

                            //    }
                            //}

                            return new JsonStringResult("SUCCESS");
                        }
                        else
                        {
                            return new JsonStringResult("User created successfully,but unable to assign role");
                        }
                    

                    // await _signInManager.SignInAsync(user, isPersistent: false);
                    // _logger.LogInformation("User created a new account with password.");
                    // return RedirectToLocal(returnUrl);
                }
                else
                {
                    return new JsonStringResult(result.ToString());
                }

                // AddErrors(result);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveUser", "Confirmation", userid, _context);

                
                return new JsonStringResult("Could not create account , Unkown Error occured");


            }




            // If we got this far, something failed, redisplay form
            //return View();
        }

        [HttpPost]
        [AllowAnonymous]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CompanyUser(RegisterViewModel model, string returnUrl = null)
        {
            ViewData["ReturnUrl"] = returnUrl;

            if (!ModelState.IsValid)
            {
                var errors = ModelState.Select(x => x.Value.Errors)
                        .Where(y => y.Count > 0)
                        .ToList();

                return View(model);
            }



            var user = new ApplicationUser
            {
                UserName = model.Email,
                Email = model.Email,
                CompanyName = model.CompanyName
                //CountryName="Pakistan",
                // CountryId="Pak123"
            };

            var result = await _userManager.CreateAsync(user, model.Password);

            if (result.Succeeded)
            {

                //_logger.LogInformation("User created a new account with password.");

                //var code = await _userManager.GenerateEmailConfirmationTokenAsync(user);
                //var callbackUrl = Url.EmailConfirmationLink(user.Id, code, Request.Scheme);

                //_logger.LogInformation("User created a new account with password.");
                //return RedirectToLocal(returnUrl);
            }

            AddErrors(result);

            // If we got this far, something failed, redisplay form
            return View(model);
        }

        private void AddErrors(IdentityResult result)
        {

            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(string.Empty, error.Description);
            }
        }

        private IActionResult RedirectToLocal(string returnUrl)
        {
            if (Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            return RedirectToAction(nameof(ConfirmationController.CompanyUser), "Company User");
        }



    }
}
