using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SmartAdmin.Seed.Controllers.Settings;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Extensions;
namespace SmartAdmin.Seed.Controllers
{
    public class ImportSettingsController : Controller
    {

        #region Declaration

        private readonly ApplicationDbContext _context;
        private List<lkpAllCountries> allcountries;
        private List<lkpAllStates> allstates;
        #endregion
        public ImportSettingsController(ApplicationDbContext context)
        {

            _context = context;
            allstates = (from c in _context.lkpAllStates select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
        }


        // GET: /<controller>/  
        public IActionResult Index()
        {

            return View();
        }

        [HttpPost]
        public ActionResult UploadFile(IFormFile file, string CompanyId)
        {


            List<string> errors = new List<string>(); // added this just to return something
            using (var transaction = _context.Database.BeginTransaction())
            {
                try
                {



                    if (file != null)
                    {
                        //read all information from csv file and save it to list of type ImportSCVSettings
                        List<ImportCSVSettings> lstCSV;
                        lstCSV = ReadAsList(file);

                        //Process csv to save countries

                        var countries = from csv in lstCSV
                                        group csv by csv.Country into g
                                        select new { Country = g.Key, AllValues = g.ToList() };


                        //Process csv to save states
                        var states = from csv in lstCSV
                                     group csv by csv.State into g
                                     select new { State = g.Key };

                        //var StateResultList = states
                        //    .Where(sr => !allstates
                        //    .Any(s => sr.State == s.StateName));

                        //if (StateResultList.Count() >  0)
                        //{
                        //    ModelState.AddModelError(string.Empty, "Unable to get State.");
                        //    return View();
                        //}

                        var PersonResultList = countries
                       .Where(pr => !allcountries
                                .Any(p => pr.Country == p.CountryName));








                        if (PersonResultList.Count() > 0)
                        {
                            ModelState.AddModelError(string.Empty, "Unable to get Country.");

                            return View();
                        }

                        var result = from csv in countries
                                     join country in allcountries on csv.Country.ToLower() equals country.CountryName.ToLower()

                                     select new
                                     {

                                         CountryName = csv.Country

                                     };





                        foreach (var cntry in countries)
                        {


                            var selectedcountry = (from c in allcountries
                                                   where c.CountryName.ToLower() == cntry.Country.ToLower()
                                                   select c).FirstOrDefault();

                            lkpCountry Country = new lkpCountry();
                            Country.CountryName = selectedcountry.CountryName;
                            Country.Latitude = selectedcountry.latitude;
                            Country.Longitude = selectedcountry.longitude;
                            Country.CreatedAt = DateTime.Now;
                            Country.ModifiedAt = DateTime.Now;
                            Country.CompanyId = int.Parse(CompanyId);
                            Country.Active = true;



                            var alreadyexists = _context.lkpCountry.Where(x => x.CountryName == selectedcountry.CountryName);

                            if (alreadyexists == null || alreadyexists.Count() == 0)
                            {
                                _context.lkpCountry.Add(Country);
                               
                            }


                        }

                        _context.SaveChanges();

                        foreach (var cntry in countries)
                        {

                            var countryvaluesonly = (from c in cntry.AllValues where c.Country == cntry.Country select c).ToList();

                            var countryid = (from c in _context.lkpCountry where c.CountryName == cntry.Country select c).FirstOrDefault();

                            //get all states of selected country
                            ProcessStates(cntry.Country, countryid.CountryId, countryvaluesonly, int.Parse(CompanyId));


                        }



                        transaction.Commit();


                    }

                }
                catch (Exception ex)
                {
                    transaction.Rollback();
                    if(ex.InnerException!=null)
                    errors.Add(ex.InnerException.Message.ToString());
                    else
                        errors.Add("Please verify data is correct");

                    return Content(errors[0].ToString());
                }

                return Content("success");
            }
        }

        private void ProcessStates(string countryname, int countryid, List<ImportCSVSettings> values, int companyId)
        {
            var states = from csv in values
                         group csv by csv.State into g
                         select new { State = g.Key, AllValues = g.ToList() };

            foreach (var currentstate in states)
            {

                var selectedstate = (from c in allstates
                                     where c.StateName.ToLower() == currentstate.State.ToLower() && c.CountryCode == countryname
                                     select c).FirstOrDefault();



                lkpState state = new lkpState();
                if (selectedstate != null)
                {
                    state.StateName = selectedstate.StateName;
                    state.CountryId = countryid;
                    state.Latitude = selectedstate.Latitude;
                    state.Longitude = selectedstate.Longitude;
                    state.CreatedAt = DateTime.Now;
                    state.ModifiedAt = DateTime.Now;
                    state.AllStateId = selectedstate.StateId;
                    state.CompanyId = companyId;
                    state.Active = true;

                    var alreadyexists = _context.lkpState.Where(x => x.StateName == selectedstate.StateName);

                    if (alreadyexists == null || alreadyexists.Count() == 0)
                    {
                        _context.lkpState.Add(state);

                    }
                }
                else
                {

                    lkpAllStates st = new lkpAllStates();
                    st.StateName = currentstate.State;
                    st.CountryCode = countryname;
                    st.Latitude = "";
                    st.Longitude = "";

                    Random generator = new Random();
                    String r = generator.Next(0, 1000000).ToString("D6");
                    st.StateId = int.Parse(r);
                    _context.lkpAllStates.Add(st);

                    state.StateName = currentstate.State;
                    state.CountryId = countryid;
                    state.Latitude = "";
                    state.Longitude = "";
                    state.CreatedAt = DateTime.Now;
                    state.ModifiedAt = DateTime.Now;
                    state.AllStateId = int.Parse(r);
                    state.Active = true;
                    state.CompanyId = companyId;


                    _context.lkpState.Add(state);


                }





            }

            _context.SaveChanges();

            foreach (var state in states)
            {

                var statevaluesonly = (from c in state.AllValues where c.State == state.State select c).ToList();

                var stateid = (from c in _context.lkpState where c.StateName == state.State select c).FirstOrDefault();

                //get all cities of selected state
                ProcessCities(state.State, stateid.StateId, countryname, statevaluesonly,companyId);
            }

        }

        private void ProcessCities(string statename, int stateid, string countryname, List<ImportCSVSettings> values, int companyId)
        {
            var cities = from csv in values
                         group csv by csv.City into g

                         select new { City = g.Key, AllValues = g.ToList() };

            foreach (var currentcity in cities)
            {
                var selectedcity = (from c in _context.lkpAllCities
                                    where c.StateName.ToLower() == statename.ToLower() && c.CountryName.ToLower() == countryname.ToLower() && c.CityName.ToLower() == currentcity.City.ToLower()
                                    select c).FirstOrDefault();


                lkpCity city = new lkpCity();

                if (selectedcity != null)
                {
                    city.CityName = selectedcity.CityName;
                    city.StateId = stateid;
                    city.Latitude = selectedcity.Latitude;
                    city.Longitude = selectedcity.Longitude;
                    city.CreatedAt = DateTime.Now;
                    city.ModifiedAt = DateTime.Now;
                    city.Active = true;
                    city.CompanyId = companyId;
                    
                    var alreadyexists = _context.lkpCity.Where(x => x.CityName == selectedcity.CityName && x.StateId == stateid);

                    if (alreadyexists == null || alreadyexists.Count() == 0)
                    {
                        _context.lkpCity.Add(city);

                    }

                }
                else
                {


                    lkpAllCities st = new lkpAllCities();
                    st.CityName = currentcity.City;
                    st.StateName = statename;

                    st.Latitude = "";
                    st.Longitude = "";
                    st.CountryName = countryname;

                    _context.lkpAllCities.Add(st);

                    city.CityName = currentcity.City;
                    city.StateId = stateid;
                    city.Latitude = "";
                    city.Longitude = "";
                    city.CreatedAt = DateTime.Now;
                    city.ModifiedAt = DateTime.Now;
                    city.Active = true;
                    
                    _context.lkpCity.Add(city);




                }

              

            }
            _context.SaveChanges();

            foreach (var city in cities)
            {

                var cityvaluesonly = (from c in city.AllValues where c.City == city.City select c).ToList();

                var cityid = (from c in _context.lkpCity where c.CityName == city.City select c).FirstOrDefault();
                //get all datacenters of selected city
                ProcessDatacenters(city.City, cityid.CityId, cityvaluesonly,companyId);
            }

        }

        private void ProcessDatacenters(string cityname, int cityid, List<ImportCSVSettings> values, int companyId)
        {
            var datacenters = from csv in values
                              group csv by csv.DataCenter into g
                              select new { Datacenter = g.Key, AllValues = g.ToList() };


       


            foreach (var datacenter in datacenters)
            {

                var selecteddatacenter = (from c in _context.lkpDataCenter
                                          where c.CityId == cityid && c.DataCenterName.ToLower() == datacenter.Datacenter.ToLower()
                                          select c).FirstOrDefault();

                if (selecteddatacenter == null)
                {
                    lkpDataCenter DataCenterValue = new lkpDataCenter();

                    DataCenterValue.CityId = cityid;
                    DataCenterValue.DataCenterName = datacenter.Datacenter;
                    DataCenterValue.CreatedAt = DateTime.Now;
                    DataCenterValue.ModifiedAt = DateTime.Now;
                    DataCenterValue.Active = true;
                    DataCenterValue.CompanyId = companyId;
                    _context.lkpDataCenter.Add(DataCenterValue);
                }
              
            }

            _context.SaveChanges();
            foreach (var datacenter in datacenters)
            {

                var datacentervaluesonly = (from c in datacenter.AllValues where c.DataCenter == datacenter.Datacenter select c).ToList();

                var datacenterid = (from c in _context.lkpDataCenter where c.DataCenterName == datacenter.Datacenter select c).FirstOrDefault();

                //get all datacenters of selected city
                ProcessDepartment(datacenter.Datacenter, datacenterid.DataCenterId, datacentervaluesonly,companyId);
            }

        }

        private void ProcessDepartment(string datacentername, int datacenterid, List<ImportCSVSettings> values, int companyId)
        {



            foreach (var department in values)
            {

                var selecteddepartment = (from c in _context.lkpDepartment
                                          where c.DataCenterId == datacenterid && c.DepartmentName.ToLower() == department.Department.ToLower()
                                          select c).FirstOrDefault();

                //insert departments
                if (selecteddepartment == null)
                {

                    lkpDepartment DepartmentValue = new lkpDepartment();

                    DepartmentValue.DataCenterId = datacenterid;
                    DepartmentValue.DepartmentName = department.Department;
                    DepartmentValue.CreatedAt = DateTime.Now;
                    DepartmentValue.ModifiedAt = DateTime.Now;
                    DepartmentValue.Active = true;
                    DepartmentValue.CompanyId = companyId;
                    _context.lkpDepartment.Add(DepartmentValue);

                }
            }

            _context.SaveChanges();

        }


        public List<ImportCSVSettings> ReadAsList(IFormFile file)
        {
            var result = new List<ImportCSVSettings>();
            int i = -1;
            using (var reader = new StreamReader(file.OpenReadStream()))
            {

                while (reader.Peek() >= 0)
                {

                    i = i + 1;
                    string line = reader.ReadLine();
                    if (!String.IsNullOrWhiteSpace(line))
                    {
                        string[] values = line.Split(',');

                        if (i > 0)
                        {
                            ImportCSVSettings csv = new ImportCSVSettings();
                            csv.Country = values[0];
                            csv.State = values[1];
                            csv.City = values[2];
                            csv.DataCenter = values[3];
                            csv.Department = values[4];
                            result.Add(csv);

                        }
                    }


                }


            }
            return result;
        }



    }

    public class ImportCSVSettings
    {
        public string Country { get; set; }
        public string State { get; set; }
        public string City { get; set; }
        public string DataCenter { get; set; }
        public string Department { get; set; }
    }

}
