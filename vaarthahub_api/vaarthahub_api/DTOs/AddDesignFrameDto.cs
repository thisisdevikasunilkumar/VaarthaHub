using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace vaarthahub_api.DTOs
{
    public class AddDesignFrameDto
    {
        [Required]
        public string Category { get; set; } = string.Empty;

        [Required]
        public string FrameName { get; set; } = string.Empty;

        [Required]
        public string CardType { get; set; } = string.Empty;

        [Required]
        public IFormFile? Image { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "Price must be zero or greater.")]
        public decimal Price { get; set; }

        public bool IsActive { get; set; } = true; 
    }
}
