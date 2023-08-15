using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SmartAdmin.Seed.Extensions;
using Microsoft.AspNetCore.Identity;
using SmartAdmin.Seed.Models;

namespace SmartAdmin.Seed.Controllers
{
    
    public class CountryController : Controller
    {
        private readonly ApplicationDbContext _context;
       private List<lkpAllCountries> countries;
        private readonly UserManager<ApplicationUser> _userManager;
        public IActionResult Index()
        {
            return View();
        }
        Tbl_ErrorLog errorLog = new Tbl_ErrorLog();
        public CountryController(ApplicationDbContext context, UserManager<ApplicationUser> userManager) 
        {
            _context = context;
            _userManager = userManager;
            countries = (from c in _context.lkpAllCountries select c).ToList();
        }

        
        [HttpPost]
        public JsonStringResult GetCountries()
        {
            try
            {
                var resultCountries = (from c in countries

                                       select c).ToList();


                var json = JsonConvert.SerializeObject(resultCountries);
                return new JsonStringResult(json);

            }
            catch (System.Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountries", "Country", userid, _context);



                return new JsonStringResult("Unable to fetch Country");

            }

        }
        public ActionResult DeleteCountry([FromBody] lkpCountry Country)
        {
            string message = "SUCCESS";

            try
            {
                var selectedcountry = (from c in _context.lkpCountry
                                       where c.CountryName == Country.CountryName
                                       select c).FirstOrDefault();

                if (selectedcountry == null)
                {

                    message = "Fail";
                }

                _context.lkpCountry.Remove(selectedcountry);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {

                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteCountry", "Country", userid, _context);

                

                return new JsonStringResult("Fail");
            }

        }
        [HttpPost]
        public async Task<ActionResult> SaveCountry([FromBody] lkpCountry Country)
        {

            try
            {
                

                 Country.CountryName = Country.CountryName;
                    Country.Latitude = Country.Latitude;
                    Country.Longitude = Country.Longitude;
                    Country.CreatedAt = DateTime.Now;
                    Country.ModifiedAt = DateTime.Now;
                    Country.Active = true;

                   _context.lkpCountry.Add(Country);
                   await _context.SaveChangesAsync(true);
                
                string message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveCountry", "Country", userid, _context);
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }






        }

        [HttpPost]
        public JsonStringResult FillcountriesGrid(int CompanyId) {

            try {
                var result = (from c in _context.lkpCountry.AsEnumerable()
                              join allcountries in countries on c.CountryName equals allcountries.CountryName
                              where c.CompanyId == CompanyId
                              select new { allcountries.CountryCode, c.CountryName, c.CountryId }
                         ).ToList();

                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "FillcountriesGrid", "Country", userid, _context);
                string message = "Unable to fetch" + ex.Message;
                return new JsonStringResult(message);

            }
        }


      
    }
}
