using System;
using System.Web;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Hosting;
using Newtonsoft.Json;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models;
using static SmartAdmin.Seed.Controllers.ConfirmationController;
using static SmartAdmin.Seed.Controllers.TestController;
using SmartAdmin.Seed.Models.Entities;
using Microsoft.AspNetCore.Authorization;
using SmartAdmin.Seed.Services;
using DinkToPdf;
using SmartAdmin.Seed.RecExtensions;
using Microsoft.EntityFrameworkCore;

namespace SmartAdmin.Seed.Controllers
{
    [Authorize]
    public class GraphController : Controller
    {





        #region Declaration

        private readonly ApplicationDbContext _context;
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IWebHostEnvironment _env;
        IEmailSender _emailSender;
        private IList<string> roles;
        int companyid = 0;
        public AppSettingsOptions Options { get; } //set only via Secret Manager

        #endregion
        public GraphController(UserManager<ApplicationUser> userManager, ApplicationDbContext context, IWebHostEnvironment env, IEmailSender emailSender, Microsoft.Extensions.Options.IOptions<AppSettingsOptions> optionsAccessor)
        {
            _userManager = userManager;
            _env = env;
            //_signInManager = signInManager;
            _emailSender = emailSender;
            //_logger = logger;
            Options = optionsAccessor.Value;
            _context = context;

        }
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Settings()
        {
            return View();
        }

        public IActionResult Designer()
        {
            return View();
        }

        public IActionResult ShareDiagram(string fileName)
        {
            FileInformation fileinfo = new FileInformation();
            fileinfo.FileName = fileName;

            //var json = JsonConvert.SerializeObject(fileinfo);

            return View(fileinfo);
        }


        public IActionResult DiagramShapes()
        {


            return View();
        }




        [HttpPost]
        public async Task<IActionResult> Upload(IFormFile file)
        {
            var uploads = Path.Combine(_env.WebRootPath, "graph\\stencils\\usman");
            if (file.Length > 0)
            {
                using (var fileStream = new FileStream(Path.Combine(uploads, file.FileName), FileMode.Create))
                {
                    await file.CopyToAsync(fileStream);
                }
            }
            return RedirectToAction("Settings");
        }

        public GraphController(UserManager<ApplicationUser> userManager, ApplicationDbContext context)
        {


            _userManager = userManager;
            _context = context;




        }

        private async Task<int> GetCompanyId()
        {
            var user = await _userManager.GetUserAsync(HttpContext.User);
            roles = await _userManager.GetRolesAsync(user);
            companyid = user.CompanyId;

            return 0;
        }


        [HttpPost]
        public JsonStringResult GetUploadedIcons()
        {

            var directorypath = Path.Combine(_env.WebRootPath, "graph\\stencils\\usman");

            DirectoryInfo d = new DirectoryInfo(directorypath);
            FileInfo[] Files = d.GetFiles();
            List<FileInformation> lst = new List<FileInformation>();
            foreach (FileInfo file in Files)
            {
                lst.Add(new FileInformation { FileName = file.Name, FileSize = file.Length });
            }

            var json = JsonConvert.SerializeObject(lst);
            return new JsonStringResult(json);
        }





        [HttpPost]
        public JsonStringResult RemoveUploadedIcons(string name)
        {

            var directorypath = Path.Combine(_env.WebRootPath, "graph\\stencils\\usman");

            DirectoryInfo d = new DirectoryInfo(directorypath);
            FileInfo[] Files = d.GetFiles();

            try
            {
                foreach (FileInfo file in Files)
                {
                    if (file.Name == name)
                    {
                        System.IO.File.Delete(file.FullName);
                        break;
                    }
                }

                var json = JsonConvert.SerializeObject("success");
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {

                var json = JsonConvert.SerializeObject(ex.Message);
                return new JsonStringResult(json);
            }







        }


        [HttpPost]
        public JsonStringResult GetAllIconFiles()
        {

            var directorypath = Path.Combine(_env.WebRootPath, "graph\\stencils\\usman");

            DirectoryInfo d = new DirectoryInfo(directorypath);
            FileInfo[] Files = d.GetFiles();
            List<FileInformation> lst = new List<FileInformation>();
            foreach (FileInfo file in Files)
            {

                lst.Add(new FileInformation { FileName = file.Name, FileSize = file.Length });

            }

            var json = JsonConvert.SerializeObject(lst);
            return new JsonStringResult(json);
        }



        [HttpPost]
        public async Task<JsonStringResult> GetDiagramXML(int FileId)
        {

            try
            {

                var user = await _userManager.GetUserAsync(HttpContext.User);

                var DiagramId = from d in _context.ApplicationDiagram
                                where d.DiagramId == FileId
                                select d;
                FileInformation info = new FileInformation();
                if (DiagramId != null)
                {

                    if (DiagramId.Count() > 0)
                    {

                        info.FileName = DiagramId.FirstOrDefault().DiagramXML;



                    }
                    else
                    {

                    }
                }


                var json = JsonConvert.SerializeObject(info);
                return new JsonStringResult(json);


            }
            catch (Exception)
            {
                FileInformation info = new FileInformation();
                info.FileName = "";
                var json = JsonConvert.SerializeObject(info);
                return new JsonStringResult(json);
            }
        }




        [HttpPost]
        public async Task<JsonStringResult> GetDesignerDiagramXML(int FileId)
        {

            try
            {

                var user = await _userManager.GetUserAsync(HttpContext.User);

                var DiagramId = from d in _context.tblApplicationDesignerDiagram
                                where d.DiagramId == FileId
                                select d;
                FileInformation info = new FileInformation();
                if (DiagramId != null)
                {

                    if (DiagramId.Count() > 0)
                    {

                        info.FileName = DiagramId.FirstOrDefault().FileName;
                        info.XMLData = DiagramId.FirstOrDefault().DiagramXML;



                    }
                    else
                    {

                    }
                }


                var json = JsonConvert.SerializeObject(info);
                return new JsonStringResult(json);


            }
            catch (Exception)
            {
                FileInformation info = new FileInformation();
                info.FileName = "";
                var json = JsonConvert.SerializeObject(info);
                return new JsonStringResult(json);
            }
        }
        [HttpPost]
        [Obsolete]
        public async Task<JsonStringResult> GetDesignerTree(int compid)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            if (rolename == "admin")
            {

                try
                {
                    var result = (from tree in _context.tblDesignerTree
                                  where tree.CompanyId == compid

                                  select new DesignerTree
                                  {
                                      id = tree.id.ToString(),
                                      text = tree.text,
                                      parent = tree.parent,
                                      folderLevel = tree.FolderLevel,
                                      type = tree.parent


                                  }).ToList();





                    if (result.Count() == 0)
                    {


                        var AppDiagram = new tblDesignerTree();
                        AppDiagram.parent = "#";

                        AppDiagram.parentint = 0;
                        AppDiagram.text = "Documents";
                        AppDiagram.CompanyId = compid;
                        AppDiagram.FolderLevel = 0;
                        AppDiagram.Active = true;
                        AppDiagram.CreatedBy = user.Id;
                        AppDiagram.CreatedAt = DateTime.Now;

                        AppDiagram.ModifiedBy = user.Id;
                        AppDiagram.ModifiedAt = DateTime.Now;

                        _context.tblDesignerTree.Add(AppDiagram);
                        var dig = await _context.SaveChangesAsync();

                        List<DesignerTree> lstTree = new List<DesignerTree>();

                        DesignerTree res = new DesignerTree();


                        res.id = AppDiagram.id.ToString();
                        res.text = "Documents";
                        res.parent = "#";
                        res.folderLevel = 0;

                        lstTree.Add(res);

                        var json = JsonConvert.SerializeObject(lstTree);
                        return new JsonStringResult(json);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }


                }
                catch (Exception ex)
                {
                    var g = ex;
                    throw;
                }

            }
            else
            {
                var result = (from tree in _context.tblDesignerTree
                              where tree.CreatedBy == user.Id && tree.CompanyId == compid
                              select new DesignerTree
                              {
                                  id = tree.id.ToString(),
                                  text = tree.text,
                                  parent = tree.parent,
                                  folderLevel = tree.FolderLevel,
                                  type = tree.parent

                              }).ToList();


                if (result.Count() == 0)
                {


                    var AppDiagram = new tblDesignerTree();
                    AppDiagram.parent = "#";

                    AppDiagram.parentint = 0;
                    AppDiagram.text = "Documents";
                    AppDiagram.CompanyId = compid;
                    AppDiagram.FolderLevel = 0;
                    AppDiagram.Active = true;
                    AppDiagram.CreatedBy = user.Id;
                    AppDiagram.CreatedAt = DateTime.Now;

                    AppDiagram.ModifiedBy = user.Id;
                    AppDiagram.ModifiedAt = DateTime.Now;

                    _context.tblDesignerTree.Add(AppDiagram);
                    var dig = await _context.SaveChangesAsync();



                    DesignerTree res = new DesignerTree();


                    res.id = AppDiagram.id.ToString();
                    res.text = "Documents";
                    res.parent = "#";
                    res.folderLevel = 0;

                    result.Add(res);



                }


                DesignerTree des = new DesignerTree();
                des.id = "-999";
                des.text = "Shared";
                des.parent = (from rid in _context.tblDesignerTree where rid.CompanyId == compid && rid.CreatedBy == user.Id select rid.id.ToString()).FirstOrDefault();
                des.folderLevel = 1;
                des.type = "share";

                result.Add(des);


                DesignerTree desTemplates = new DesignerTree();
                desTemplates.id = "-111";
                desTemplates.text = "Community";
                desTemplates.parent = (from rid in _context.tblDesignerTree where rid.CompanyId == compid && rid.CreatedBy == user.Id select rid.id.ToString()).FirstOrDefault();
                desTemplates.folderLevel = 1;
                desTemplates.type = "template";

                result.Add(desTemplates);


                string cteQuery = @"
WITH cte (id, parent, text,folderLevel,type,topmost) AS (
    SELECT cast(m.id as varchar(50)) as id, m.parent, m.[text],m.FolderLevel as folderLevel,m.parent as type,1 as topmost
        
    FROM tblDesignerTree m,tblSharedFolderWithUser d
    WHERE m.id= d.SharedFolderId
	and d.SharedWithUserEmail= '" + user.Email + "' and m.CompanyId=" + compid + " ";

                cteQuery = cteQuery + @"
    UNION ALL 
    SELECT cast(c.id as varchar(50)) as id, c.parent, c.[text],c.FolderLevel as folderLevel,c.parent as type,0 as topmost
         
    FROM  tblDesignerTree c
	INNER JOIN cte ON cte.id = c.parentint 
   
    
) 
SELECT *
FROM cte
";

                var d = _context.Database.ExecuteSqlRaw(cteQuery);
                List<DesignerTree> lstTree = new List<DesignerTree>();

                using (var dr = await _context.Database.ExecuteSqlQueryAsync(cteQuery))
                {
                    // Output rows.
                    var reader = dr.DbDataReader;

                    lstTree = RDFacadeExtensions.DataReaderMapToList<DesignerTree>(reader);

                    for (int i = 0; i < lstTree.Count; i++)
                    {


                        if (lstTree[i].topmost == 1)
                        {
                            lstTree[i].parent = "-999";
                        }
                    }

                    result.AddRange(lstTree);


                }





                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }





        }


