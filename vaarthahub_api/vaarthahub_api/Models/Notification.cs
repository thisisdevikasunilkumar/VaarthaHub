using System.ComponentModel.DataAnnotations;

namespace vaarthahub_api.Models
{
    public class Notification
    {
        [Key]
        public int NotificationId { get; set; }

        [Required]
        public string UserCode { get; set; } = string.Empty; // ReaderCode or PartnerCode

        [Required]
        public string Title { get; set; } = string.Empty;

        [Required]
        public string Message { get; set; } = string.Empty;

        public int? RelatedId { get; set; } // e.g. SwapId

        [Required]
        public string Type { get; set; } = "General"; // SwapProposal, SwapAccepted, SwapCompleted, General

        public bool IsRead { get; set; } = false;

        public DateTime CreatedAt { get; set; }
    }
}
