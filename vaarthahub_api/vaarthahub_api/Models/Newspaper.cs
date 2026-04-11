using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Newspaper
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int NewspaperId { get; set; }

        public int ItemId { get; set; } = 1;

        public string ItemType { get; set; } = "Newspaper";

        public string Name { get; set; } = string.Empty;

        public string Category { get; set; } = string.Empty;

        public string PaperType { get; set; } = string.Empty;

        [Column(TypeName = "decimal(6, 2)")]
        public decimal BasePrice { get; set; }

        public string? LogoUrl { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
