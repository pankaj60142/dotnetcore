#region Using

using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SmartAdmin.Seed.Controllers.Settings;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.Entities;
using System.Linq;
using Newtonsoft.Json;
using Microsoft.AspNetCore.Identity;
using System.Threading.Tasks;
using SmartAdmin.Seed.Extensions;
using System;
using System.Text.RegularExpressions;
#endregion

namespace SmartAdmin.Seed.Controllers
{
    [Authorize]
    //[AllowAnonymous]
    public class HomeController : Controller
    {
        public IActionResult Index() => View();
        private readonly UserManager<ApplicationUser> _userManager;


        #region Declaration

        private readonly ApplicationDbContext _context;
        private List<lkpAllCountries> countries;
        private IList<string> roles;
        int companyid = 0;

        #endregion
        public HomeController(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
        {


            _userManager = userManager;
            _context = context;
            countries = (from c in _context.lkpAllCountries select c).ToList();



        }

        private async Task<int> GetCompanyId()
        {
            var user = await _userManager.GetUserAsync(HttpContext.User);
            roles = await _userManager.GetRolesAsync(user);
            companyid = user.CompanyId;

            return companyid;
        }




        public IActionResult Error() => View(new ErrorViewModel
        {
            RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier
        });


        [HttpPost]
        public async Task<JsonStringResult> GetDefinedCountries()
        {
            try
            {
                await GetCompanyId();

                var result = (from c in _context.lkpCountry.AsEnumerable()
                              join allcountries in countries on c.CountryName equals allcountries.CountryName
                              where c.CompanyId == companyid
                              select new { name = c.CountryName, id = allcountries.MapId, countryid = c.CountryId }
                            ).ToList();

                var finalresult = (from r in result
                                       // join allowedcountries in _context.Authorization_AllowedCountries on r.countryid equals allowedcountries.CountryId

                                   select new { name = r.name, id = r.id }).ToList();



                var json = JsonConvert.SerializeObject(finalresult);
                return new JsonStringResult(json);


            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDefinedCountries", "Home", userid, _context);

                return new JsonStringResult("unable to find Countries");
            }


        }
        [HttpPost]
        public JsonStringResult GetDataCenterTreeForCountry(int countryid)
        {
            try
            {
                List<DataCentersTree> lstTree = new List<DataCentersTree>();
                var country = (from c in _context.lkpCountry.AsEnumerable()
                               join allcountries in countries on c.CountryName equals allcountries.CountryName
                               where allcountries.MapId == countryid
                               select new DataCentersTree
                               {
                                   id = c.CountryId,
                                   name = c.CountryName,
                                   parentid = null
                               }).FirstOrDefault();

                //fill states of selected country

                if (country != null)
                {
                    var state =
      ((from word in _context.lkpState.AsEnumerable()
        where word.CountryId == country.id
        select new DataCentersTree
        {
            id = word.StateId,
            name = word.StateName,
            matchingid = "state" + word.StateId,
            parentid = null
        })
       ).ToList();

                    if (state != null)
                    {
                        foreach (var a in state)
                        {

                            FillCities(a.id, a.matchingid, lstTree);

                            //add state to list
                            lstTree.Add(a);

                        }





                    }
                }


                if (lstTree.Count > 0)
                {
                    foreach (DataCentersTree g in lstTree)
                        if (g.parentid != null)
                            lstTree.Single(group => group.matchingid == g.parentid).children.Add(g);



                    var rootgroups = lstTree.Where(g => g.parentid == null);


                    country.children.AddRange(rootgroups);
                    var json = JsonConvert.SerializeObject(country);
                    return new JsonStringResult(json);
                }
                else
                {

                    DataCentersTree tree = new DataCentersTree();
                    tree.name = "No data";

                    var json = JsonConvert.SerializeObject(tree);
                    return new JsonStringResult(json);
                }




            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDataCenterTreeForCountry", "Home", userid, _context);

                return new JsonStringResult("unable to find DataCenter Tree For Country");
            }
        }

        private void FillCities(int stateid, string matchingid, List<DataCentersTree> lstTree)
        {
            try
            {
                var result =
    ((from word in _context.lkpCity.AsEnumerable()
      where word.StateId == stateid
      select new DataCentersTree
      {
          id = word.CityId,
          name = word.CityName,
          matchingid = "city" + word.CityId,
          parentid = matchingid
      })
    ).ToList();


                if (result != null)
                {
                    foreach (var a in result)
                    {

                        FillDataCenters(a.id, a.matchingid, lstTree);

                        //add state to list
                        lstTree.Add(a);

                    }





                }


            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "FillCities", "Home", userid, _context);


            }
        }
        private void FillDataCenters(int cityid, string matchingid, List<DataCentersTree> lstTree)
        {
            try
            {
                var result =
        ((from word in _context.lkpDataCenter.AsEnumerable()
          where word.CityId == cityid
          select new DataCentersTree
          {
              id = word.DataCenterId,
              name = word.DataCenterName,
              matchingid = "datacenter" + word.DataCenterId,
              parentid = matchingid
          })
        ).ToList();
                lstTree.AddRange(result);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "FillDataCenters", "Home", userid, _context);
            }
        }



        public ActionResult Saveapplication(int compid, string applicationname, string departments, int ApplicationId)
        {


            try
            {
                var FoundApplication = (from c in _context.lkpApplication
                                        where c.ApplicationName == applicationname
                                        select c).FirstOrDefault();
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
        public JsonStringResult GetDepartmentForDataCenter(int DataCenterId)
        {

            try
            {



                var result = (from d in _context.lkpDepartment.AsEnumerable()
                              join a in _context.lkpApplication.AsEnumerable() on d.DepartmentId equals a.DepartmentId into ps
                              from p in ps.AsEnumerable().DefaultIfEmpty()
                              where d.DataCenterId == DataCenterId
                              select new { id = d.DepartmentId, id_field = d.DepartmentName, id_application = p.ApplicationName ?? "No Application", value = 1 }
                               ).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);


            }

            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentForDataCenter", "Home", userid, _context);
                return new JsonStringResult("unable get Department For DataCenter");
            }
        }

        [HttpPost]
        public async Task<JsonStringResult> GetLoggedInRole()
        {

            try
            {

                string result_Name = "";

                var user = await _userManager.GetUserAsync(HttpContext.User);
                var RoleName = (from ur in _context.UserRoles.AsEnumerable()
                                join r in _context.Roles.AsEnumerable() on ur.RoleId equals r.Id
                                where ur.UserId.ToString() == user.Id.ToString()
                                select r).ToList();

                if (RoleName != null)
                {
                    if (RoleName.Count() > 0)
                    {
                        result_Name = RoleName.FirstOrDefault().Name.ToLower();

                    }
                }


                if (result_Name == "")
                    result_Name = "admin";



                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = result_Name });
                return new JsonStringResult(json);


            }

            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetLoggedInRole", "Home", userid, _context);
                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "none" });
                return new JsonStringResult(json);
            }
        }


    }

    public class DataCentersTree
    {

        public int id { get; set; }
        public string matchingid { get; set; }
        public string name { get; set; }
        public string parentid { get; set; }
        public List<DataCentersTree> children { get; set; }

        public DataCentersTree()
        {
            this.children = new List<DataCentersTree>();
        }
    }


}
