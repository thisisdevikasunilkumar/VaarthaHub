namespace vaarthahub_api.DTOs
{
    public class ReaderDto
    {
        public string Role { get; set; } = "Reader";
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string? HouseName { get; set; }
        public string? HouseNo { get; set; }
        public string? Landmark { get; set; }
        public string PanchayatName { get; set; } = string.Empty;
        public string? WardNumber { get; set; }
        public string? Pincode { get; set; }
        public string AddedByPartnerCode { get; set; } = string.Empty;
    }
}