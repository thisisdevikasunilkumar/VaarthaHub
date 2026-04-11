namespace vaarthahub_api.DTOs
{
    public class UpdateBookingStatusDto
    {
        public int BookingId { get; set; }
        public string Status { get; set; } = string.Empty;
    }
}
