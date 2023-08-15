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
// For more information on enabling MVC for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace SmartAdmin.Seed.Controllers.Settings
{
    public class Framework_ServerController : Controller
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
        private List<lkpDepartment> department;
        private readonly UserManager<ApplicationUser> _userManager;

        //  private List<Databases> databases;


        //  private List<Documents> documents;
        #endregion
        public IActionResult Index()
        {
            return View();
        }

        public Framework_ServerController(ApplicationDbContext context, UserManager<ApplicationUser> userManager)
        {
            _context = context;
            allStates = (from c in _context.lkpAllStates select c).ToList();
            countries = (from c in _context.lkpCountry select c).ToList();
            allcities = (from c in _context.lkpAllCities select c).ToList();
            city = (from c in _context.lkpCity select c).ToList();
            states = (from c in _context.lkpState select c).ToList();
            allcountries = (from c in _context.lkpAllCountries select c).ToList();
            datacenter = (from c in _context.lkpDataCenter select c).ToList();
            department = (from c in _context.lkpDepartment select c).ToList();
            _userManager = userManager;

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
                ErrorLogExtension.RecordErrorLogException(ex, "GetCountryName", "Framework_Server", userid, _context);

                return new JsonStringResult("unable to get Country");
            }
            }
        [HttpPost]
        public JsonStringResult GetStateName(int CountryId)
        {
            try {
                var result = (from s in _context.lkpState
                              where s.CountryId == CountryId
                              select s
                              ).ToList();


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetStateName", "Framework_Server", userid, _context);

                return new JsonStringResult("unable to get State Name");
            }
            }


        [HttpPost]
        public JsonStringResult GetCityName(int StateId)

        {
            try {
                var result = (from s in _context.lkpCity
                              where s.StateId == StateId
                              select s
                          ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch(Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetCityName", "Framework_Server", userid, _context);

                return new JsonStringResult("unable to get City Name");
            }
            }
        [HttpPost]
        public JsonStringResult GetDataCenterName(int CityId)

        {
            try {
                var result = (from s in _context.lkpDataCenter
                              where s.CityId == CityId
                              select s
                        ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            } catch(Exception ex) {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDataCenterName", "Framework_Server", userid, _context);

                return new JsonStringResult("unable to get Center Name");
            }

            
        }

        [HttpGet]
        public JsonStringResult frmserver_DatabaseID()
        {
            try
            {
                var result = from d in _context.Databases
                             select d;
                 
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_DatabaseID", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_SAN()
        {
            try
            {

                var result = _context.lkpSAN.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_SAN", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_SANSwitchName()
        {
            try
            {
                var result = _context.lkpSANSwitchName.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_SANSwitchName", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        
        [HttpGet]
        public JsonStringResult frmserver_SANSwitchPort()
        {
            try
            {
                var result = _context.lkpSANSwitchPort.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_SANSwitchPort", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        
        [HttpGet]
        public JsonStringResult frmserver_lkpFibreBackup()
        {
            try
            {

                var result = _context.lkpFibreBackup.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpFibreBackup", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_lkpFibreSwitchName()
        {
            try
            {
                var result = _context.lkpFibreSwitchName.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpFibreSwitchName", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }


        

        [HttpGet]
        public JsonStringResult frmserver_lkpFibreSwitchPort()
        {
            try
            {
                var result = _context.lkpFibreSwitchPort.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpFibreSwitchPort", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        
        [HttpGet]
        public JsonStringResult frmserver_lkpClusterType()
        {
            try
            {
                var result = _context.lkpClusterType.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch(Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpClusterType", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        [HttpGet]
        public JsonStringResult frmserver_lkpLocation()
        {
            try
            {
                var result = _context.lkpLocation.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch(Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpLocation", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_lkpITGroup()
        {
            try
            {
                var result = _context.lkpITGroup.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpITGroup", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }
        [HttpGet]
        public JsonStringResult frmserver_lkpNetworkType()
        {
            try
            {
                var result = _context.lkpNetworkType.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpITGroup", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_lkpServerType()
        {
            try
            {
                var result = _context.lkpServerType.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch(Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpServerType", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        [HttpGet]
        public JsonStringResult frmserver_lkpVHostName()
        {
            try
            {
                var result = _context.lkpVHost.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_lkpVHostName", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }


        [HttpGet]
        public JsonStringResult frmserver_Document()
        {
            try
            {
                var result = _context.Document.ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch(Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "frmserver_Document", "Framework_Server", userid, _context);

                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);
            }
        }

        //[HttpGet]
        //public JsonStringResult frmserver_getserver()
        //{
        //    try
        //    {
        //        var result = _context.completeserver.ToList();
        //        var json = JsonConvert.SerializeObject(result);
        //        return new JsonStringResult(json);
        //    }
        //    catch (Exception ex)
        //    {
        //        string message = "Fail.." + ex.Message;
        //        return new JsonStringResult(message);
        //    }
        //}

        [HttpGet]
        public JsonStringResult GetServer()
        {
            try {

                var result = (from x in _context.Server

                              select new
                              {
                                  x.ServerID,
                                  x.Name,
                                  x.OS,
                                  x.IPAddress,
                                  x.Generation


                              });



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetServer", "Framework_Server", userid, _context);
                return new JsonStringResult("Unable get to  get Server");
            }
        }
        [HttpPost]
        public JsonStringResult EditData(int ServerID)
        {
            try
            {
                var result = (from x in _context.Server
                              join aag in _context.serverdatabase on x.ServerID equals aag.ServerID
                              //  join ac in _context.ApplicationContact on ac.ApplicationID equals x.ApplicationID
                              join ad in _context.serverdocument on x.ServerID equals ad.ServerID

                              join fal in _context.framework_Server_Location on x.ServerID equals fal.ServerID

                              where x.ServerID == ServerID
                              select new
                              {
                                  fal.CountryId,
                                  fal.StateId,
                                  fal.CityId,
                                  fal.DataCenterId,
                                  fal.DepartmentId,
                                  ad.DocumentID,

                                  aag.ServerDatabaseID,
                                  x.ServerID,
                                  x.Name,
                                  x.AdminEngineerID,
                                  x.LocationID,
                                  x.IPAddress,
                                  x.OS,
                                  //x.ProcessorNumber,
                                  x.CPUSpeed,
                                  x.ServerMemory,
                                  x.VHostName,
                                  x.VirtualHostType,

                                  x.BackupDescription,
                                  x.WebServerTypeID,
                                  x.ServerTypeID,
                                  x.AntiVirusTypeID,
                                  x.RebootSchedule,
                                  //x.ControllerNumber,
                                  x.DiskCapacity,

                                  //x.NetworkTypeID,
                                  x.ITGroupID,
                                  x.GroupDescription,
                                  
                                  x.SerialNo,
                                  x.ILODNSName,
                                  x.ILOIPAddress,
                                  x.IPAddress2,
                                  x.IPAddress3,
                                  //x.IPAddress4,
                                  x.BackUpPath,
                                  x.ILOLicense,
                                  x.NIC1CableNo,
                                  x.NIC1BunbleNo,
                                 
                                  x.ServerUseID


                              }
                               ).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }

            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "EditData", "Framework_Server", userid, _context);
                return new JsonStringResult("Unable to save");
            }
        }
        [HttpPost]
        public JsonStringResult GetDepartmentName(int DataCenterId)

        {
            try
            {

                var result = (from s in _context.lkpDepartment
                              where s.DataCenterId == DataCenterId
                              select s
                              ).ToList();
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentName", "Framework_Server", userid, _context);
                return new JsonStringResult("Unable to get Department Name");
            }
        }
        //[HttpPost]
        //public JsonStringResult demo([FromBody]Server serv)
        //{
        //    try
        //    {

        //        var found = (from c in _context.Server where c.Name == serv.Name select c).FirstOrDefault();
        //        if (found==null)
        //        {
        //            Server selectedserver = new Server();
        //            selectedserver.ServerID = serv.ServerID;
        //            selectedserver.Name = serv.Name;
        //            selectedserver.LocationID = serv.LocationID;
        //            selectedserver.IPAddress = serv.IPAddress;
        //            selectedserver.AdminEngineerID = serv.AdminEngineerID;
        //            selectedserver.OS = serv.OS;
        //            selectedserver.ProcessorNumber = serv.OS;
        //            selectedserver.CPUSpeed = serv.CPUSpeed;
        //            selectedserver.ServerMemory = serv.ServerMemory;
        //            //selectedserver.Comment = serv.Comment;
        //            //selectedserver.VHostName = serv.VHostName;
        //            //selectedserver.VirtualHostType = serv.VirtualHostType;
        //            //selectedserver.BackupDescription = serv.BackupDescription;
        //            //selectedserver.WebServerTypeID = serv.WebServerTypeID;
        //            //selectedserver.ServerTypeID = serv.ServerTypeID;
        //            //selectedserver.AntiVirusTypeID = serv.AntiVirusTypeID;
        //            //selectedserver.RebootSchedule = serv.RebootSchedule;
        //            //selectedserver.ControllerNumber = serv.ControllerNumber;
        //            //selectedserver.DiskCapacity = serv.DiskCapacity;
        //            //selectedserver.GroupDescription = serv.GroupDescription;
        //            //selectedserver.CabinetNo = serv.CabinetNo;
        //            //selectedserver.ChasisNo = serv.ChasisNo;
        //            //selectedserver.ModelNo = serv.ModelNo;
        //            //selectedserver.BladeNo = serv.BladeNo;
        //            //selectedserver.Generation = serv.Generation;
        //            //selectedserver.SerialNo = serv.SerialNo;
                    //selectedserver.ILODNSName = serv.ILODNSName;
                    //selectedserver.ILOIPAddress = serv.ILOIPAddress;
                    //selectedserver.IPAddress2 = serv.IPAddress2;
                    //selectedserver.IPAddress3 = serv.IPAddress3;
        //            //selectedserver.BackUpPath = serv.BackUpPath;
        //            //selectedserver.ILOLicense = serv.ILOLicense;
        //            //selectedserver.LastUpdatedBy = serv.LastUpdatedBy;
        //            //selectedserver.LastUpdated = DateTime.Now;
        //            //selectedserver.NIC1CableNo = serv.NIC1CableNo;
        //            //selectedserver.NIC1BunbleNo = serv.NIC1BunbleNo;
        //            //selectedserver.IPAddress4 = serv.IPAddress4;
        //            //selectedserver.SAN = serv.SAN;
        //            //selectedserver.SANSwitchName = serv.SANSwitchName;
        //            //selectedserver.SANSwitchPort = serv.SANSwitchPort;
        //            //selectedserver.FibreBackup = serv.FibreBackup;
        //            //selectedserver.FibreSwitchName = serv.FibreSwitchName;
        //            //selectedserver.FibreSwitchPort = serv.FibreSwitchPort;
        //            //selectedserver.ClusterType = serv.ClusterType;
        //            //selectedserver.ClusterName = serv.ClusterName;
        //            //selectedserver.ClusterIP1 = serv.ClusterIP1;
        //            //selectedserver.ManufacturerNumber = serv.ManufacturerNumber;
        //            //selectedserver.Manufacturer = serv.Manufacturer;
        //            //selectedserver.WarrantyExpiration = serv.WarrantyExpiration;
        //            //selectedserver.NIC1Bundle = serv.NIC1Bundle;
        //            //selectedserver.NIC2Bundle = serv.NIC2Bundle;
        //            //selectedserver.NIC3Bundle = serv.NIC3Bundle;
        //            //selectedserver.NIC4Bundle = serv.NIC4Bundle;
        //            //selectedserver.NIC1Cable = serv.NIC1Cable;


        //        }

        //        string message = "SUCCESS";
        //        return new JsonStringResult(message);
        //    }
        //    catch (Exception ex)
        //    {
        //        string message = "Fail.." + ex.Message;
        //        return new JsonStringResult(message);

        //    }
        //}

        [HttpPost]
        public JsonStringResult SaveFramework_Server([FromBody] completeserver serv)
              {
            try
            {
                
                var found = (from c in _context.Server where c.Name == serv.server.Name select c).FirstOrDefault();
                if (found==null)
                {
                    Server selectedserver = new Server();
                    serverdatabase selecteddatabases = new serverdatabase();
                    serverdocument selecteddocument = new serverdocument();
                    Framework_Server_Location framework_Server_Location = new Framework_Server_Location();

                    selectedserver.Name = serv.server.Name;
                    selectedserver.LocationID = serv.server.LocationID;
                    selectedserver.IPAddress = serv.server.IPAddress;
                    selectedserver.AdminEngineerID = serv.server.AdminEngineerID;
                    selectedserver.OS = serv.server.OS;
                   selectedserver.ProcessorNumber = serv.server.ProcessorNumber;
                    selectedserver.CPUSpeed = serv.server.CPUSpeed;
                    selectedserver.LastUpdated = DateTime.Now;
                    selectedserver.ServerMemory = serv.server.ServerMemory;
                    selectedserver.WarrantyExpiration = DateTime.Now;
                    selectedserver.Comment = serv.server.Comment;
                    selectedserver.VHostName = serv.server.VHostName;
                    selectedserver.VirtualHostType = serv.server.VirtualHostType;
                    selectedserver.BackupDescription = serv.server.BackupDescription;
                    selectedserver.WebServerTypeID = serv.server.WebServerTypeID;
                    selectedserver.ServerTypeID = serv.server.ServerTypeID;
                    selectedserver.AntiVirusTypeID = serv.server.AntiVirusTypeID;
                    selectedserver.RebootSchedule = serv.server.RebootSchedule;
                    selectedserver.ControllerNumber = serv.server.ControllerNumber;
                    selectedserver.DiskCapacity = serv.server.DiskCapacity;
                    selectedserver.NetworkTypeID = serv.server.NetworkTypeID;
                    selectedserver.ITGroupID = serv.server.ITGroupID;
                    selectedserver.GroupDescription = serv.server.GroupDescription;
                    selectedserver.CabinetNo = serv.server.CabinetNo;
                    selectedserver.ChasisNo = serv.server.ChasisNo;
                    selectedserver.ModelNo = serv.server.ModelNo;
                    selectedserver.BladeNo = serv.server.BladeNo;
                    selectedserver.Generation = serv.server.Generation;
                    selectedserver.SerialNo = serv.server.SerialNo;
                    selectedserver.ILODNSName = serv.server.ILODNSName;
                    selectedserver.ILOIPAddress = serv.server.ILOIPAddress;
                    selectedserver.IPAddress2 = serv.server.IPAddress2;
                    selectedserver.IPAddress3 = serv.server.IPAddress3;
                    selectedserver.BackUpPath = serv.server.BackUpPath;
                    selectedserver.ILOLicense = serv.server.ILOLicense;
                    selectedserver.LastUpdatedBy = serv.server.LastUpdatedBy;
                    selectedserver.NIC1CableNo = serv.server.NIC1CableNo;
                    selectedserver.NIC1BunbleNo = serv.server.NIC1BunbleNo;
                    selectedserver.IPAddress4 = serv.server.IPAddress4;
                    selectedserver.SAN = serv.server.SAN;
                    selectedserver.SANSwitchName = serv.server.SANSwitchName;
                    selectedserver.SANSwitchPort = serv.server.SANSwitchPort;
                    selectedserver.FibreBackup = serv.server.FibreBackup;
                    selectedserver.FibreSwitchName = serv.server.FibreSwitchName;
                    selectedserver.FibreSwitchPort = serv.server.FibreSwitchPort;
                    selectedserver.ClusterType = serv.server.ClusterType;
                    selectedserver.ClusterName = serv.server.ClusterName;
                    selectedserver.ClusterIP1 = serv.server.ClusterIP1;
                    selectedserver.ManufacturerNumber = serv.server.ManufacturerNumber;
                    selectedserver.Manufacturer = serv.server.Manufacturer;
                    selectedserver.NIC1Bundle = serv.server.NIC1Bundle;
                    selectedserver.NIC2Bundle = serv.server.NIC2Bundle;
                    selectedserver.NIC3Bundle = serv.server.NIC3Bundle;
                    selectedserver.NIC4Bundle = serv.server.NIC4Bundle;
                    selectedserver.NIC1Cable = serv.server.NIC1Cable;
                    selectedserver.NIC2Cable = serv.server.NIC2Cable;
                    selectedserver.NIC3Cable = serv.server.NIC3Cable;
                    selectedserver.NIC4Cable = serv.server.NIC4Cable;
                    selectedserver.ClusterSAN = serv.server.ClusterSAN;
                    selectedserver.LUNNumber = serv.server.LUNNumber;
                    selectedserver.SMTP = serv.server.SMTP;
                    selectedserver.Description = serv.server.Description;
                    selectedserver.Location = serv.server.Location;
                    selectedserver.Network = serv.server.Network;
                    
                    selectedserver.NIC1Interface = serv.server.NIC1Interface;
                    selectedserver.NIC2Interface = serv.server.NIC2Interface;
                    selectedserver.NIC3Interface = serv.server.NIC3Interface;
                    selectedserver.NIC4Interface = serv.server.NIC4Interface;
                    selectedserver.NIC1Subnet = serv.server.NIC1Subnet;
                    selectedserver.NIC2Subnet = serv.server.NIC2Subnet;
                    selectedserver.NIC3Subnet = serv.server.NIC3Subnet;
                    selectedserver.NIC4Subnet = serv.server.NIC4Subnet;
                    selectedserver.NIC1SwitchPortNum = serv.server.NIC1SwitchPortNum;
                    selectedserver.NIC2SwitchPortNum = serv.server.NIC2SwitchPortNum;
                    selectedserver.NIC3SwitchPortNum = serv.server.NIC3SwitchPortNum;
                    selectedserver.NIC4SwitchPortNum = serv.server.NIC4SwitchPortNum;
                    selectedserver.NIC1VLAN = serv.server.NIC1VLAN;
                    selectedserver.NIC2VLAN = serv.server.NIC2VLAN;
                    selectedserver.NIC3VLAN = serv.server.NIC3VLAN;
                    selectedserver.NIC4VLAN = serv.server.NIC4VLAN;
                    selectedserver.NIC1SwitchName = serv.server.NIC1SwitchName;
                    selectedserver.NIC2SwitchName = serv.server.NIC2SwitchName;
                    selectedserver.NIC3SwitchName = serv.server.NIC3SwitchName;
                    selectedserver.NIC4SwitchName = serv.server.NIC4SwitchName;
                    selectedserver.CPUType = serv.server.CPUType;
                    selectedserver.DNSServer1 = serv.server.DNSServer1;
                    selectedserver.DNSServer2 = serv.server.DNSServer2;
                    selectedserver.PhysicalDiskSize = serv.server.PhysicalDiskSize;
                    selectedserver.RaidType = serv.server.RaidType;
                    selectedserver.PhysicalDisks = serv.server.PhysicalDisks;
                    selectedserver.Ownership = serv.server.Ownership;
                    selectedserver.ServerUseID = serv.server.ServerUseID;

                    
                    _context.Add(selectedserver);
                    _context.SaveChanges();

                    //----------------------Databases--------------->
                    selecteddatabases.DatabaseID = serv.databases.DatabaseID;
                    selecteddatabases.ServerID = selectedserver.ServerID;
                     _context.Add(selecteddatabases);
                    //----------------------EndDatabases------------->

                    //------------------------Documents-------------------->

                    selecteddocument.DocumentID = serv.document.DocumentID;
                    selecteddocument.ServerID = selectedserver.ServerID;
                    _context.Add(selecteddocument);

                    //-----------------------end documents-------------------->

                    //------------------------Save Country City Dataceneter etc --------------------->
                    framework_Server_Location.CountryId = serv.lkpCountry.CountryId;
                    framework_Server_Location.StateId = serv.lkpState.StateId;
                    framework_Server_Location.CityId = serv.lkpCity.CityId;
                    framework_Server_Location.DataCenterId = serv.lkpDataCenter.DataCenterId;
                    framework_Server_Location.DepartmentId = serv.lkpDepartment.DepartmentId;
                     framework_Server_Location.ServerID = selectedserver.ServerID;
                    _context.Add(framework_Server_Location);
                    //---------------------------end region---------------------------->
                    _context.SaveChanges();

                }
                else
                {
                    var foundserverdatabase = (from c in _context.serverdatabase where c.ServerID == serv.server.ServerID select c).FirstOrDefault();
                    var foundserverdoc = (from c in _context.serverdocument where c.ServerID == serv.server.ServerID select c).FirstOrDefault();
                    found.Name = serv.server.Name;
                    found.OS = serv.server.OS;
                    found.IPAddress = serv.server.IPAddress;
                    found.Generation = serv.server.Generation;
                    foundserverdatabase.ServerDatabaseID = serv.databases.ServerDatabaseID;
                    foundserverdoc.ServerID = serv.document.ServerID;
                    

                }
                string message = "SUCCESS";
                return new JsonStringResult(message);
            }
            catch (Exception ex)
            {
                var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                ErrorLogExtension.RecordErrorLogException(ex, "SaveFramework_Server", "Framework_Server", userid, _context);
                
                string message = "Fail.." + ex.Message;
                return new JsonStringResult(message);

            }
        }


        private int ParseInt(string value)
        {
            int number = 0;
            if (int.TryParse(value, out number))
                return number;
            else
                return 0;
        }

    }
}
