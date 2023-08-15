using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using SmartAdmin.Seed.Data;
using Newtonsoft.Json;

namespace SmartAdmin.Seed.Controllers
{
    public class TestController : Controller
    {
        private readonly ApplicationDbContext _context;
        public TestController(ApplicationDbContext context)
        {
            _context = context;
           }
        public IActionResult Index()
        {
            return View();
        }
        [HttpPost]
        public JsonStringResult GetStateName(string SelectedCountryIds1 , int compid)
        {
            try
            {
                string countryids = Regex.Replace(SelectedCountryIds1, @"[^,\d]", "0");

                int[] ids = countryids.Split(',').Select(int.Parse).ToArray();



                var result = (from s in _context.lkpState
                              where  (ids.Contains(s.CountryId)) && s.CompanyId==compid
                              select s
                              ).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception)
            {

                return new JsonStringResult("[]");
            }

        }

        public class JsonStringResult : ContentResult
        {
            public JsonStringResult(string json)
            {
                Content = json;
                ContentType = "application/json";
            }
        }
    }

}
