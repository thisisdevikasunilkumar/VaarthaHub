using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class VacationRequest
    {
        [Key]
        public int RequestId { get; set; }

        [Required]
        public int ReaderId { get; set; }

        [Required]
        public int SubscriptionId { get; set; }

        public string Category { get; set; } = string.Empty;

        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required]
        public DateTime StartDate { get; set; }

        public DateTime? EndDate { get; set; }

        [Column(TypeName = "decimal(18, 2)")]
        public decimal TotalAmount { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation Properties
        [ForeignKey("ReaderId")]
        public virtual Reader? Reader { get; set; }

        [ForeignKey("SubscriptionId")]
        public virtual Subscription? Subscription { get; set; }
    }
}
