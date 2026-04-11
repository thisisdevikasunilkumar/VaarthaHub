using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace vaarthahub_api.Models
{
    public class Registration
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int UserId { get; set; }

        public string UserCode { get; set; } = string.Empty; // PartnerCode/ReaderCode
        [Required]
        [RegularExpression("^(Reader|DeliveryPartner)$", ErrorMessage = "Role must be 'Reader' or 'DeliveryPartner'")]
        public string Role { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        public string PhoneNumber { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public byte[]? ProfileImage { get; set; }

        [Required]
        public string PasswordHash { get; set; } = string.Empty;
        public DateTime? PasswordUpdatedAt { get; set; }

        public DateTime JoinDate { get; set; } = DateTime.Now;

        public bool IsActive { get; set; } = true;
    }
}