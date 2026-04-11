namespace vaarthahub_api.DTOs
{
    public class ReaderDto
    {
        public string Role { get; set; } = "Reader";
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string PanchayatName { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? WardNumber { get; set; }
        public string AddedByPartnerCode { get; set; } = string.Empty;
    }
}