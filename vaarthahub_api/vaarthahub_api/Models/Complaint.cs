using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Complaint
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ComplaintId { get; set; }

        public int ReaderId { get; set; }

        public int DeliveryPartnerId { get; set; }

        public string ComplaintType { get; set; } = string.Empty;

        public string? Comments { get; set; }

        public string Status { get; set; } = "Open";

        public DateTime CreatedAt { get; set; } = DateTime.Now;

        [ForeignKey("ReaderId")]
        public virtual Reader? Reader { get; set; }

        [ForeignKey("DeliveryPartnerId")]
        public virtual DeliveryPartner? DeliveryPartner { get; set; }
    }
}
