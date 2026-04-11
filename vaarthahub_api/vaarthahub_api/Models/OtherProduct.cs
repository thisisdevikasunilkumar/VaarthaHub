using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class OtherProduct
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ProductId { get; set; }

        public int ItemId { get; set; }

        public string ItemType { get; set; } = string.Empty;

        public int NewspaperId { get; set; }

        public string Name { get; set; } = string.Empty;

        public string? ProductType { get; set; } // Stores "Calendar Type" or "Diary Type"

        public string? Size { get; set; }  // Specifically for Diaries

        public string Year { get; set; } = string.Empty;

        [Column(TypeName = "decimal(10, 2)")]
        public decimal UnitPrice { get; set; }

        public string? ImageUrl { get; set; }

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("NewspaperId")]
        public virtual Newspaper? Newspaper { get; set; }
    }
}
