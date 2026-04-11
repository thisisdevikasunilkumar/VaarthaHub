namespace vaarthahub_api.DTOs
{
    public class UpdateReaderDto
    {
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string PanchayatName { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? WardNumber { get; set; }
        public string? ProfileImageBase64 { get; set; }
    }
}