        [HttpPost]
        [Obsolete]
        public async Task<JsonStringResult> GetDesignerTreeForCopyFile(int compid)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            if (rolename == "admin")
            {

                try
                {
                    var result = (from tree in _context.tblDesignerTree
                                  where tree.CompanyId == compid

                                  select new DesignerTree
                                  {
                                      id = tree.id.ToString(),
                                      text = tree.text,
                                      parent = tree.parent,
                                      folderLevel = tree.FolderLevel,
                                      type = tree.parent


                                  }).ToList();





                    if (result.Count() == 0)
                    {


                        var AppDiagram = new tblDesignerTree();
                        AppDiagram.parent = "#";

                        AppDiagram.parentint = 0;
                        AppDiagram.text = "Documents";
                        AppDiagram.CompanyId = compid;
                        AppDiagram.FolderLevel = 0;
                        AppDiagram.Active = true;
                        AppDiagram.CreatedBy = user.Id;
                        AppDiagram.CreatedAt = DateTime.Now;

                        AppDiagram.ModifiedBy = user.Id;
                        AppDiagram.ModifiedAt = DateTime.Now;

                        _context.tblDesignerTree.Add(AppDiagram);
                        var dig = await _context.SaveChangesAsync();

                        List<DesignerTree> lstTree = new List<DesignerTree>();

                        DesignerTree res = new DesignerTree();


                        res.id = AppDiagram.id.ToString();
                        res.text = "Documents";
                        res.parent = "#";
                        res.folderLevel = 0;

                        lstTree.Add(res);

                        var json = JsonConvert.SerializeObject(lstTree);
                        return new JsonStringResult(json);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }


                }
                catch (Exception ex)
                {
                    var g = ex;
                    throw;
                }

            }
            else
            {
                var result = (from tree in _context.tblDesignerTree
                              where tree.CreatedBy == user.Id && tree.CompanyId == compid && tree.Active == true
                              select new DesignerTree
                              {
                                  id = tree.id.ToString(),
                                  text = tree.text,
                                  parent = tree.parent,
                                  folderLevel = tree.FolderLevel,
                                  type = tree.parent

                              }).ToList();


                if (result.Count() == 0)
                {


                    var AppDiagram = new tblDesignerTree();
                    AppDiagram.parent = "#";

                    AppDiagram.parentint = 0;
                    AppDiagram.text = "Documents";
                    AppDiagram.CompanyId = compid;
                    AppDiagram.FolderLevel = 0;
                    AppDiagram.Active = true;
                    AppDiagram.CreatedBy = user.Id;
                    AppDiagram.CreatedAt = DateTime.Now;

                    AppDiagram.ModifiedBy = user.Id;
                    AppDiagram.ModifiedAt = DateTime.Now;

                    _context.tblDesignerTree.Add(AppDiagram);
                    var dig = await _context.SaveChangesAsync();



                    DesignerTree res = new DesignerTree();


                    res.id = AppDiagram.id.ToString();
                    res.text = "Documents";
                    res.parent = "#";
                    res.folderLevel = 0;

                    result.Add(res);



                }





                string cteQuery = @"
WITH cte (id, parent, text,folderLevel,type,topmost) AS (
    SELECT cast(m.id as varchar(50)) as id, m.parent, m.[text],m.FolderLevel as folderLevel,m.parent as type,1 as topmost
        
    FROM tblDesignerTree m,tblSharedFolderWithUser d
    WHERE m.id= d.SharedFolderId
	and d.SharedWithUserEmail= '" + user.Email + "' and m.CompanyId=" + compid + " ";

                cteQuery = cteQuery + @"
    UNION ALL 
    SELECT cast(c.id as varchar(50)) as id, c.parent, c.[text],c.FolderLevel as folderLevel,c.parent as type,0 as topmost
         
    FROM  tblDesignerTree c
	INNER JOIN cte ON cte.id = c.parentint 
   
    
) 
SELECT *
FROM cte
";

                var d = _context.Database.ExecuteSqlRaw(cteQuery);
                List<DesignerTree> lstTree = new List<DesignerTree>();

                using (var dr = await _context.Database.ExecuteSqlQueryAsync(cteQuery))
                {
                    // Output rows.
                    var reader = dr.DbDataReader;

                    lstTree = RDFacadeExtensions.DataReaderMapToList<DesignerTree>(reader);

                    for (int i = 0; i < lstTree.Count; i++)
                    {


                        if (lstTree[i].topmost == 1)
                        {
                            lstTree[i].parent = "-999";
                        }
                    }

                    result.AddRange(lstTree);


                }


                DesignerTree resTemplate = new DesignerTree();


                resTemplate.id = "-111";
                resTemplate.text = "Community";
                resTemplate.parent = "#";
                resTemplate.folderLevel = 1;

                result.Add(resTemplate);


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }





        }

        public async Task<JsonStringResult> CopyFileToNewFolder(int compid, int FolderId, int FileId)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            //if (rolename == "admin")
            //{
            //}
            //else
            //{
            var rec = _context.tblApplicationDesignerDiagram.Where(x => x.DiagramId == FileId);
            if (rec != null)
            {
                if (rec.Count() > 0)
                {
                    var rcd = rec.FirstOrDefault();
                    var AppDiagram = new tblApplicationDesignerDiagram();
                    if (FolderId.ToString() == "-111")
                    {
                        var id = (from rid in _context.tblDesignerTree where rid.CompanyId == compid && rid.CreatedBy == user.Id select rid.id.ToString()).FirstOrDefault();
                        AppDiagram.DesignerTreeId = int.Parse(id);
                        AppDiagram.IsTemplate = true;
                    }
                    else
                    {
                        AppDiagram.DesignerTreeId = FolderId;
                        AppDiagram.IsTemplate = false;
                    }
                    AppDiagram.FileName = rcd.FileName;
                    AppDiagram.CompanyId = compid;
                    AppDiagram.DiagramXML = rcd.DiagramXML;
                    AppDiagram.OwnerId = Guid.Parse(user.Id);
                  
                    _context.tblApplicationDesignerDiagram.Add(AppDiagram);
                    var dig = await _context.SaveChangesAsync();

                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                    return new JsonStringResult(json);
                }
            }

            //}

