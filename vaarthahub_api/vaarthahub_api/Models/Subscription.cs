using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Subscription
    {
        [Key]
        public int SubscriptionId { get; set; }

        [Required]
        public int ReaderId { get; set; }

        [Required]
        public int ItemId { get; set; } // Stores 1 for Newspaper, 2 for Magazine (as requested)

        [Required]
        public int PublicationId { get; set; } // Stores the actual NewspaperId or MagazineId

        [Required]
        public string ItemType { get; set; } // 'Newspaper' or 'Magazine'

        public string SubscriptionName { get; set; } = string.Empty;

        public string Category { get; set; }

        public int DurationMonths { get; set; }

        [Column(TypeName = "decimal(18, 2)")]
        public decimal TotalAmount { get; set; }

        [Required]
        public DateTime StartDate { get; set; }

        [Required]
        public DateTime EndDate { get; set; }

        public bool IsVacationMode { get; set; } = false;

        [Required]
        public string IsActive { get; set; } = "Active"; // 'Active', 'Expired', 'Cancelled', 'Vacation'

        public string DeliverySlot { get; set; } // stores PaperType or PublicationCycle

        // Navigation Properties
        [ForeignKey("ReaderId")]
        public virtual Reader? Reader { get; set; }
    }
}
