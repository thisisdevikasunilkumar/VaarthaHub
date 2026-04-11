using System.ComponentModel.DataAnnotations;

namespace vaarthahub_api.DTOs
{
    public class DeliveryRatingDto
    {
        [Required]
        public required string PartnerCode { get; set; }

        [Required]
        public required string ReaderCode { get; set; }

        [Required]
        [Range(1, 5)]
        public byte RatingValue { get; set; }

        public List<string>? FeedbackTags { get; set; }

        public string? Comments { get; set; }
    }
}