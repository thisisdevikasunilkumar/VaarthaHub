namespace vaarthahub_api.DTOs
{
    public class VerifyOtpDto
    {
        public string EmailOrPhone { get; set; } = string.Empty;
        public string Otp { get; set; } = string.Empty;
    }
}