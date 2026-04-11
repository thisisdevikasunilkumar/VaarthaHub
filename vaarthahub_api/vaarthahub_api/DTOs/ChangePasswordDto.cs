namespace vaarthahub_api.DTOs
{
    public class ChangePasswordDto
    {
        public string UserCode { get; set; } = string.Empty;
        public string OldPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}