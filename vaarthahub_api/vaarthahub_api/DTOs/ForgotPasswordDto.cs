namespace vaarthahub_api.DTOs
{
    public class ForgotPasswordDto
    {
        public string EmailOrPhone { get; set; } = string.Empty;
        public string Method { get; set; } = string.Empty; // "SMS" or "Email"
    }
}