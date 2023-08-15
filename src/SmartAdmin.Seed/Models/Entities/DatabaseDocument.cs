using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Threading.Tasks;

namespace SmartAdmin.Seed.Models.Entities
{
    public class DatabaseDocument
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int DatabaseDocumentID { get; set; }
        public int DatabaseID { get; set; }
        public int DocumentID { get; set; }
    }
}
