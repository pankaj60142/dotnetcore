using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{

    public class tblApplicationDesignerDiagram
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int DiagramId { get; set; }
        public int DesignerTreeId { get; set; }
        public string DiagramXML { get; set; }
        public Guid OwnerId { get; set; }

        public string FileName { get; set; }

        public int CompanyId { get; set; }

        public bool IsTemplate { get; set; }



    }
}

