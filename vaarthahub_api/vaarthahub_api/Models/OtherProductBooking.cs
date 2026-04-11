using System.ComponentModel.DataAnnotations;

namespace vaarthahub_api.Models
{
    public class OtherProductBooking
    {
        [Key]
        public int BookingId { get; set; }
        public int ReaderId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal TotalAmount { get; set; }
        public DateTime BookingDate { get; set; }
        public string Status { get; set; } = "Pending";
        public string? AssignedPartnerCode { get; set; }
        public int? DeliveryRating { get; set; }
        public string? DeliveryComments { get; set; }
        public DateTime? ShippedDate { get; set; }
        public DateTime? DeliveredDate { get; set; }
    }
}