using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Tbl_ErrorLog:IDisposable
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Logid { get; set; }
        public string Logdescription { get; set; }
        public string Userid { get; set; }
        public DateTime TransactionTime { get; set; }
        public string FormName { get; set; }
        public string ProcedureName { get; set; }

        public void Dispose()
        {
            GC.Collect();
        }
    }
}
