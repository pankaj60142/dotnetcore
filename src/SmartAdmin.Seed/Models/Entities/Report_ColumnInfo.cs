using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class Report_ColumnInfo
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ColumnId { get; set; }
        public string SqlTableName { get; set; }

        
        public string SqlColumnName { get; set; }
        public string MappedColumnName { get; set; }


        public string ColumnType { get; set; }

        

    }


}
