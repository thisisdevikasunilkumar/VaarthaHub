using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class DeliveryPartner
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int DeliveryPartnerId { get; set; }

#pragma warning disable CS8618 // Non-nullable property is uninitialized
        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public string PartnerCode { get; private set; }
#pragma warning restore CS8618

        public string Role { get; set; } = "DeliveryPartner";
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string VehicleType { get; set; } = string.Empty;
        public string VehicleNumber { get; set; } = string.Empty;
        public string LicenseNumber { get; set; } = string.Empty;
        public string PanchayatName { get; set; } = string.Empty;

        [Column(TypeName = "decimal(10, 2)")]
        public decimal BasicSalary { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}