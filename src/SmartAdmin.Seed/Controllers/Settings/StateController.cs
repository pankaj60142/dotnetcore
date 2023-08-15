using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Extensions;
using SmartAdmin.Seed.Models;
using Microsoft.AspNetCore.Identity;

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class StateController : Controller
    {

        #region Declaration

        private readonly ApplicationDbContext _context;
        private List<lkpAllStates> states;
        private List<lkpCountry> countries;
        private List<lkpAllCountries> allcountries;
        private readonly UserManager<ApplicationUser> _userManager;
        #endregion

        public StateController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {

            _context = context;
            states = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            _userManager = userManager;
            allcountries = (from c in _context.lkpAllCountries select c).ToList();

        }
        public IActionResult Index()
        {
            return View();
        }
        [HttpPost]
        public ActionResult DeleteState([FromBody] lkpState state)
        {
            string message = "SUCCESS";

            try
            {
                var selectedstate = (from c in _context.lkpState
                                     where c.StateId == state.StateId
                                     select c).FirstOrDefault();

                if (selectedstate == null)
                {

                    message = "Fail";
                }

                _context.lkpState.Remove(selectedstate);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteState", "State", userid, _context);

                return new JsonStringResult("Fail");
            }

        }

        [HttpPost]
        public JsonStringResult GetInsertedStates()
        {
            try {
                var result = (from state in _context.lkpState
                              join country in _context.lkpCountry on state.CountryId equals country.CountryId
                              select new
                              {
                                  CountryName = country.CountryName,
                                  StateName = state.StateName,
                                  StateId = state.StateId
                              }
                          ).ToList();





                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            catch(System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetInsertedStates", "State", userid, _context);
                return new JsonStringResult("States not Found"); 
            }



        }

        [HttpPost]
        public JsonStringResult GetStateName(string countrycode)
        {
            try {
                var result = (from s in states

                              where s.CountryCode == countrycode
                              select s
                      ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "State", userid, _context);
                return new JsonStringResult("States not Found");
            }



        }


        public ActionResult SaveState([FromBody] lkpState Stateobj)
         {

            try
            {
                lkpState state = new lkpState();
                state.AllStateId = Stateobj.AllStateId;
                state.CountryId = Stateobj.CountryId;
                state.CompanyId = Stateobj.CompanyId;
                state.StateName = Stateobj.StateName;
                state.Latitude = Stateobj.Latitude;
                state.Longitude = Stateobj.Longitude;
                state.CreatedAt = DateTime.Now;
                state.ModifiedAt = DateTime.Now;
                

                _context.lkpState.Add(state);
                _context.SaveChanges();

                string message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveState", "State", userid, _context);



                  string message = "Fail.." + ex.Message;
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
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountry", "State", userid, _context);



                return new JsonStringResult("Unable to get Country");

            }

        }




    }


}
