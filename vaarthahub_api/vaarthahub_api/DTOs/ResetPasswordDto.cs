namespace vaarthahub_api.DTOs
{
    public class ResetPasswordDto
    {
        public string EmailOrPhone { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}