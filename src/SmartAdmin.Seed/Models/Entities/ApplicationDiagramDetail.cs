using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{

    public class ApplicationDiagramDetail
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ApplicationDiagramDetailId { get; set; }
        public int DiagramId { get; set; }
    
        public Guid SharedWithId { get; set; }

        public int SharedApplicationId { get; set; }

        public int CompanyId { get; set; }
    }
}
