using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Extensions;
using Microsoft.AspNetCore.Identity;
using SmartAdmin.Seed.Models;

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class CityController : Controller
    {
        private readonly ApplicationDbContext _context; 
        private List<lkpCountry> countries;
        private List<lkpState> states=new List<lkpState>();
        private readonly UserManager<ApplicationUser> _userManager;

        public CityController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            countries = (from c in _context.lkpCountry select c).ToList();
            _userManager = userManager;
            // states = (from s in _context.lkpState select s).ToList();
            // states = (from c in _context.lkpAllStates select c).ToList();
        }
        public IActionResult Index()
        {
            return View();
        }
        [HttpPost]
        public ActionResult DeleteCity([FromBody] lkpCity city)
        {
            string message = "SUCCESS";

            try
            {
                var selectedcity = (from c in _context.lkpCity
                                    where c.CityId == city.CityId
                                    select c).FirstOrDefault();

                if (selectedcity == null)
                {

                    message = "Fail";
                }

                _context.lkpCity.Remove(selectedcity);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCity", "City", userid, _context);

                return new JsonStringResult("Fail");
            }

        }
        [HttpPost]
        public ActionResult Deletedatacenter([FromBody] lkpDataCenter datacenter)
        {
            string message = "SUCCESS";

            try
            {
                var selecteddatacenter = (from c in _context.lkpDataCenter
                                          where c.DataCenterId == datacenter.DataCenterId
                                          select c).FirstOrDefault();

                if (selecteddatacenter == null)
                {

                    message = "Fail";
                }

                _context.lkpDataCenter.Remove(selecteddatacenter);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "Deletedatacenter", "City", userid, _context);


                return new JsonStringResult("Fail");
            }

        }

        [HttpPost]
        public JsonStringResult GetInsertedCities(int compid)
        {
            try {
                var result = (from cities in _context.lkpCity
                              join state in _context.lkpState on cities.StateId equals state.StateId
                              where cities.CompanyId == compid
                              select new
                              {

                                  StateName = state.StateName,
                                  CityName = cities.CityName,
                                  CityId = cities.CityId,

                              }
                             ).ToList();



                



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }


            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetInsertedCities", "City", userid, _context);

                return new JsonStringResult("Unable to find cities");

            }
        }
        [HttpPost]
        public ActionResult SaveCity([FromBody] lkpCity objCity)
        {
            string message="";

            try
            {
                
                var selectedcity = (from c in _context.lkpCity
                                    where c.CityName == objCity.CityName
                                select c).FirstOrDefault();

              

             
                //Country name dows not exist, so add a new country
                if (selectedcity == null)
                {
                    lkpCity city = new lkpCity();

                    city.CityName = objCity.CityName;
                    city.StateId = objCity.StateId;
                    city.CompanyId = objCity.CompanyId;
                    city.Latitude = objCity.Latitude;
                    city.Longitude = objCity.Longitude;
                    city.CreatedAt = DateTime.Now;
                    city.ModifiedAt = DateTime.Now;
                    city.Active = true;
                    
                    _context.lkpCity.Add(city);
                    _context.SaveChanges();
                }
                //Country found, Update it
                else
                {
                    selectedcity.CityName = objCity.CityName;
                    selectedcity.Latitude = selectedcity.Latitude;
                    selectedcity.Longitude = selectedcity.Longitude;
                    selectedcity.ModifiedAt = DateTime.Now;
                    _context.SaveChanges();




                }

                message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveCity", "City", userid, _context);

                message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }



        }
        [HttpPost]
        public JsonStringResult GetCities(string CountryName, string StateName)
        {
            try {
                var result = (from s in _context.lkpAllCities.AsEnumerable()

                              where s.CountryName == CountryName && s.StateName == StateName
                              select s
                  ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCities", "City", userid, _context);

                return new JsonStringResult("Unable to get cities");

            }


        }

        [HttpPost]
        public JsonStringResult GetStateName(int countrycode ,int compid)
        {
            try {
                var result = (from s in _context.lkpState.AsEnumerable()

                              where s.CountryId == countrycode && s.CompanyId == compid
                              select s
                   ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "City", userid, _context);

                return new JsonStringResult("Unable to get State");
            }


        }

        [HttpPost]
        public JsonStringResult GetCountry(int Compid)
        {
            try {
                var resultCountry = (from c in countries
                                     where c.CompanyId == Compid
                                     select c).ToList();




                var json = JsonConvert.SerializeObject(resultCountry);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountry", "City", userid, _context);

                return new JsonStringResult("Unable to get Country");
            }

        }




    }







}