            var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "error" });
            return new JsonStringResult(jsonRes);


        }



        [HttpPost]
        [Obsolete]
        public async Task<JsonStringResult> GetDesignerTreeForMoveFile(int compid)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            if (rolename == "admin")
            {

                try
                {
                    var result = (from tree in _context.tblDesignerTree
                                  where tree.CompanyId == compid

                                  select new DesignerTree
                                  {
                                      id = tree.id.ToString(),
                                      text = tree.text,
                                      parent = tree.parent,
                                      folderLevel = tree.FolderLevel,
                                      type = tree.parent


                                  }).ToList();





                    if (result.Count() == 0)
                    {


                        var AppDiagram = new tblDesignerTree();
                        AppDiagram.parent = "#";

                        AppDiagram.parentint = 0;
                        AppDiagram.text = "Documents";
                        AppDiagram.CompanyId = compid;
                        AppDiagram.FolderLevel = 0;
                        AppDiagram.Active = true;
                        AppDiagram.CreatedBy = user.Id;
                        AppDiagram.CreatedAt = DateTime.Now;

                        AppDiagram.ModifiedBy = user.Id;
                        AppDiagram.ModifiedAt = DateTime.Now;

                        _context.tblDesignerTree.Add(AppDiagram);
                        var dig = await _context.SaveChangesAsync();

                        List<DesignerTree> lstTree = new List<DesignerTree>();

                        DesignerTree res = new DesignerTree();


                        res.id = AppDiagram.id.ToString();
                        res.text = "Documents";
                        res.parent = "#";
                        res.folderLevel = 0;

                        lstTree.Add(res);

                        var json = JsonConvert.SerializeObject(lstTree);
                        return new JsonStringResult(json);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }


                }
                catch (Exception ex)
                {
                    var g = ex;
                    throw;
                }

            }
            else
            {
                var result = (from tree in _context.tblDesignerTree
                              where tree.CreatedBy == user.Id && tree.CompanyId == compid && tree.Active == true
                              select new DesignerTree
                              {
                                  id = tree.id.ToString(),
                                  text = tree.text,
                                  parent = tree.parent,
                                  folderLevel = tree.FolderLevel,
                                  type = tree.parent

                              }).ToList();


                if (result.Count() == 0)
                {


                    var AppDiagram = new tblDesignerTree();
                    AppDiagram.parent = "#";

                    AppDiagram.parentint = 0;
                    AppDiagram.text = "Documents";
                    AppDiagram.CompanyId = compid;
                    AppDiagram.FolderLevel = 0;
                    AppDiagram.Active = true;
                    AppDiagram.CreatedBy = user.Id;
                    AppDiagram.CreatedAt = DateTime.Now;

                    AppDiagram.ModifiedBy = user.Id;
                    AppDiagram.ModifiedAt = DateTime.Now;

                    _context.tblDesignerTree.Add(AppDiagram);
                    var dig = await _context.SaveChangesAsync();



                    DesignerTree res = new DesignerTree();


                    res.id = AppDiagram.id.ToString();
                    res.text = "Documents";
                    res.parent = "#";
                    res.folderLevel = 0;

                    result.Add(res);



                }





                string cteQuery = @"
WITH cte (id, parent, text,folderLevel,type,topmost) AS (
    SELECT cast(m.id as varchar(50)) as id, m.parent, m.[text],m.FolderLevel as folderLevel,m.parent as type,1 as topmost
        
    FROM tblDesignerTree m,tblSharedFolderWithUser d
    WHERE m.id= d.SharedFolderId
	and d.SharedWithUserEmail= '" + user.Email + "' and m.CompanyId=" + compid + " ";

                cteQuery = cteQuery + @"
    UNION ALL 
    SELECT cast(c.id as varchar(50)) as id, c.parent, c.[text],c.FolderLevel as folderLevel,c.parent as type,0 as topmost
         
    FROM  tblDesignerTree c
	INNER JOIN cte ON cte.id = c.parentint 
   
    
) 
SELECT *
FROM cte
";

                var d = _context.Database.ExecuteSqlRaw(cteQuery);
                List<DesignerTree> lstTree = new List<DesignerTree>();

                using (var dr = await _context.Database.ExecuteSqlQueryAsync(cteQuery))
                {
                    // Output rows.
                    var reader = dr.DbDataReader;

                    lstTree = RDFacadeExtensions.DataReaderMapToList<DesignerTree>(reader);

                    for (int i = 0; i < lstTree.Count; i++)
                    {


                        if (lstTree[i].topmost == 1)
                        {
                            lstTree[i].parent = "-999";
                        }
                    }

                    result.AddRange(lstTree);


                }





                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }





        }

        public async Task<JsonStringResult> MoveFileToNewFolder(int compid, int FolderId, int FileId)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            //if (rolename == "admin")
            //{
            //}
            //else
            //{
            var rec = _context.tblApplicationDesignerDiagram.Where(x => x.DiagramId == FileId);
            if (rec != null)
            {
                if (rec.Count() > 0)
                {
                    rec.FirstOrDefault().DesignerTreeId = FolderId;
                    await _context.SaveChangesAsync();

                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                    return new JsonStringResult(json);
                }
            }

            //}

            var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "error" });
            return new JsonStringResult(jsonRes);


        }




        [HttpPost]
        public async Task<JsonStringResult> GetDesignerApplicationTree(int compid, int selectedFolder, bool isSharedWithmeSelected)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";
            if (selectedFolder == -111)
            {
                try
                {
                    var result = (from tree in _context.tblApplicationDesignerDiagram

                                  where tree.CompanyId == compid && tree.IsTemplate == true

                                  select new DesignerTree
                                  {
                                      id = tree.DiagramId.ToString(),
                                      text = tree.FileName,
                                      parent = "-111",
                                      folderLevel = 2


                                  }).ToList();




                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }
                catch (Exception ex)
                {
                    var g = ex;
                    throw;
                }

            }
            else
            {
                if (rolename == "admin")
                {

                    try
                    {
                        var result = (from tree in _context.tblApplicationDesignerDiagram
                                      join design in _context.tblDesignerTree on tree.DesignerTreeId equals design.id
                                      where tree.CompanyId == compid && design.id == selectedFolder && tree.IsTemplate == false

                                      select new DesignerTree
                                      {
                                          id = tree.DiagramId.ToString(),
                                          text = tree.FileName,
                                          parent = tree.DesignerTreeId.ToString(),
                                          folderLevel = design.FolderLevel


                                      }).ToList();




                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }
                    catch (Exception ex)
                    {
                        var g = ex;
                        throw;
                    }

                }
                else
                {

                    if (isSharedWithmeSelected == false)
                    {
                        var result = (from tree in _context.tblApplicationDesignerDiagram
                                      join design in _context.tblDesignerTree on tree.DesignerTreeId equals design.id
                                      where tree.CompanyId == compid && tree.OwnerId.ToString() == user.Id && design.id == selectedFolder && tree.IsTemplate == false

                                      select new DesignerTree
                                      {
                                          id = tree.DiagramId.ToString(),
                                          text = tree.FileName,
                                          parent = tree.DesignerTreeId.ToString(),
                                          folderLevel = design.FolderLevel


                                      }).ToList();




                        var json = JsonConvert.SerializeObject(result);
                        return new JsonStringResult(json);
                    }
                    else
                    {

                        //try
                        {
                            var result = (from tree in _context.tblApplicationDesignerDiagram
                                          join sharedapp in _context.tblSharedApplicationWithUser on tree.DiagramId equals sharedapp.SharedApplicationId
                                          where tree.CompanyId == compid && sharedapp.SharedWithUserEmail == user.Email && tree.IsTemplate == false


                                          select new DesignerTree
                                          {
                                              id = tree.DiagramId.ToString(),
                                              text = tree.FileName,
                                              parent = "-999",
                                              folderLevel = 2


                                          }).ToList();




                            var json = JsonConvert.SerializeObject(result);
                            return new JsonStringResult(json);
                        }
                        //catch (Exception ex)
                        {

                            //throw ex;
                        }


                    }

                }
            }
        }


        [HttpPost]
        public async Task<JsonStringResult> GetDesignerApplicationTreeBySearch(int compid, string filenameContains)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (user.Email == "admin@admin.com")
                rolename = "admin";

            if (rolename == "admin")
            {

                try
                {
                    var result = (from tree in _context.tblApplicationDesignerDiagram
                                  join design in _context.tblDesignerTree on tree.DesignerTreeId equals design.id
                                  where tree.CompanyId == compid && tree.FileName.Contains(filenameContains) && tree.IsTemplate == false

                                  select new DesignerTree
                                  {
                                      id = tree.DiagramId.ToString(),
                                      text = tree.FileName,
                                      parent = tree.DesignerTreeId.ToString(),
                                      folderLevel = design.FolderLevel,
                                      parentText = design.text

                                  }).ToList();




                    var json = JsonConvert.SerializeObject(result);
                    return new JsonStringResult(json);
                }
                catch (Exception ex)
                {
                    var g = ex;
                    throw;
                }

            }
            else
            {


                var result = (from tree in _context.tblApplicationDesignerDiagram
                              join design in _context.tblDesignerTree on tree.DesignerTreeId equals design.id
                              where tree.CompanyId == compid && tree.FileName.Contains(filenameContains) && tree.OwnerId.ToString() == user.Id && tree.IsTemplate == false

                              select new DesignerTree
                              {
                                  id = tree.DiagramId.ToString(),
                                  text = tree.FileName,
                                  parent = tree.DesignerTreeId.ToString(),
                                  folderLevel = design.FolderLevel,
                                  parentText = design.text

                              }).ToList();









                //try
                {
                    var resultShared = (from tree in _context.tblApplicationDesignerDiagram
                                        join sharedapp in _context.tblSharedApplicationWithUser on tree.DiagramId equals sharedapp.SharedApplicationId
                                        where tree.CompanyId == compid && tree.FileName.Contains(filenameContains) && sharedapp.SharedWithUserEmail == user.Email && tree.IsTemplate == false


                                        select new DesignerTree
                                        {
                                            id = tree.DiagramId.ToString(),
                                            text = tree.FileName,
                                            parent = "-999",
                                            folderLevel = 2,
                                            parentText = ""
                                        }).ToList();
                    if (resultShared.Count > 0)
                    {

                        result.AddRange(resultShared);
                    }
                    var json = JsonConvert.SerializeObject(result);


                    return new JsonStringResult(json);
                }
                //catch (Exception ex)
                {

                //    throw ex;
                }




            }
        }


        public async Task<JsonStringResult> RemoveFileSharing(int SharedApplicationId, int compid)
        {

            try
            {

                var user = await _userManager.GetUserAsync(HttpContext.User);

                var rolename = GetRole(user.Id);
                if (user.Email == "admin@admin.com")
                    rolename = "admin";

                if (rolename == "admin")
                {
                    var res = from t in _context.tblSharedApplicationWithUser
                              where t.SharedApplicationWithUserId == SharedApplicationId && t.CompanyId == compid
                              select t;





                    var result = _context.tblSharedApplicationWithUser.Where(x => x.SharedApplicationWithUserId == SharedApplicationId);
                    _context.tblSharedApplicationWithUser.Remove(result.FirstOrDefault());

                    _context.SaveChanges();

                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Success" });
                    return new JsonStringResult(json);
                }
                else
                {

                    var res = from t in _context.tblSharedApplicationWithUser
                              where t.SharedApplicationWithUserId == SharedApplicationId && t.CompanyId == compid && t.WhoSharedId == user.Id
                              select t;



                    if (res == null)
                    {

                        var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "You don't have access to remove sharing" });
                        return new JsonStringResult(json1);

                    }

                    if (res.Count() == 0)
                    {

                        var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "You don't have access to remove sharing" });
                        return new JsonStringResult(json1);

                    }

                    var result = _context.tblSharedApplicationWithUser.Where(x => x.SharedApplicationWithUserId == SharedApplicationId);
                    _context.tblSharedApplicationWithUser.Remove(result.FirstOrDefault());

                    _context.SaveChanges();

                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Success" });
                    return new JsonStringResult(json);

                }
            }
            catch (Exception)
            {

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to Remove sharing" });
                return new JsonStringResult(json);
            }




        }





        public async Task<JsonStringResult> GetFolderSharingDetail(int CompanyId, int FolderId, string FolderName)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var roleName = GetRole(user.Id);
            if (roleName == "")
                roleName = "admin";

            if (roleName == "admin")
            {
                var result = (from a in _context.tblSharedFolderWithUser
                              where a.SharedFolderId == FolderId && a.CompanyId == CompanyId
                              select new SharedApplicationDetailModel()
                              {
                                  SharedApplicationWithUserId = a.SharedFolderWithUserId,
                                  FileName = FolderName,
                                  SharedWithUserEmail = a.SharedWithUserEmail,
                                  SharedApplicationId = a.SharedFolderId

                              });

                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            else
            {
                var result = (from a in _context.tblSharedFolderWithUser
                              where a.SharedFolderId == FolderId && a.CompanyId == CompanyId
                              select new SharedApplicationDetailModel()
                              {
                                  SharedApplicationWithUserId = a.SharedFolderWithUserId,
                                  FileName = FolderName,
                                  SharedWithUserEmail = a.SharedWithUserEmail,
                                  SharedApplicationId = a.SharedFolderId

                              });
                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
        }

        public async Task<JsonStringResult> GetSharingDetail(int CompanyId, int FileId, string FileName)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var roleName = GetRole(user.Id);
            if (roleName == "")
                roleName = "admin";

            if (roleName == "admin")
            {
                var result = (from a in _context.tblSharedApplicationWithUser
                              where a.SharedApplicationId == FileId && a.CompanyId == CompanyId
                              select new SharedApplicationDetailModel()
                              {
                                  SharedApplicationWithUserId = a.SharedApplicationWithUserId,
                                  FileName = FileName,
                                  SharedWithUserEmail = a.SharedWithUserEmail,
                                  SharedApplicationId = a.SharedApplicationId

                              });

                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);

            }
            else
            {
                var result = (from a in _context.tblSharedApplicationWithUser
                              where a.SharedApplicationId == FileId && a.CompanyId == CompanyId
                              select new SharedApplicationDetailModel()
                              {
                                  SharedApplicationWithUserId = a.SharedApplicationWithUserId,
                                  FileName = FileName,
                                  SharedWithUserEmail = a.SharedWithUserEmail,
                                  SharedApplicationId = a.SharedApplicationId

                              });

                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
        }

        [HttpPost]
        public async Task<JsonStringResult> CreateDesignerFolder(int compid, string parent, string foldername, int selectedNodeLevel)
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);
            var AppDiagram = new tblDesignerTree();
            AppDiagram.parent = parent;

            AppDiagram.parentint = int.Parse(parent);
            AppDiagram.text = foldername;
            AppDiagram.CompanyId = compid;
            AppDiagram.FolderLevel = selectedNodeLevel;
            AppDiagram.Active = true;
            AppDiagram.CreatedBy = user.Id;
            AppDiagram.CreatedAt = DateTime.Now;

            AppDiagram.ModifiedBy = user.Id;
            AppDiagram.ModifiedAt = DateTime.Now;

            _context.tblDesignerTree.Add(AppDiagram);
            var dig = await _context.SaveChangesAsync();




            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = AppDiagram.id.ToString() });
            return new JsonStringResult(json);
        }


        public void RecursiveDesignerTreeDelete(int id)
        {

            var res = from t in _context.tblDesignerTree
                      where t.parentint == id
                      select t;


            foreach (var item in res)
            {
                //for each child ,delet its' childs by calling recursively
                RecursiveDesignerTreeDelete(item.id);
            }


            var tre = _context.tblDesignerTree.Find(id);
            _context.tblDesignerTree.Remove(tre);

        }

        [HttpPost]
        public async Task<JsonStringResult> DeleteFolder(int DiagramId, int compid)
        {
            try
            {







                RecursiveDesignerTreeDelete(DiagramId);

                var dig = await _context.SaveChangesAsync();




                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Folder deleted successfully !" });
                return new JsonStringResult(json);
            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "DeleteFolder", "Graph", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to delete folder !" });
                return new JsonStringResult(json);
            }

        }


        [HttpPost]
        public async Task<JsonStringResult> DeleteFile(int DiagramId, int compid)
        {
            try
            {

                var selectedFile = _context.tblApplicationDesignerDiagram.Where(x => x.DiagramId == DiagramId);

                if (selectedFile != null)
                {
                    if (selectedFile.Count() > 0)
                    {
                        _context.tblApplicationDesignerDiagram.Remove(selectedFile.FirstOrDefault());
                        await _context.SaveChangesAsync();
                        var jsonResult = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "File deleted successfully" });
                        return new JsonStringResult(jsonResult);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to delete file !" });
                        return new JsonStringResult(json);
                    }
                }

                else
                {
                    var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to delete file !" });
                    return new JsonStringResult(json);
                }





            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "DeleteFile", "Graph", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to delete file !" });
                return new JsonStringResult(json);
            }

        }

        [HttpPost]
        public async Task<JsonStringResult> RenameFileFolder(int FileFolderId, int compid, int isFile, string RenamedName)
        {
            try
            {
                if (isFile == 1)
                {
                    var selectedFile = _context.tblApplicationDesignerDiagram.Where(x => x.DiagramId == FileFolderId);

                    if (selectedFile != null)
                    {
                        if (selectedFile.Count() > 0)
                        {
                            _context.tblApplicationDesignerDiagram.Where(x => x.DiagramId == FileFolderId).FirstOrDefault().FileName = RenamedName;
                            await _context.SaveChangesAsync();
                            var jsonResult = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Renamed successfully" });
                            return new JsonStringResult(jsonResult);

                        }
                        else
                        {
                            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to rename !" });
                            return new JsonStringResult(json);
                        }
                    }

                    else
                    {
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to rename !" });
                        return new JsonStringResult(json);
                    }
                }
                else
                {
                    var selectedFile = _context.tblDesignerTree.Where(x => x.id == FileFolderId);

                    if (selectedFile != null)
                    {
                        if (selectedFile.Count() > 0)
                        {
                            _context.tblDesignerTree.Where(x => x.id == FileFolderId).FirstOrDefault().text = RenamedName;
                            await _context.SaveChangesAsync();
                            var jsonResult = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Renamed successfully" });
                            return new JsonStringResult(jsonResult);

                        }
                        else
                        {
                            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to rename !" });
                            return new JsonStringResult(json);
                        }
                    }

                    else
                    {
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to rename !" });
                        return new JsonStringResult(json);
                    }
                }




            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "RenameFileFolder", "Graph", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to rename !" });
                return new JsonStringResult(json);
            }

        }


        [HttpPost]
        public JsonStringResult GetDesignerApplications(int compid)
        {

            try
            {


                var allAllowedDiagrams = from a in _context.tblApplicationDesignerDiagram
                                         where a.CompanyId == compid
                                         select a;

                List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                foreach (var file in allAllowedDiagrams)
                {



                    lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), parentid = file.DesignerTreeId.ToString(), text = file.FileName, type = "tree" });


                }




                var json = JsonConvert.SerializeObject(lst);
                return new JsonStringResult(json);







            }

            catch (Exception ex)
            {

                var userid = SmartAdmin.Seed.Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                SmartAdmin.Seed.Extensions.ErrorLogExtension.RecordErrorLogException(ex, "GetDesignerApplications", "Graph", userid, _context);
                return new JsonStringResult("[]");
            }
        }


        [HttpPost]
        public async Task<JsonStringResult> GetFrameworkData()
        {

            var user = await _userManager.GetUserAsync(HttpContext.User);

            var rolename = GetRole(user.Id);
            if (rolename == "")
                rolename = "admin";

            if (rolename == "admin")
            {

                var result = (from allcountries in _context.lkpCountry

                              select new FrameworkTree
                              {
                                  id = "co" + allcountries.CountryId.ToString(),
                                  text = allcountries.CountryName,
                                  type = "root"


                              }).ToList();

                foreach (var c in result)
                {
                    int id = int.Parse(c.id.Replace("co", ""));
                    c.children = GetStates(id, user.Id, rolename);
                }


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }
            else
            {
                var result = (from c in _context.Authorization_AllowedCountries
                              join allcountries in _context.lkpCountry on c.CountryId equals allcountries.CountryId
                              where c.UserId == user.Id
                              select new FrameworkTree
                              {
                                  id = "co" + c.CountryId.ToString(),
                                  text = allcountries.CountryName,
                                  type = "root"


                              }).ToList();

                foreach (var c in result)
                {
                    int id = int.Parse(c.id.Replace("co", ""));
                    c.children = GetStates(id, user.Id, rolename);
                }


                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);
            }





        }

        private string GetRole(string userId)
        {

            var RoleName = (from ur in _context.UserRoles.AsEnumerable()
                            join r in _context.Roles.AsEnumerable() on ur.RoleId equals r.Id
                            where ur.UserId.ToString() == userId.ToString()
                            select r).ToList();

            if (RoleName != null)
            {
                if (RoleName.Count() > 0)
                {
                    return RoleName.FirstOrDefault().Name.ToLower();
                }
                else
                {
                    return "";
                }
            }
            else
            {
                return "";
            }


        }




        [HttpPost]
        public async Task<JsonStringResult> ShareFolderViaEmail(int compid, int folderid, string email, string foldername, bool isfilesharing)
        {



            try
            {
                if (isfilesharing == false)
                {
                    try
                    {
                        var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();

                        var alreadyshared = from s in _context.tblSharedFolderWithUser
                                            where s.SharedWithUserEmail == email && s.SharedFolderId == folderid
                                            select s;

                        if (alreadyshared.Count() > 0)
                        {

                            var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Folder is already shared with this email" });
                            return new JsonStringResult(json1);

                        }
                        else
                        {
                            var sharedfolder = new tblSharedFolderWithUser();
                            sharedfolder.SharedFolderId = folderid;
                            sharedfolder.CompanyId = compid;
                            sharedfolder.WhoSharedId = userid;
                            sharedfolder.SharedAt = DateTime.Now;
                            sharedfolder.SharedWithUserEmail = email;
                            _context.tblSharedFolderWithUser.Add(sharedfolder);
                            _context.SaveChanges();
                            var callbackUrl = Options.HostURL;
                            var msg = $" <b>Hi,</b> <br/> <br/> <br/> Folder (" + foldername + ") is shared with you — accept the invitation to take a closer look! <br/><br/><br/> <a class='btn btn-info' href='" + System.Text.Encodings.Web.HtmlEncoder.Default.Encode(Options.HostURL) + "'><b>Accept Invitation</b></a> <br/><br/>Thank you,<br/>Sales Team <br/><br/><img src='cid:imgLogo' width='100' height='80' style='width:100px;height80px;'/>";





                            string result = await _emailSender.ShareFolderEmailAsync(email, "Shared Folder ( " + foldername + " )", msg);


                            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = result });
                            return new JsonStringResult(json);
                        }
                    }
                    catch (Exception ex)
                    {
                        var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                        Extensions.ErrorLogExtension.RecordErrorLogException(ex, "ShareFolderViaEmail", "Graph(Index)", userid, _context);

                        var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to share folder" });
                        return new JsonStringResult(json1);
                    }
                }
                else
                {
                    try
                    {
                        var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                        if (folderid == -99)
                        {
                            foldername = foldername.Replace(".xml.xml", ".xml");
                            foldername = foldername.Replace(".xml", "");

                            var getActualFileId = (from f in _context.tblApplicationDesignerDiagram where f.FileName == foldername && f.CompanyId == compid select f).FirstOrDefault();

                            if (getActualFileId != null)
                            {
                                folderid = getActualFileId.DiagramId;
                            }
                            else
                            {
                                foldername = foldername + ".xml";

                                var getActualFileIdWithXML = (from f in _context.tblApplicationDesignerDiagram where f.FileName == foldername && f.CompanyId == compid select f).FirstOrDefault();

                                if (getActualFileIdWithXML != null)
                                {
                                    folderid = getActualFileIdWithXML.DiagramId;
                                }




                            }
                        }

                        var alreadyshared = from s in _context.tblSharedApplicationWithUser
                                            where s.SharedWithUserEmail == email && s.SharedApplicationId == folderid
                                            select s;

                        foldername = foldername.Replace(".xml.xml", ".xml");
                        foldername = foldername.Replace(".xml", "");

                        if (alreadyshared.Count() > 0)
                        {

                            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Diagram is already shared with this email" });
                            return new JsonStringResult(json);

                        }
                        else
                        {
                            var sharedapplication = new tblSharedApplicationWithUser();
                            sharedapplication.SharedApplicationId = folderid;
                            sharedapplication.CompanyId = compid;
                            sharedapplication.WhoSharedId = userid;
                            sharedapplication.SharedAt = DateTime.Now;
                            sharedapplication.SharedWithUserEmail = email;
                            _context.tblSharedApplicationWithUser.Add(sharedapplication);

                            _context.SaveChanges();
                            var callbackUrl = Options.HostURL;
                            var msg = $" <b>Hi,</b> <br/> <br/> <br/> Diagram (" + foldername + ") is shared with you — accept the invitation to take a closer look! <br/><br/><br/> <a class='btn btn-info' href='" + System.Text.Encodings.Web.HtmlEncoder.Default.Encode(Options.HostURL) + "'><b>Accept Invitation</b></a><br/><br/>Thank you,<br/>Sales Team <br/><br/><img src='cid:imgLogo' width='100' height='80' style='width:100px;height80px;'/>";

                            string result = await _emailSender.ShareFolderEmailAsync(email, "Shared Diagram ( " + foldername + " )", msg);

                            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = result });
                            return new JsonStringResult(json);

                        }


                    }
                    catch (Exception ex)
                    {
                        var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                        Extensions.ErrorLogExtension.RecordErrorLogException(ex, "ShareFolderViaEmail", "Graph(Index)", userid, _context);

                        var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to share folder" });
                        return new JsonStringResult(json1);
                    }
                }



            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "ShareFolderViaEmail", "Graph(Index)", userid, _context);

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }



        }
        [HttpPost]
        public async Task<JsonStringResult> SharedViaEmail(string name, string email)
        {



            try
            {

                var user = await _userManager.GetUserAsync(HttpContext.User);

                var DiagramId = from d in _context.ApplicationDiagram
                                where d.FileName == name
                                select d;
                var fileContents = "";
                if (DiagramId != null)
                {

                    if (DiagramId.Count() > 0)
                    {

                        fileContents = DiagramId.FirstOrDefault().DiagramXML;



                    }
                    else
                    {

                    }
                }






                await _emailSender.SendDiagramEmailAsync(email, "Shared diagram ( " + name + " )",
              $"" + fileContents + "", name);

                var json = JsonConvert.SerializeObject("success");
                return new JsonStringResult(json);

            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "SharedViaEmail", "Graph(Index)", userid, _context);

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }



        }

        [HttpPost]
        public JsonStringResult ExportData(string xml, string filename, string format, int w, int h, string bg)
        {

            try
            {


                if (filename != null)
                {
                    filename = HttpUtility.UrlDecode(filename);
                }

                string s = System.Uri.UnescapeDataString(xml);
                int width = w;
                int height = h;

                if (xml != null && bg != null
                   && filename != null && format != null)
                {
                    var html = @"
                        <html>
                            <head></head>
                            <body>" + s +

                            "</body></html>";


                    var doc = new HtmlToPdfDocument()
                    {
                        GlobalSettings =
                {
                    ColorMode = ColorMode.Color,
                    Orientation = Orientation.Portrait,
                    PaperSize = PaperKind.A4,
                    DocumentTitle = "Bug"
                },
                        Objects =
                {
                    new ObjectSettings()
                    {
                        HtmlContent = html
                    }
                }
                    };

                    var converter = new BasicConverter(new PdfTools());

                    byte[] file = converter.Convert(doc);
                    // return File(file, "application/pdf");
                }
                else
                {
                    //context.Response.StatusCode = 400; /* Bad Request */
                }


                var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                return new JsonStringResult(json1);



            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "ExportData", "Graph(Index)", userid, _context);

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }



        }

        [HttpPost]
        public async Task<JsonStringResult> SaveData(string xml, string fileName, int compid, int updateMode, string SelectedFolderId)
        {

            try
            {

                fileName = fileName.Replace(".xml.xml", ".xml");
                var user = await _userManager.GetUserAsync(HttpContext.User);
                var DiagramId = from d in _context.tblApplicationDesignerDiagram
                                where d.FileName == fileName && d.CompanyId == compid
                                select d;

                if (updateMode == 0)  //Insert new diagram
                {

                    if (DiagramId != null)
                    {

                        //if (DiagramId.Count() > 0)
                        //{


                        //    var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Diagram with the same name already exists" });
                        //    return new JsonStringResult(jsonRes);
                        //}
                        //else
                        //{
                        var AppDiagram = new tblApplicationDesignerDiagram();
                        if (SelectedFolderId == "-111")
                        {
                            var id = (from rid in _context.tblDesignerTree where rid.CompanyId == compid && rid.CreatedBy == user.Id select rid.id.ToString()).FirstOrDefault();
                            AppDiagram.DesignerTreeId = int.Parse(id);
                        }
                        else
                        {
                            AppDiagram.DesignerTreeId = int.Parse(SelectedFolderId);
                        }
                        AppDiagram.FileName = fileName;
                        AppDiagram.CompanyId = compid;
                        AppDiagram.DiagramXML = xml;
                        AppDiagram.OwnerId = Guid.Parse(user.Id);
                        _context.tblApplicationDesignerDiagram.Add(AppDiagram);
                        var dig = await _context.SaveChangesAsync();




                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                        return new JsonStringResult(json);
                        //}
                    }
                    var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                    return new JsonStringResult(json1);

                }
                else  //Update existing diagram
                {
                    if (DiagramId != null)
                    {

                        if (DiagramId.Count() > 0)
                        {
                            DiagramId.FirstOrDefault().DiagramXML = xml;
                            await _context.SaveChangesAsync();

                            var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                            return new JsonStringResult(jsonRes);
                        }

                    }


                    var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                    return new JsonStringResult(json1);
                }





                //if (updateMode == 0)  //Insert new diagram
                //{

                //    if (DiagramId != null)
                //    {

                //        if (DiagramId.Count() > 0)
                //        {


                //            var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Diagram with the same name already exists" });
                //            return new JsonStringResult(jsonRes);
                //        }
                //        else
                //        {
                //            var AppDiagram = new ApplicationDiagram();
                //            AppDiagram.ApplicationId = -1;
                //            AppDiagram.FileName = fileName;
                //            AppDiagram.CompanyId = compid;
                //            AppDiagram.DiagramXML = xml;
                //            AppDiagram.OwnerId = Guid.Parse(user.Id);
                //            _context.ApplicationDiagram.Add(AppDiagram);
                //            var dig = await _context.SaveChangesAsync();


                //            ApplicationDiagramDetail det = new ApplicationDiagramDetail();
                //            det.SharedApplicationId = -1;
                //            det.DiagramId = AppDiagram.DiagramId;
                //            det.CompanyId = compid;
                //            det.SharedWithId = Guid.Parse(user.Id);
                //            _context.ApplicationDiagramDetail.Add(det);
                //            await _context.SaveChangesAsync();


                //            var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                //            return new JsonStringResult(json);
                //        }
                //    }
                //    var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                //    return new JsonStringResult(json1);

                //}
                //else  //Update existing diagram
                //{
                //    if (DiagramId != null)
                //    {

                //        if (DiagramId.Count() > 0)
                //        {
                //            DiagramId.FirstOrDefault().DiagramXML = xml;
                //            await _context.SaveChangesAsync();

                //            var jsonRes = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                //            return new JsonStringResult(jsonRes);
                //        }

                //    }


                //    var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                //    return new JsonStringResult(json1);
                //}


            }
            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "SaveData", "Graph(Index)", userid, _context);

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }



        }





        private List<FrameworkTree> GetStates(int countryid, string userid, string roleName)
        {
            if (roleName == "country" || roleName == "admin")
            {

                var result = (from allstates in _context.lkpState
                              where allstates.CountryId == countryid
                              select new FrameworkTree
                              {
                                  id = "st" + allstates.StateId.ToString(),
                                  text = allstates.StateName,
                                  type = "root"


                              }).ToList();
                foreach (var c in result)
                {
                    int id = int.Parse(c.id.Replace("st", ""));
                    c.children = GetCities(id, userid, roleName);
                }

                return result;

            }
            else
            {
                var result = (from s in _context.Authorization_AllowedStates
                              join allstates in _context.lkpState on s.StateId equals allstates.StateId
                              where allstates.CountryId == countryid && s.UserId == userid
                              select new FrameworkTree
                              {
                                  id = "st" + s.StateId.ToString(),
                                  text = allstates.StateName,
                                  type = "root"


                              }).ToList();
                foreach (var c in result)
                {
                    int id = int.Parse(c.id.Replace("st", ""));
                    c.children = GetCities(id, userid, roleName);
                }

                return result;
            }
        }

        private List<FrameworkTree> GetCities(int stateid, string userid, string roleName)
        {


            if (roleName == "admin" || roleName == "country")
            {
                var result = (from allcities in _context.lkpCity
                              where allcities.StateId == stateid
                              select new FrameworkTree
                              {
                                  id = "ci" + allcities.CityId.ToString(),
                                  text = allcities.CityName,
                                  type = "root"


                              }).ToList();

                foreach (var d in result)
                {
                    int id = int.Parse(d.id.Replace("ci", ""));
                    d.children = GetDataCenter(id, userid, roleName);
                }


                return result;
            }
            else
            {
                var result = (from s in _context.Authorization_AllowedCities
                              join allcities in _context.lkpCity on s.CityId equals allcities.CityId
                              where allcities.StateId == stateid && s.UserId == userid
                              select new FrameworkTree
                              {
                                  id = "ci" + s.CityId.ToString(),
                                  text = allcities.CityName,
                                  type = "root"


                              }).ToList();

                foreach (var d in result)
                {
                    int id = int.Parse(d.id.Replace("ci", ""));
                    d.children = GetDataCenter(id, userid, roleName);
                }


                return result;
            }
        }

        private List<FrameworkTree> GetDataCenter(int cityid, string userid, string roleName)
        {
            if (roleName == "admin" || roleName == "country")
            {
                var result = (
                              from alldatacenters in _context.lkpDataCenter
                              where alldatacenters.CityId == cityid
                              select new FrameworkTree
                              {
                                  id = "dc" + alldatacenters.DataCenterId.ToString(),
                                  text = alldatacenters.DataCenterName,
                                  type = "root",



                              }).ToList();

                foreach (var de in result)
                {
                    int id = int.Parse(de.id.Replace("dc", ""));
                    de.children = GetDepartment(id, userid, roleName);
                }

                return result;
            }
            else
            {
                var result = (from s in _context.Authorization_AllowedDatacenters
                              join alldatacenters in _context.lkpDataCenter on s.DatacenterId equals alldatacenters.DataCenterId
                              where alldatacenters.CityId == cityid && s.UserId == userid
                              select new FrameworkTree
                              {
                                  id = "dc" + s.DatacenterId.ToString(),
                                  text = alldatacenters.DataCenterName,
                                  type = "root",



                              }).ToList();

                foreach (var de in result)
                {
                    int id = int.Parse(de.id.Replace("dc", ""));
                    de.children = GetDepartment(id, userid, roleName);
                }

                return result;
            }
        }

        public IActionResult mxgraph()
        {
            return View();
        }

        [HttpPost]
        public JsonResult SaveGraph([FromBody] EditorUIXML xml)
        {

            //            Dim xmlSource As String = "<xml><item>1</item><xml><item>2</item><xml><item>3</item></xml>"
            //Dim xmlDoc As New XmlDocument
            //xmlDoc.LoadXml(xmlSource)


            using (FileStream fileStream = new FileStream("file.xml", FileMode.Create))
            {

                XmlWriterSettings settings = new XmlWriterSettings() { Indent = true };
                XmlWriter writer = XmlWriter.Create(fileStream, settings);
                writer.WriteRaw(xml.XMLData);
                writer.Flush();
                fileStream.Flush();
            }
            return Json("Success");
        }

        private List<FrameworkTree> GetDepartment(int datacenterid, string userid, string roleName)
        {
            if (roleName == "admin" || roleName == "country" || roleName == "datacenter")
            {
                var result = (from alldepts in _context.lkpDepartment
                              where alldepts.DataCenterId == datacenterid
                              select new FrameworkTree
                              {
                                  id = "de" + alldepts.DepartmentId.ToString(),
                                  text = alldepts.DepartmentName,
                                  type = "dept"


                              }).ToList();


                foreach (var de in result)
                {
                    int id = int.Parse(de.id.Replace("de", ""));
                    de.children = GetApplicationForDepartment(id, userid, roleName);
                }

                return result;
            }
            else
            {
                var result = (from s in _context.Authorization_AllowedDepartments
                              join alldepts in _context.lkpDepartment on s.DepartmentId equals alldepts.DepartmentId
                              where alldepts.DataCenterId == datacenterid && s.UserId == userid
                              select new FrameworkTree
                              {
                                  id = "de" + s.DepartmentId.ToString(),
                                  text = alldepts.DepartmentName,
                                  type = "dept"


                              }).ToList();


                foreach (var de in result)
                {
                    int id = int.Parse(de.id.Replace("de", ""));
                    de.children = GetApplicationForDepartment(id, userid, roleName);
                }

                return result;
            }
        }



        [HttpPost]
        public List<FrameworkTree> GetApplicationForDepartment(int departmentId, string userid, string roleName)
        {

            try
            {

                if (roleName == "admin" || roleName == "country" || roleName == "datacenter" || roleName == "department")
                {

                    var result = (from a in _context.lkpApplication.AsEnumerable()
                                  join d in _context.lkpDepartment on a.DepartmentId equals d.DepartmentId
                                  where d.DepartmentId == departmentId
                                  select new FrameworkTree
                                  {
                                      id = "ap" + a.ApplicationId.ToString(),
                                      text = a.ApplicationName,
                                      type = "app"


                                  }).ToList();


                    foreach (var ap in result)
                    {
                        int id = int.Parse(ap.id.Replace("ap", ""));
                        ap.children = GetDiagramForApplication(id, userid);
                    }



                    return result;

                }
                else
                {
                    var result = (from d in _context.lkpDepartment.AsEnumerable()
                                  join a in _context.lkpApplication.AsEnumerable() on d.DepartmentId equals a.DepartmentId into ps
                                  from p in ps.AsEnumerable().DefaultIfEmpty()
                                  where d.DepartmentId == departmentId && p.ApplicationName != null
                                  select new FrameworkTree
                                  {
                                      id = "ap" + p.ApplicationId.ToString(),
                                      text = p.ApplicationName,
                                      type = "app"


                                  }).ToList();


                    foreach (var ap in result)
                    {
                        int id = int.Parse(ap.id.Replace("ap", ""));
                        ap.children = GetDiagramForApplication(id, userid);
                    }



                    return result;
                }


            }

            catch (Exception)
            {
                //var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                //ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentForDataCenter", "Home", userid, _context);
                return null;
            }
        }



        public List<FrameworkTree> GetDiagramForApplication(int applicationId, string userid)
        {

            try
            {
                var result = (from d in _context.ApplicationDiagramDetail.AsEnumerable()
                              join m in _context.ApplicationDiagram on d.DiagramId equals m.DiagramId
                              where d.SharedApplicationId == applicationId && d.SharedWithId == Guid.Parse(userid)
                              select new FrameworkTree
                              {
                                  id = "diag" + d.DiagramId.ToString(),
                                  text = m.FileName.Replace(".xml", ""),
                                  type = "tree"


                              }).ToList();





                return result;


            }

            catch (Exception)
            {
                //var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                //ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentForDataCenter", "Home", userid, _context);
                return null;
            }
        }


        [HttpPost]
        public async Task<JsonStringResult> SaveDiagramDetail(string appId, string FileName, int compid)
        {

            try
            {
                FileName = FileName + ".xml";
                appId = appId.Replace("ap", "");
                int application_id = int.Parse(appId);
                var DiagramId = from d in _context.ApplicationDiagram
                                where d.FileName == FileName && d.CompanyId == compid
                                select d;

                if (DiagramId != null)
                {

                    if (DiagramId.Count() > 0)
                    {
                        var user = await _userManager.GetUserAsync(HttpContext.User);
                        Guid userid = Guid.Parse(user.Id);
                        var ApplicationDetail = from d in _context.ApplicationDiagramDetail
                                                where d.DiagramId == DiagramId.FirstOrDefault().DiagramId && d.SharedWithId == userid && d.CompanyId == compid
                                                select d;

                        if (application_id != -1)     // actual drag drop operation completed
                        {
                            if (ApplicationDetail == null || ApplicationDetail.Count() == 0)
                            {
                                ApplicationDiagramDetail det = new ApplicationDiagramDetail();
                                det.SharedApplicationId = application_id;
                                det.DiagramId = DiagramId.FirstOrDefault().DiagramId;
                                det.CompanyId = compid;
                                det.SharedWithId = DiagramId.FirstOrDefault().OwnerId;
                                _context.ApplicationDiagramDetail.Add(det);
                                await _context.SaveChangesAsync();
                            }
                            else
                            {
                                ApplicationDetail.FirstOrDefault().SharedApplicationId = application_id;
                                await _context.SaveChangesAsync();
                                //ApplicationDetail.FirstOrDefault().DiagramId = DiagramId.FirstOrDefault().DiagramId;
                                //ApplicationDetail.FirstOrDefault().SharedWithId = userid;
                            }
                        }
                        else     //Move application back to main application tree by making it -1
                        {
                            ApplicationDetail.FirstOrDefault().SharedApplicationId = -1;
                            await _context.SaveChangesAsync();
                        }
                    }

                }
                else
                {

                }

                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "success" });
                return new JsonStringResult(json);


            }

            catch (Exception ex)
            {

                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "SaveDiagramDetail", "Graph(Index)", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }
        }


        [HttpPost]
        public async Task<JsonStringResult> DeleteDiagramDetail(string FileName, int compid)
        {

            try
            {
                var user = await _userManager.GetUserAsync(HttpContext.User);
                Guid userid = Guid.Parse(user.Id);
                FileName = FileName + ".xml";

                var DiagramId = from d in _context.ApplicationDiagram
                                where d.FileName == FileName && d.OwnerId == userid && d.CompanyId == compid
                                select d;

                if (DiagramId != null)
                {

                    if (DiagramId.Count() > 0)
                    {


                        _context.ApplicationDiagram.Remove(DiagramId.FirstOrDefault());
                        await _context.SaveChangesAsync();
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Application xml deleted successfully" });
                        return new JsonStringResult(json);

                    }
                    else
                    {
                        var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to delete XML,Only owner can delete" });
                        return new JsonStringResult(json);
                    }

                }


                var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "" });
                return new JsonStringResult(json1);


            }

            catch (Exception ex)
            {

                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "DeleteDiagramDetail", "Graph(Index)", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = ex.Message });
                return new JsonStringResult(json);
            }
        }

        [HttpPost]
        public async Task<JsonStringResult> GetAllowedApplication()
        {

            try
            {



                var user = await _userManager.GetUserAsync(HttpContext.User);

                var rolename = GetRole(user.Id);
                if (rolename == "")
                    rolename = "admin";
                if (rolename == "country")
                {
                    var allAllowedDiagrams = (from add in _context.ApplicationDiagramDetail.AsEnumerable()
                                              join ad in _context.ApplicationDiagram.AsEnumerable() on add.DiagramId equals ad.DiagramId
                                              join ac in _context.Authorization_AllowedCountries.AsEnumerable() on add.SharedWithId.ToString() equals ac.UserId.ToString()
                                              where (from alc in _context.Authorization_AllowedCountries.AsEnumerable() where alc.UserId == user.Id select alc.CountryId).Contains(ac.CountryId)
                                              && !(from ad in _context.ApplicationDiagramDetail
                                                   where ad.SharedWithId == Guid.Parse(user.Id) && ad.SharedApplicationId != -1
                                                   select ad.DiagramId)
                      .Contains(ad.DiagramId)
                                              select ad).Distinct();

                    List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                    foreach (var file in allAllowedDiagrams)
                    {

                        var filename = Path.GetFileNameWithoutExtension(file.FileName);

                        lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), text = filename, type = "tree" });


                    }




                    var json = JsonConvert.SerializeObject(lst);
                    return new JsonStringResult(json);

                }

                else if (rolename == "datacenter")
                {
                    var allAllowedDiagrams = (from add in _context.ApplicationDiagramDetail.AsEnumerable()
                                              join ad in _context.ApplicationDiagram.AsEnumerable() on add.DiagramId equals ad.DiagramId
                                              join ac in _context.Authorization_AllowedDatacenters.AsEnumerable() on add.SharedWithId.ToString() equals ac.UserId.ToString()
                                              where (from alc in _context.Authorization_AllowedDatacenters.AsEnumerable() where alc.UserId == user.Id select alc.DatacenterId).Contains(ac.DatacenterId)
                                                  && !(from ad in _context.ApplicationDiagramDetail
                                                       where ad.SharedWithId == Guid.Parse(user.Id) && ad.SharedApplicationId != -1
                                                       select ad.DiagramId)
                      .Contains(ad.DiagramId)
                                              select ad).Distinct();

                    List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                    foreach (var file in allAllowedDiagrams)
                    {

                        var filename = Path.GetFileNameWithoutExtension(file.FileName);

                        lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), text = filename, type = "tree" });


                    }




                    var json = JsonConvert.SerializeObject(lst);
                    return new JsonStringResult(json);

                }

                else if (rolename == "department")
                {
                    var allAllowedDiagrams = (from add in _context.ApplicationDiagramDetail.AsEnumerable()
                                              join ad in _context.ApplicationDiagram.AsEnumerable() on add.DiagramId equals ad.DiagramId
                                              join ac in _context.Authorization_AllowedDepartments.AsEnumerable() on add.SharedWithId.ToString() equals ac.UserId.ToString()
                                              where (from alc in _context.Authorization_AllowedDepartments.AsEnumerable() where alc.UserId == user.Id select alc.DepartmentId).Contains(ac.DepartmentId)
                                                  && !(from ad in _context.ApplicationDiagramDetail
                                                       where ad.SharedWithId == Guid.Parse(user.Id) && ad.SharedApplicationId != -1
                                                       select ad.DiagramId)
                      .Contains(ad.DiagramId)
                                              select ad).Distinct();

                    List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                    foreach (var file in allAllowedDiagrams)
                    {

                        var filename = Path.GetFileNameWithoutExtension(file.FileName);

                        lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), text = filename, type = "tree" });


                    }




                    var json = JsonConvert.SerializeObject(lst);
                    return new JsonStringResult(json);

                }

                else if (rolename == "application")
                {
                    var allAllowedDiagrams = (from add in _context.ApplicationDiagramDetail.AsEnumerable()
                                              join ad in _context.ApplicationDiagram.AsEnumerable() on add.DiagramId equals ad.DiagramId
                                              join ac in _context.Authorization_AllowedApplications.AsEnumerable() on add.SharedWithId.ToString() equals ac.UserId.ToString()
                                              where (from alc in _context.Authorization_AllowedApplications.AsEnumerable() where alc.UserId == user.Id select alc.ApplicationId).Contains(ac.ApplicationId)
                                                  && !(from ad in _context.ApplicationDiagramDetail
                                                       where ad.SharedWithId == Guid.Parse(user.Id) && ad.SharedApplicationId != -1
                                                       select ad.DiagramId)
                      .Contains(ad.DiagramId)
                                              select ad).Distinct();

                    List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                    foreach (var file in allAllowedDiagrams)
                    {

                        var filename = Path.GetFileNameWithoutExtension(file.FileName);

                        lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), text = filename, type = "tree" });


                    }




                    var json = JsonConvert.SerializeObject(lst);
                    return new JsonStringResult(json);

                }

                else
                {
                    var allAllowedDiagrams = from d in _context.ApplicationDiagram
                                             where !(from ad in _context.ApplicationDiagramDetail
                                                     where ad.SharedWithId == Guid.Parse(user.Id) && ad.SharedApplicationId != -1
                                                     select ad.DiagramId)
                                             .Contains(d.DiagramId)
                                             select d;

                    List<ApplicationTreeInGraph> lst = new List<ApplicationTreeInGraph>();



                    foreach (var file in allAllowedDiagrams)
                    {

                        var filename = Path.GetFileNameWithoutExtension(file.FileName);

                        lst.Add(new ApplicationTreeInGraph { id = file.DiagramId.ToString(), text = filename, type = "tree" });


                    }




                    var json = JsonConvert.SerializeObject(lst);
                    return new JsonStringResult(json);

                }

                //var allAllowedDiagrams = from d in _context.ApplicationDiagram
                //                         where d.OwnerId == Guid.Parse( user.Id)
                //                         select d;





                //var dirPath = Path.Combine(_env.WebRootPath, "App_Users\\" + user.UserName);


                //var files = Directory.GetFiles(dirPath, "*.xml", SearchOption.TopDirectoryOnly);




            }

            catch (Exception ex)
            {
                var g = ex;
                //var userid = UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                //ErrorLogExtension.RecordErrorLogException(ex, "GetDepartmentForDataCenter", "Home", userid, _context);
                return new JsonStringResult("[]");
            }
        }



        [HttpPost]
        public JsonStringResult GetAlreadySharedUsers(int compid, string FileName)
        {

            try
            {
                FileName = FileName + ".xml";



                var result = (from m in _context.ApplicationDiagram
                              join d in _context.ApplicationDiagramDetail on m.DiagramId equals d.DiagramId
                              where m.FileName == FileName
                              select new { d.SharedWithId }).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);


            }

            catch (Exception ex)
            {
                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "GetAlreadySharedUsers", "Graph(Index)", userid, _context);
                return new JsonStringResult("[]");

            }
        }

        [HttpPost]
        public JsonStringResult GetSharingUsers(int compid)
        {

            try
            {




                var result = (from f in _context.Users
                                  //  join allcountries in countries on c.CountryName equals allcountries.CountryName
                              join u in _context.UserRoles on f.Id equals u.UserId
                              join r in _context.Roles on u.RoleId equals r.Id
                              where f.CompanyId == compid
                              select new { r.Name, u.RoleId, f.Id, f.NormalizedUserName, f.UserName }).ToList();



                var json = JsonConvert.SerializeObject(result);
                return new JsonStringResult(json);


            }

            catch (Exception)
            {

                return new JsonStringResult("[]");
            }
        }

        [HttpPost]
        public async Task<JsonStringResult> SaveUserSharing(string all_usernames, string FileName, int compid, string AlreadyCheckedIds)
        {

            try
            {

                string[] objs = JsonConvert.DeserializeObject<string[]>(all_usernames);
                string[] existingIds = JsonConvert.DeserializeObject<string[]>(AlreadyCheckedIds);

                List<String> idsToRemove = new List<string>();
                foreach (string id in existingIds)
                {
                    if (!objs.Contains(id))
                    {
                        idsToRemove.Add(id);
                    }
                }

                FileName = FileName + ".xml";

                var ActualDiagramId = from d in _context.ApplicationDiagram where d.FileName == FileName select d;

                if (ActualDiagramId.Count() == 0)
                {
                    var jsonDiagram = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Please select valid diagram for sharing" });
                    return new JsonStringResult(jsonDiagram);
                }

                else
                {
                    foreach (var usr in objs)
                    {






                        var DiagramId = from d in _context.ApplicationDiagramDetail
                                        join m in _context.ApplicationDiagram on d.DiagramId equals m.DiagramId
                                        where m.FileName == FileName && d.SharedWithId == Guid.Parse(usr)
                                        select d;

                        if (DiagramId != null)
                        {

                            if (DiagramId.Count() == 0)
                            {



                                ApplicationDiagramDetail det = new ApplicationDiagramDetail();
                                det.SharedApplicationId = -1;
                                det.CompanyId = compid;
                                det.DiagramId = ActualDiagramId.FirstOrDefault().DiagramId;
                                det.SharedWithId = Guid.Parse(usr);
                                _context.ApplicationDiagramDetail.Add(det);


                            }
                            else
                            {


                            }

                        }


                    }
                }

                foreach (var id in idsToRemove)
                {
                    var appdetail = from a in _context.ApplicationDiagramDetail where a.DiagramId == ActualDiagramId.FirstOrDefault().DiagramId && a.SharedWithId == Guid.Parse(id) select a;
                    if (appdetail.Count() > 0)
                        _context.ApplicationDiagramDetail.Remove(appdetail.FirstOrDefault());
                }


                await _context.SaveChangesAsync();

                var json1 = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Diagram shared successfully" });
                return new JsonStringResult(json1);


            }

            catch (Exception ex)
            {

                var userid = Extensions.UserExtension.GetUserId(_userManager, HttpContext).GetAwaiter().GetResult();
                Extensions.ErrorLogExtension.RecordErrorLogException(ex, "SaveUserSharing", "Graph(Index)", userid, _context);


                var json = JsonConvert.SerializeObject(new GeneralStringReturn { Message = "Unable to complete diagram sharing" });
                return new JsonStringResult(json);
            }
        }




        public IActionResult GetPartial()
        {
            List<string> countries = new List<string>();
            countries.Add("USA");
            countries.Add("UK");
            countries.Add("India");

            return PartialView("TempPartial", countries);
        }



        //var jsonData = [
        //                                    {
        //                                        id: 1,
        //                                      text: "Folder 1",
        //                                      type: "root",
        //                                      state: {

        //                                          selected: false
        //                                        },
        //                                        children: [
        //                                            {
        //                                                id: 2,
        //                                                text: "Sub Folder 1",
        //                                                type: "child",
        //                                                state: {
        //                                                    selected: false
        //                                                },
        //                                            },
        //                                            {
        //                                                id: 3,
        //                                                text: "Sub Folder 2",
        //                                                type: "child",
        //                                                state: {
        //                                                    selected: false
        //                                                },
        //                                            }
        //                                        ]
        //                                    },
        //                                    {
        //                                        id: 4,
        //                                        text: "Folder 2",
        //                                        type: "root",
        //                                        state: {
        //                                            selected: true
        //                                        },
        //                                        children: []
        //                                    }
        //                                ];


    }

    public class FrameworkTree
    {

        public string id { get; set; }
        public string text { get; set; }
        public string type { get; set; }
        public string state { get; set; }
        public List<FrameworkTree> children { get; set; }

        public FrameworkTree()
        {
            this.children = new List<FrameworkTree>();
        }
    }


    public class DesignerTree
    {

        public string id { get; set; }
        public string text { get; set; }
        public string parent { get; set; }

        public int folderLevel { get; set; }
        public string type { get; set; }

        public int topmost { get; set; }

        public string parentText { get; set; }


    }

    public class EditorUIXML
    {

        public string XMLData { get; set; }

    }

    public class FileInformation
    {

        public string FileName { get; set; }
        public long FileSize { get; set; }

        public string XMLData { get; set; }


    }






}
