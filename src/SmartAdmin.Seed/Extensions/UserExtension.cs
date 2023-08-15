using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SmartAdmin.Seed.Data;
using SmartAdmin.Seed.Models;
using SmartAdmin.Seed.Models.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Extensions
{
    public static class UserExtension
    {
       
        public static async  Task<string> GetUserId(UserManager<ApplicationUser> userManager, Microsoft.AspNetCore.Http.HttpContext context)
        {
            var user = await userManager.GetUserAsync(context.User);
            return user.Id;
        }
    }
    public static class ErrorLogExtension
    {
        public static void RecordErrorLog(string logdescription,string procedureName, string formName, string userid, ApplicationDbContext _context)
        {

           
            _context.Database.ExecuteSqlRaw("Insert into Tbl_ErrorLog(Logdescription,Userid,TransactionTime,FormName,ProcedureName) Values({0},{1},{2},{3},{4})", logdescription, userid, DateTime.Now, formName, procedureName);

        }
        public static void RecordErrorLogException(Exception logdescription, string procedureName, string formName, string userid, ApplicationDbContext _context)
        {
            var log_desc = "";
            if (logdescription.InnerException == null)
            {
                log_desc = "unable to process " + formName;
            }
            else
                log_desc = logdescription.InnerException.Message.ToString();

            _context.Database.ExecuteSqlRaw("Insert into Tbl_ErrorLog(Logdescription,Userid,TransactionTime,FormName,ProcedureName) Values({0},{1},{2},{3},{4})", log_desc, userid, DateTime.Now, formName, procedureName);
           

            
        }
    }
}
