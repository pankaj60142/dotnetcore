using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using SmartAdmin.Seed.Data;
using Newtonsoft.Json;
using Microsoft.EntityFrameworkCore;
using System.Xml.Serialization;
using SmartAdmin.Seed.Models.Entities;
using SmartAdmin.Seed.Extensions;

namespace SmartAdmin.Seed.Controllers
{
    public class ReportsController : Controller
    {
        private readonly ApplicationDbContext _context;
        public ReportsController(ApplicationDbContext context)
        {
            _context = context;
        }
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult SqlColumnMappings()
        {
            return View();
        }

        public IActionResult ReportDesigner()
        {
            return View();
        }



        [HttpPost]
        public JsonStringResult GetAllTablesFromEntityFramework()
        {
            try
            {

                var tableNames = _context.Model.GetEntityTypes()
    .Select(t => t.GetTableName())
    .Distinct()
    .ToList();



                var json = JsonConvert.SerializeObject(tableNames);
                return new JsonStringResult(json);
            }
            catch (Exception)
            {

                return new JsonStringResult("[]");
            }

        }

        [HttpPost]
        public ActionResult SaveMapping(string tablename, string columnvalues)
        {
            StringResultAsJSON res = new StringResultAsJSON();
            string json = "";
            try
            {


                List<Report_ColumnInfo> columns = JsonConvert.DeserializeObject<List<Report_ColumnInfo>>(columnvalues);
                if (columns == null)
                {
                    res.Message = "error";

                    json = JsonConvert.SerializeObject(res);
                    res = null;
                    return new JsonStringResult(json);
                }
                if (columns.Count() == 0)
                {
                    res.Message = "error";

                    json = JsonConvert.SerializeObject(res);
                    res = null;
                    return new JsonStringResult(json);

                }

                var tablemappednamefound = from t in _context.Report_TableInfo where t.SqlTableName == tablename select t;

                if (tablemappednamefound.Count() > 0)
                {
                    _context.Report_TableInfo.Remove(tablemappednamefound.FirstOrDefault());

                }

                Report_TableInfo tab = new Report_TableInfo();
                tab.SqlTableName = tablename;
                tab.MappedTableName = columns.FirstOrDefault().SqlTableName;
                _context.Report_TableInfo.Add(tab);


                var columnmappednamefound = from t in _context.Report_ColumnInfo where t.SqlTableName == tablename select t;
                if (columnmappednamefound == null || columnmappednamefound.Count() == 0)
                {

                }
                else
                {
                    _context.Report_ColumnInfo.RemoveRange(columnmappednamefound);
                }
                foreach (var c in columns)
                {
                    Report_ColumnInfo c1 = new Report_ColumnInfo();
                    c1.ColumnType = c.ColumnType;
                    c1.MappedColumnName = c.MappedColumnName;
                    c1.SqlColumnName = c.SqlColumnName;
                    c1.SqlTableName = tablename;

                    _context.Report_ColumnInfo.Add(c1);
                }

                _context.SaveChanges();


                res.Message = "success";

                json = JsonConvert.SerializeObject(res);
                res = null;
                return new JsonStringResult(json);
            }
            catch (Exception)
            {

                res.Message = "error";

                json = JsonConvert.SerializeObject(res);
                res = null;
                return new JsonStringResult(json);
            }
        }

        public JsonStringResult GetMappedTableName(string tablename)
        {
            StringResultAsJSON res = new StringResultAsJSON();
            string json = "";

            var tablemappednamefound = from t in _context.Report_TableInfo where t.SqlTableName == tablename select t;

            if (tablemappednamefound == null || tablemappednamefound.Count() == 0)
            {
                res.Message = "";

                json = JsonConvert.SerializeObject(res);
            }
            else
            {
                res.Message = tablemappednamefound.FirstOrDefault().MappedTableName;

                json = JsonConvert.SerializeObject(res);
            }

            res = null;
            return new JsonStringResult(json);
        }

