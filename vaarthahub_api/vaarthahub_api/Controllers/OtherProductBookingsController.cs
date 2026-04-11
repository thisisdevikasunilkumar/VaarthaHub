using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OtherProductBookingsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public OtherProductBookingsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("AddBooking")]
        public async Task<IActionResult> AddBooking([FromBody] OtherProductBooking booking)
        {
            if (booking == null) return BadRequest("Invalid booking data.");

            try
            {
                booking.BookingDate = DateTime.Now;
                booking.Status = "Pending";

                _context.OtherProductBookings.Add(booking);
                await _context.SaveChangesAsync();

                // Get Product and Reader details for notification message
                var product = await _context.OtherProducts.FindAsync(booking.ProductId);
                var reader = await _context.Reader.FindAsync(booking.ReaderId);

                if (product != null && reader != null)
                {
                    string productName = product.Name;
                    string message = $"{reader.FullName} has booked {booking.Quantity} unit(s) of {productName}.";

                    // 1. Notify Delivery Partner
                    if (!string.IsNullOrEmpty(reader.AddedByPartnerCode))
                    {
                        var partnerNotification = new Notification
                        {
                            UserCode = reader.AddedByPartnerCode,
                            Title = "New Product Booking",
                            Message = message,
                            RelatedId = booking.BookingId,
                            Type = "ProductBookingPartner",
                            CreatedAt = DateTime.Now,
                            IsRead = false
                        };
                        _context.Notifications.Add(partnerNotification);
                    }

                    // 2. Notify Admin
                    var adminNotification = new Notification
                    {
                        UserCode = "Admin", // Assuming 'Admin' is the identifier for admin notifications
                        Title = "New Product Booking",
                        Message = message,
                        RelatedId = booking.BookingId,
                        Type = "ProductBookingAdmin",
                        CreatedAt = DateTime.Now,
                        IsRead = false
                    };
                    _context.Notifications.Add(adminNotification);

                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Booking successful!", bookingId = booking.BookingId });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("GetBookingsByReader/{readerId}")]
        public async Task<IActionResult> GetBookingsByReader(int readerId)
        {
            try
            {
                var bookings = await (from b in _context.OtherProductBookings
                                      join p in _context.OtherProducts on b.ProductId equals p.ProductId
                                      join dp in _context.DeliveryPartner on b.AssignedPartnerCode equals dp.PartnerCode into dpJoin
                                      from dp in dpJoin.DefaultIfEmpty()
                                      where b.ReaderId == readerId
                                      orderby b.BookingDate descending
                                      select new
                                      {
                                          bookingId = b.BookingId,
                                          productId = b.ProductId,
                                          itemType = p.ItemType,
                                          productName = p.Name,
                                          productType = p.ProductType,
                                          size = p.Size,
                                          year = p.Year,
                                          imageUrl = p.ImageUrl,
                                          quantity = b.Quantity,
                                          unitPrice = p.UnitPrice,
                                          totalAmount = b.TotalAmount,
                                          bookingDate = b.BookingDate,
                                          status = b.Status,
                                          assignedPartnerCode = b.AssignedPartnerCode,
                                          partnerName = dp != null ? dp.FullName : null,
                                          partnerPhone = dp != null ? dp.PhoneNumber : null,
                                          deliveryRating = b.DeliveryRating,
                                          deliveryComments = b.DeliveryComments,
                                          shippedDate = b.ShippedDate,
                                          deliveredDate = b.DeliveredDate
                                      }).ToListAsync();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("GetAdminBookings")]
        public async Task<IActionResult> GetAdminBookings()
        {
            try
            {
                var bookings = await (from b in _context.OtherProductBookings
                                      join r in _context.Reader on b.ReaderId equals r.ReaderId
                                      join p in _context.OtherProducts on b.ProductId equals p.ProductId
                                      orderby b.BookingDate descending
                                      select new
                                      {
                                          bookingId = b.BookingId,
                                          readerId = b.ReaderId,
                                          readerName = r.FullName,
                                          phoneNumber = r.PhoneNumber,
                                          houseName = r.HouseName,
                                          houseNo = r.HouseNo,
                                          landmark = r.Landmark,
                                          panchayatName = r.PanchayatName,
                                          wardNumber = r.WardNumber,
                                          pincode = r.Pincode,
                                          productId = b.ProductId,
                                          itemType = p.ItemType,
                                          productName = p.Name,
                                          productType = p.ProductType,
                                          size = p.Size,
                                          year = p.Year,
                                          imageUrl = p.ImageUrl,
                                          quantity = b.Quantity,
                                          unitPrice = p.UnitPrice,
                                          totalAmount = b.TotalAmount,
                                          bookingDate = b.BookingDate,
                                          status = b.Status,
                                          assignedPartnerCode = b.AssignedPartnerCode,
                                          deliveryRating = b.DeliveryRating,
                                          deliveryComments = b.DeliveryComments,
                                          shippedDate = b.ShippedDate,
                                          deliveredDate = b.DeliveredDate
                                      }).ToListAsync();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("AssignPartner")]
        public async Task<IActionResult> AssignPartner([FromBody] AssignPartnerDto dto)
        {
            try
            {
                var booking = await _context.OtherProductBookings.FindAsync(dto.BookingId);
                if (booking == null) return NotFound("Booking not found");

                booking.AssignedPartnerCode = dto.PartnerCode;
                booking.Status = "Shipped";
                booking.ShippedDate = DateTime.Now;

                await _context.SaveChangesAsync();

                // Fetch extra details for notifications
                var product = await _context.OtherProducts.FindAsync(booking.ProductId);
                var reader = await _context.Reader.FindAsync(booking.ReaderId);
                var partner = await _context.DeliveryPartner.FirstOrDefaultAsync(p => p.PartnerCode == dto.PartnerCode);

                if (product != null && reader != null)
                {
                    // 1. Notify Partner
                    var partnerNotification = new Notification
                    {
                        UserCode = dto.PartnerCode,
                        Title = "New Delivery Assigned",
                        Message = $"A new delivery for {product.Name} (Qty: {booking.Quantity}) has been assigned to you for Reader: {reader.FullName}.",
                        RelatedId = dto.BookingId,
                        Type = "DeliveryAssigned",
                        CreatedAt = DateTime.Now,
                        IsRead = false
                    };
                    _context.Notifications.Add(partnerNotification);

                    // 2. Notify Reader
                    var readerNotification = new Notification
                    {
                        UserCode = reader.ReaderCode,
                        Title = "Order Shipped",
                        Message = $"Your order for {product.Name} has been shipped. {(partner != null ? $"Partner {partner.FullName} ({partner.PhoneNumber}) will deliver it soon." : "A delivery partner will deliver it soon.")}",
                        RelatedId = booking.BookingId,
                        Type = "OrderShipped",
                        CreatedAt = DateTime.Now,
                        IsRead = false
                    };
                    _context.Notifications.Add(readerNotification);

                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Partner assigned and notifications sent!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("GetPartnerBookings/{partnerCode}")]
        public async Task<IActionResult> GetPartnerBookings(string partnerCode)
        {
            try
            {
                var bookings = await (from b in _context.OtherProductBookings
                                      join r in _context.Reader on b.ReaderId equals r.ReaderId
                                      join p in _context.OtherProducts on b.ProductId equals p.ProductId
                                      where b.AssignedPartnerCode == partnerCode
                                      orderby b.BookingDate descending
                                      select new
                                      {
                                          bookingId = b.BookingId,
                                          readerId = b.ReaderId,
                                          readerName = r.FullName,
                                          phoneNumber = r.PhoneNumber,
                                          houseName = r.HouseName,
                                          houseNo = r.HouseNo,
                                          landmark = r.Landmark,
                                          panchayatName = r.PanchayatName,
                                          wardNumber = r.WardNumber,
                                          pincode = r.Pincode,
                                          productId = b.ProductId,
                                          itemType = p.ItemType,
                                          productName = p.Name,
                                          productType = p.ProductType,
                                          size = p.Size,
                                          year = p.Year,
                                          imageUrl = p.ImageUrl,
                                          quantity = b.Quantity,
                                          unitPrice = p.UnitPrice,
                                          totalAmount = b.TotalAmount,
                                          bookingDate = b.BookingDate,
                                          status = b.Status,
                                          assignedPartnerCode = b.AssignedPartnerCode,
                                          deliveryRating = b.DeliveryRating,
                                          deliveryComments = b.DeliveryComments,
                                          shippedDate = b.ShippedDate,
                                          deliveredDate = b.DeliveredDate
                                      }).ToListAsync();

                return Ok(bookings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("UpdateStatus")]
        public async Task<IActionResult> UpdateStatus([FromBody] UpdateBookingStatusDto dto)
        {
            try
            {
                var booking = await _context.OtherProductBookings.FindAsync(dto.BookingId);
                if (booking == null) return NotFound("Booking not found");

                booking.Status = dto.Status;
                if (dto.Status == "Delivered")
                {
                    booking.DeliveredDate = DateTime.Now;
                }
                await _context.SaveChangesAsync();

                return Ok(new { message = $"Booking status updated to {dto.Status}!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("RateBooking")]
        public async Task<IActionResult> RateBooking([FromBody] RateOtherProductBookingDto dto)
        {
            try
            {
                var booking = await _context.OtherProductBookings.FindAsync(dto.BookingId);
                if (booking == null) return NotFound("Booking not found");

                booking.DeliveryRating = dto.Rating;
                booking.DeliveryComments = dto.Comments;

                await _context.SaveChangesAsync();

                return Ok(new { message = "Rating submitted successfully!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
