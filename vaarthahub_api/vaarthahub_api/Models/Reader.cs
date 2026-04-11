using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Reader
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int ReaderId { get; set; }

#pragma warning disable CS8618 // Non-nullable property is uninitialized
        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public string ReaderCode { get; private set; }
#pragma warning restore CS8618

        public string Role { get; set; } = "Reader";
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }

        // --- Detailed Address Fields ---
        public string? HouseName { get; set; }
        public string? HouseNo { get; set; }
        public string? Landmark { get; set; }
        public string PanchayatName { get; set; } = string.Empty;
        public string? WardNumber { get; set; }
        public string? Pincode { get; set; }

        [Required]
        public string AddedByPartnerCode { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.Now;
    }
}