        public JsonStringResult GetColumnNamesOfTable(string tablename)
        {
            try
            {

                var columnNames = _context.Model.GetEntityTypes()
   .Where(t => t.GetTableName() == tablename)
   .Select(c => c.GetProperties())
   .Distinct()
   .ToList();

                var getmappedcolumnnames = from c in _context.Report_ColumnInfo where c.SqlTableName == tablename select c;

                string mappedtablename = "";
                var tableinfo = from t in _context.Report_TableInfo
                                where t.SqlTableName == tablename
                                select t.MappedTableName;

                if (tablename.Count() > 0)
                {
                    mappedtablename = tableinfo.FirstOrDefault();
                }



                List<Report_ColumnInfo> columns = new List<Report_ColumnInfo>();

                // Column info 
                foreach (var property in columnNames.FirstOrDefault())
                {
                    Report_ColumnInfo c = new Report_ColumnInfo();
                    c.SqlTableName = tablename;
                    if (property.GetColumnType().Contains("varchar"))
                    {
                        c.ColumnType = "string";
                    }
                    else
                    {
                        c.ColumnType = property.GetColumnType();
                    }
                    if (getmappedcolumnnames.Where(x => x.SqlColumnName == property.GetColumnName()).FirstOrDefault() == null || getmappedcolumnnames.Where(x => x.SqlColumnName == property.GetColumnName()).Count() == 0)
                    {
                        c.MappedColumnName = "";
                    }
                    else
                    {
                        c.MappedColumnName = getmappedcolumnnames.Where(x => x.SqlColumnName == property.GetColumnName()).FirstOrDefault().MappedColumnName;
                    }
                    c.SqlColumnName = property.GetColumnName();


                    columns.Add(c);
                    c = null;

                }




                var json = JsonConvert.SerializeObject(columns);
                columns = null;
                return new JsonStringResult(json);
            }
            catch (Exception)
            {

                return new JsonStringResult("[]");
            }

        }

        public JsonStringResult GetALLMappedTables()
        {
            try
            {
                var tablemappednamefound = from t in _context.Report_TableInfo select t;


                var json = JsonConvert.SerializeObject(tablemappednamefound);
                return new JsonStringResult(json);
            }
            catch (Exception)
            {
                StringResultAsJSON res = new StringResultAsJSON();
                res.Message = "[]";

                var json = JsonConvert.SerializeObject(res);
                res = null;
                return new JsonStringResult(json);
            }


        }

        [Obsolete]
        public async Task<JsonStringResult> GetALLRelationships()
        {
            try
            {

                string json = "[]";

                List<object> objects = new List<object>();
                // Execute a query.
                using (var dr = await _context.Database.ExecuteSqlQueryAsync("SELECT f.name AS foreign_key_name ,OBJECT_NAME(f.parent_object_id) AS table_name,COL_NAME(fc.parent_object_id, fc.parent_column_id) AS constraint_column_name ,OBJECT_NAME (f.referenced_object_id) AS referenced_object  ,COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS referenced_column_name  FROM sys.foreign_keys AS f  INNER JOIN sys.foreign_key_columns AS fc      ON f.object_id = fc.constraint_object_id   "))
                {
                    // Output rows.
                    var reader = dr.DbDataReader;
                    while (reader.Read())
                    {

                        IDictionary<string, object> record = new Dictionary<string, object>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            record.Add(reader.GetName(i), reader[i]);
                        }

                        objects.Add(record);
                        // Console.Write("{0}\t{1}\t{2} \n", reader[0], reader[1], reader[2]);
                    }


                }



                json = JsonConvert.SerializeObject(objects, Formatting.Indented);

                return new JsonStringResult(json);
            }
            catch (Exception)
            {
                StringResultAsJSON res = new StringResultAsJSON();
                res.Message = "[]";

                var json = JsonConvert.SerializeObject(res);
                res = null;
                return new JsonStringResult(json);
            }


        }


