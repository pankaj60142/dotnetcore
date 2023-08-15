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
    public class DatacenterController : Controller
    {
        #region Declaration

        private readonly ApplicationDbContext _context;
        private List<lkpAllStates> allStates;
        private List<lkpCountry> countries;
        private List<lkpAllCountries> allcountries;
        private List<lkpAllCities> allcities;
        private List<lkpState> states;
        private readonly UserManager<ApplicationUser> _userManager;


        #endregion

        public DatacenterController(ApplicationDbContext context,UserManager<ApplicationUser> userManager)
        {
            _context = context;
            allStates = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            allcities = (from c in _context.lkpAllCities select c).ToList();
            _userManager = userManager;
            states = (from c in _context.lkpState select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
           
        }

        [HttpPost]
        public ActionResult DeleteDataCenter([FromBody] lkpDataCenter datacenter)
        {
            string message = "SUCCESS";

            try
            {
                var selectedDataCenter = (from c in _context.lkpDataCenter
                                    where c.DataCenterId == datacenter.DataCenterId
                                    select c).FirstOrDefault();

                if (selectedDataCenter == null)
                {

                    message = "Fail";
                }

                _context.lkpDataCenter.Remove(selectedDataCenter);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteDataCenter", "Datacenter", userid, _context);

                ex.ToString();
                return new JsonStringResult("Fail");
            }

        }



        
        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public JsonStringResult GetInsertedDataCenter(int compid)
        {
            try {
                var result = (from datacenter in _context.lkpDataCenter
                              join city in _context.lkpCity on datacenter.CityId equals city.CityId
                              where datacenter.CompanyId == compid
                              select new
                              {

                                  CityName = city.CityName,
                                  Datacenter = datacenter.DataCenterName,
                                  DataCenterId = datacenter.DataCenterId

                              }
                        ).ToList();







                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            catch (Exception ex) {

                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetInsertedDataCenter", "Datacenter", userid, _context);
                return new JsonStringResult("Unable to get states");
            }



        }
        [HttpPost]
           public JsonStringResult SaveDataCenter([FromBody] lkpDataCenter objDataCenter) {
            var message = "";
            try {
                var selectedDataCenter = (from c in _context.lkpDataCenter
                                    where c.DataCenterName == objDataCenter.DataCenterName && c.CompanyId==objDataCenter.CompanyId
                                    select c).FirstOrDefault();
                if (selectedDataCenter == null)
                {
                    lkpDataCenter dataCenter = new lkpDataCenter();

                    dataCenter.DataCenterName = objDataCenter.DataCenterName;
                    dataCenter.CityId = objDataCenter.CityId;
                    dataCenter.CompanyId = objDataCenter.CompanyId;
                    dataCenter.CreatedAt = DateTime.Now;
                    dataCenter.ModifiedAt = DateTime.Now;

                    _context.lkpDataCenter.Add(dataCenter);
                    _context.SaveChanges();
                }
                //Country found, Update it
                else
                {
                    selectedDataCenter.DataCenterName = objDataCenter.DataCenterName;
                    selectedDataCenter.CityId = objDataCenter.CityId;
                    selectedDataCenter.CompanyId = objDataCenter.CompanyId;
                    selectedDataCenter.ModifiedAt = DateTime.Now;
                    _context.SaveChanges();




                }

               message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch( Exception ex)
            { 
             var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
            ErrorLogExtension.RecordErrorLogException(ex, "SaveDataCenter", "Datacenter", userid, _context);

            message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
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
            catch( Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountry","Datacenter", userid, _context);

               
                return new JsonStringResult("Unable to get country ");
            }
            

        }

        [HttpPost]
        public JsonStringResult GetStateName(int countrycode, int compid)
        {
            try {
                var result = (from s in _context.lkpState.AsEnumerable()

                              where s.CountryId == countrycode && s.CompanyId == compid
                              select s
                  ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "Datacenter", userid, _context);


                return new JsonStringResult("Unable to get State");
            }


        }
        [HttpPost]
        public JsonStringResult GetCities(int StateId, int compid)
        {
            try {
                var result = (from s in _context.lkpCity.AsEnumerable()

                              where s.CompanyId == compid && s.StateId == StateId
                              select s
                        ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex){

                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCities", "Datacenter", userid, _context);


                return new JsonStringResult("Unable to get cities");
            }


        }


    }
}

