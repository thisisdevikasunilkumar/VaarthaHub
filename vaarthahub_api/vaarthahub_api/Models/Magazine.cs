using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Magazine
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int MagazineId { get; set; }

        public int ItemId { get; set; } = 2;

        public string ItemType { get; set; } = "Magazine";

        public int NewspaperId { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Category { get; set; } = string.Empty;

        public string PublicationCycle { get; set; } = string.Empty;

        [Column(TypeName = "decimal(6, 2)")]
        public decimal Price { get; set; }

        public string? LogoUrl { get; set; }

        public bool IsActive { get; set; } = true;

        [ForeignKey("NewspaperId")]
        public virtual Newspaper? Newspaper { get; set; }
    }
}
