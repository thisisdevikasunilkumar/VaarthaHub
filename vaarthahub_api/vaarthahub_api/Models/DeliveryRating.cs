using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class DeliveryRating
    {
        [Key]
        public int RatingId { get; set; }

        [Required]
        [ForeignKey("DeliveryPartner")]
        public int DeliveryPartnerId { get; set; }

        [Required]
        [ForeignKey("Reader")]
        public int ReaderId { get; set; }

        [Required]
        public byte RatingValue { get; set; } // TINYINT in SQL

        public string? FeedbackTags { get; set; } // Stores comma separated strings

        public string? Comments { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}