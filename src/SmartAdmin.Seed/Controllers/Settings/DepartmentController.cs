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

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class DepartmentController : Controller
    {

       

        #region Declaration

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private List<lkpCountry> countries;
        #endregion

            public DepartmentController(ApplicationDbContext context,UserManager<ApplicationUser> userManager)
        {
            _context = context;
            _userManager = userManager;
            countries = (from c in _context.lkpCountry select c).ToList();
            
        }


        public IActionResult Index()
        {
            return View();
        }
        [HttpPost]
        public ActionResult Deletedepartment([FromBody] lkpDepartment department)
        {
            string message = "SUCCESS";

            try
            {
                var selecteddepartment = (from c in _context.lkpDepartment
                                          where c.DepartmentId == department.DepartmentId
                                          select c).FirstOrDefault();

                if (selecteddepartment == null)
                {

                    message = "Fail";
                }

                _context.lkpDepartment.Remove(selecteddepartment);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "Deletedepartment", "Department", userid, _context);
                return new JsonStringResult("Fail");
            }

        }
        [HttpPost]
        public JsonStringResult GetInsertedDepartment(int compid)
        {
            try {
                var result = (from Department in _context.lkpDepartment
                              join datacenter in _context.lkpDataCenter on Department.DataCenterId equals datacenter.DataCenterId
                              where Department.CompanyId == compid
                              select new
                              {

                                  DataCenterName = datacenter.DataCenterName,
                                  DepartmentName = Department.DepartmentName,
                                  DepartmentId = Department.DepartmentId

                              }
                        ).ToList();







                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }


            catch ( Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetInsertedDepartment", "Department", userid, _context);
                return new JsonStringResult("Unable to find Inserted Department");

            }
        }
        [HttpPost]
        public JsonStringResult GetCountry(int Compid)
        {
            try
            {
                var resultCountry = (from c in countries
                                     where c.CompanyId == Compid
                                     select c).ToList();




                var json = JsonConvert.SerializeObject(resultCountry);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountry", "Department", userid, _context);
                return new JsonStringResult("Unable to find Country");
            }

        }

        [HttpPost]
        public JsonStringResult SaveDepartment([FromBody] lkpDepartment objDepartment)
        {
            var message = "";
            try
            {
                var selectedDepartment = (from c in _context.lkpDepartment
                                          where c.DepartmentName == objDepartment.DepartmentName && c.CompanyId== objDepartment.CompanyId
                                          select c).FirstOrDefault();
                if (selectedDepartment == null)
                {
                    lkpDepartment department = new lkpDepartment();

                    department.DepartmentName = objDepartment.DepartmentName;
                    department.DataCenterId = objDepartment.DataCenterId;
                    department.CompanyId = objDepartment.CompanyId;
                    department.CreatedAt = DateTime.Now;
                    department.ModifiedAt = DateTime.Now;
                    department.Active = true;
                    _context.lkpDepartment.Add(department);
                    _context.SaveChanges();
                }
                //Country found, Update it
                else
                {
                    selectedDepartment.DepartmentName = objDepartment.DepartmentName;
                    selectedDepartment.DataCenterId = objDepartment.DataCenterId;
                    selectedDepartment.CompanyId = objDepartment.CompanyId;
                   
                    selectedDepartment.ModifiedAt = DateTime.Now;
                    _context.SaveChanges();




                }

                message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveDepartment", "Department", userid, _context);

                message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }

        }
        [HttpPost]
        public JsonStringResult GetDataCenter(int CityName, int compid)
        {
            try {
                var result = (from s in _context.lkpDataCenter.AsEnumerable()

                              where s.CityId == CityName && s.CompanyId == compid
                              select s
                  ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDataCenter", "Department", userid, _context);

               return new JsonStringResult("Unable to get datacenter");
            }
            }
        [HttpPost]
        public JsonStringResult GetStateName(int countrycode, int compid)
        {
            try
            {
                var result = (from s in _context.lkpState.AsEnumerable()

                              where s.CountryId == countrycode && s.CompanyId == compid
                              select s
                        ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "Department", userid, _context);

                
                return new JsonStringResult("Unable get State name");
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
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCities", "Department", userid, _context);

               
                return new JsonStringResult("Unable get Cities");
            }
        }

        [HttpPost]
        public JsonStringResult GetDepartment(int datacenter, int compid)
        {
            try {
                var result = (from s in _context.lkpDepartment.AsEnumerable()

                              where s.DataCenterId == datacenter && s.CompanyId == compid
                              select s
                        ).ToList();




                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDepartment", "Department", userid, _context);

                
                return new JsonStringResult("Unable to Get Department");
            }
            }
    }


}
