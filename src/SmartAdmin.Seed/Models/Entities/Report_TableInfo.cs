using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Report_TableInfo
    {
        [Key]
               public string SqlTableName { get; set; }
        public string MappedTableName { get; set; }
      
    }


}
