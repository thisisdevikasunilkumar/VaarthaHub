using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class SwapProposal
    {
        [Key]
        public int ProposalId { get; set; }

        [Required]
        public int SwapRequestId { get; set; }

        [Required]
        public int ReceiverReaderId { get; set; } // The person proposing the swap

        [Column(TypeName = "decimal(18,2)")]
        public decimal OfferedMagazinePrice { get; set; }

        [Required]
        public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected

        public DateTime CreatedAt { get; set; }
    }
}
