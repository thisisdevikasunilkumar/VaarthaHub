namespace vaarthahub_api.DTOs
{
    public class DeliveryPartnerDto
    {
        public string Role { get; set; } = "DeliveryPartner";
        public string FullName { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string VehicleType { get; set; } = string.Empty;
        public string VehicleNumber { get; set; } = string.Empty;
        public string LicenseNumber { get; set; } = string.Empty;
        public string PanchayatName { get; set; } = string.Empty;
        public decimal BasicSalary { get; set; }
    }
}