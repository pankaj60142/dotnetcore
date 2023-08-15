using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Extensions;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class ApplicationController: Controller
    {
        public IActionResult Index()
        {
            return View();
        }

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        public ApplicationController(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
        {


            _userManager = userManager;
            _context = context;



        }
        public ActionResult DeleteApplication([FromBody] lkpApplication applicationobj)
        {
            string message = "SUCCESS";

            try
            {
                var selectedApplication = (from c in _context.lkpApplication
                                          where c.ApplicationId == applicationobj.ApplicationId
                                          select c).FirstOrDefault();

                if (selectedApplication == null)
                {

                    message = "Fail";
                }

                _context.lkpApplication.Remove(selectedApplication);
                _context.SaveChanges();

                return new JsonStringResult(message);
            }
            catch (System.Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "DeleteApplication", "Application", userid, _context);
                return new JsonStringResult("Fail");
            }

        }
        public ActionResult EditApplication(int ApplicationId, int ComapnyId)
        {

            try
            {
                var result = (from s in _context.lkpApplication.AsEnumerable()

                              where s.ApplicationId == ApplicationId && s.ComapnyId == ComapnyId
                              select s
                             ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            } 
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "EditApplication", "Application", userid, _context);

                return new JsonStringResult("Unable to Get Filter Applications ");
            }
        }
        public ActionResult Saveapplication(int compid, string applicationname, string departments,int ApplicationId, string application)
        {


            try
            {
                if (ApplicationId != 0) {
                    var FoundApplication = (from c in _context.lkpApplication
                                            where c.ApplicationId == ApplicationId
                                            select c).FirstOrDefault();
                    FoundApplication.ApplicationName = application;
                    _context.SaveChanges();

                }
                else {
                    string departmentid = Regex.Replace(departments, @"[^,\d]", "0");
                    List<int> st = departmentid.Split(',').Select(int.Parse).ToList();
                    var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();




                    if (departments != null)
                    {

                        foreach (int c in st)
                        {
                            lkpApplication app = new lkpApplication();
                            app.ApplicationName = applicationname;
                            app.DepartmentId = c;
                            app.ComapnyId = compid;
                            app.CreatedBy = userid;
                            _context.lkpApplication.Add(app);
                        }
                    }
                }

                _context.SaveChanges();
                string message = "SUCCESS";
                return new JsonStringResult(message);

            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveApplication", "Application", userid, _context);



                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }






        }

        public JsonStringResult GetFilterApplications(int compid,string departments)
        {
            try
            {
                string departmentid = Regex.Replace(departments, @"[^,\d]", "0");
                List<int> st = departmentid.Split(',').Select(int.Parse).ToList();
                 var result = (from s in _context.lkpApplication.AsEnumerable()
                               join department in _context.lkpDepartment.AsEnumerable() on s.DepartmentId equals department.DepartmentId
                               join datacenter in _context.lkpDataCenter.AsEnumerable() on department.DataCenterId equals datacenter.DataCenterId
                               join City in _context.lkpCity.AsEnumerable() on  datacenter.CityId equals City.CityId
                               join State in _context.lkpState.AsEnumerable() on City.StateId equals State.StateId
                               join Country in _context.lkpCountry.AsEnumerable() on State.CountryId equals Country.CountryId

                               where (st.Contains(s.DepartmentId)) && s.ComapnyId == compid
                              select new { s.ApplicationId, s.ApplicationName, department.DepartmentName,datacenter.DataCenterName,City.CityName,State.StateName,Country.CountryName }
                             ).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

              
            }


            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveApplication", "Application", userid, _context);

                return new JsonStringResult("Unable to Get Filter Applications ");

            }
        }
    }
}
