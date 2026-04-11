using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class SwapRequest
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int SwapId { get; set; }
        
        [ForeignKey("Reader")]
        public int RequestReaderId { get; set; }

        [ForeignKey("Reader")]
        public int ReceiverReaderId { get; set; }

        [Required]
        public string OfferedMagazine { get; set; } = string.Empty;

        public string? IssueEdition { get; set; }

        [Required]
        public string RequestedMagazine { get; set; } = string.Empty;
        
        public string? Category { get; set; }
        public string? Condition { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal MagazinePrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal RequestedMagazinePrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal ServiceFee_Requestor { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal ServiceFee_Receiver { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal TotalServiceFee { get; set; }

        public string? AcceptedByPartnerCode { get; set; }

        // 'Requested', 'Pending', 'Completed'
        public string Status { get; set; } = "Requested";

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? CompletedAt { get; set; }
    }
}
