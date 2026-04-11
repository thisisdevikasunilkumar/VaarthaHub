namespace vaarthahub_api.DTOs
{
    public class RegistrationDto
    {
        public string FullName { get; set; } = string.Empty;

        public string PhoneNumber { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public string Password { get; set; } = string.Empty;

        public string Role { get; set; } = string.Empty;

        public string? ProfileImage { get; set; } // Received as Base64 string
    }
}