        private string FindTableInRelation( ref string sql,string[] allrelations,string tabletocheck)
        {
          //  string result = "";
            foreach (string x in allrelations)
            {
                if (x.Contains(tabletocheck))
                {

                    if(x.Contains(","))
                    {
                        var result = x.Split(",");
                        foreach (var res in result)
                        {

                            var table = res.Split("=");

                            table[0] = table[0].Replace(")","");
                            table[0] = table[0].Replace("(", "");


                            table[1] = table[1].Replace(")", "");
                            table[1] = table[1].Replace("(", "");

                            if (sql.Contains(SubstringHelper.GetUntilOrEmpty(table[0],":")) && sql.Contains(SubstringHelper.GetUntilOrEmpty(table[1], ":")))
                            {
                                if(table[0].Contains(tabletocheck))
                                {
                                    sql = sql + " ON "+table[1].Replace(":",".")+" = "+table[0].Replace(":",".")+"";
                                }
                                else
                                {
                                    sql = sql + " ON " + table[0].Replace(":", ".") + " = " + table[1].Replace(":", ".") + "";
                                }
                            }

                           
                        }
                    }
                    else
                    {

                        var table = x.Split("=");

                        table[0] = table[0].Replace(")", "");
                        table[0] = table[0].Replace("(", "");


                        table[1] = table[1].Replace(")", "");
                        table[1] = table[1].Replace("(", "");

                        if (sql.Contains(SubstringHelper.GetUntilOrEmpty(table[0], ":")) && sql.Contains(SubstringHelper.GetUntilOrEmpty(table[1], ":")))
                        {
                            if (table[0].Contains(tabletocheck))
                            {
                                sql = sql + " ON " + table[1].Replace(":", ".") + " = " + table[0].Replace(":", ".") + "";
                            }
                            else
                            {
                                sql = sql + " ON " + table[0].Replace(":", ".") + " = " + table[1].Replace(":", ".") + "";
                            }
                        }

                    }
                   
                }
            }

            return sql;
        }


        private string CreateTablePriorityQuery(string[] array,string parenttablename,string[] arrrelations,ref string sql)
        {
            string result = "";
            foreach (string x in array)
            {
                if (x.Contains(parenttablename+"."))
                {
                    result =  x.Split(".")[1];

                    sql = sql + " left join " + result;
                    if (arrrelations != null)
                    {
                        FindTableInRelation(ref sql, arrrelations, result);
                    }
                    CreateTablePriorityQuery(array,result, arrrelations,ref sql);
                }
            }

            return sql;
        }

        [Obsolete]
        public async Task<JsonStringResult> GeneratePreview(string tablespriority, string generatedrelations,string mappedcolumnsname)
        {
            try
            {
                string[] tables = tablespriority.Split(',').ToArray();

                string sql = "";
                string[] relations=null;
                if (generatedrelations != null)
                 relations = generatedrelations.Split(';').ToArray();

                if (tables.Length>0)
                {

                    foreach (string x in tables)
                    {
                        if (x.Contains("."))
                        {
                           
                        }
                        else
                        {
                            if (sql == "")
                            {
                                sql = "Select * from " + x;
                            }
                            else
                            {
                                sql = sql + " Right join " + x;
                            }
                            var f = await Task.Run(() => CreateTablePriorityQuery(tables, x, relations, ref sql));
                        }
                    }
                }

                sql = sql.Replace("*", " " + mappedcolumnsname);
                string json = "[]";

                List<object> objects = new List<object>();
                // Execute a query.
                using (var dr = await _context.Database.ExecuteSqlQueryAsync(sql))
                {
                    // Output rows.
                    var reader = dr.DbDataReader;
                    while (reader.Read())
                    {

                        IDictionary<string, object> record = new Dictionary<string, object>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            try
                            {
                                record.Add(reader.GetName(i).Replace(".",":"), reader[i]);
                            }
                            catch (Exception exc)
                            {

                                var t = exc;
                            }
                          
                        }

                        objects.Add(record);
                        // Console.Write("{0}\t{1}\t{2} \n", reader[0], reader[1], reader[2]);
                    }


                }



                json = JsonConvert.SerializeObject(objects, Formatting.Indented);

                return new JsonStringResult(json);
            }
            catch (Exception)
            {
                StringResultAsJSON res = new StringResultAsJSON();
                res.Message = "[]";

                var json = JsonConvert.SerializeObject(res);
                res = null;
                return new JsonStringResult(json);
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

        public class ColumnData
        {
            public string ColumnName { get; set; }
            public string ColumnType { get; set; }

        }

      


        public static class SubstringHelper
        {
            public static string GetUntilOrEmpty(string text, string stopAt = "-")
            {
                if (!String.IsNullOrWhiteSpace(text))
                {
                    int charLocation = text.IndexOf(stopAt, StringComparison.Ordinal);

                    if (charLocation > 0)
                    {
                        return text.Substring(0, charLocation);
                    }
                }

                return String.Empty;
            }
        }




    }

}
