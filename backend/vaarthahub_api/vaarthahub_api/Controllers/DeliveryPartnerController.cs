using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.DTOs;
using vaarthahub_api.Models;
using vaarthahub_api.Services;

namespace vaarthahub_api.Controllers
{
    // api url: /api/DeliveryPartner/ - base route for this controller
    [Route("api/[controller]")]
    [ApiController]
    public class DeliveryPartnerController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ISmsService _smsService;

        public DeliveryPartnerController(ApplicationDbContext context, ISmsService smsService)
        {
            _context = context;
            _smsService = smsService;
        }

        // GET: api/DeliveryPartner/GetDeliveryPartnerProfile/{partnerCode}
        [HttpGet("GetDeliveryPartnerProfile/{partnerCode}")]
        public async Task<IActionResult> GetDeliveryPartnerProfile(string partnerCode) // Method name maatti
        {
            try
            {
                // 1. First, Partner details fetch cheyyunnu
                var partnerData = await (from partner in _context.DeliveryPartner
                                         join reg in _context.Registration
                                         on partner.PhoneNumber equals reg.PhoneNumber
                                         where partner.PartnerCode == partnerCode
                                         select new
                                         {
                                             partner.DeliveryPartnerId, // Rating edukkan ID venam
                                             partner.PartnerCode,
                                             reg.UserCode,
                                             partner.FullName,
                                             partner.PhoneNumber,
                                             reg.Email,
                                             partner.VehicleType,
                                             partner.VehicleNumber,
                                             partner.LicenseNumber,
                                             partner.PanchayatName,
                                             partner.Role,
                                             reg.PasswordUpdatedAt,
                                             ProfileImage = reg.ProfileImage != null
                                                            ? Convert.ToBase64String(reg.ProfileImage)
                                                            : null
                                         }).FirstOrDefaultAsync();

                if (partnerData == null)
                {
                    return NotFound(new { status = "Error", message = "Delivery Partner not found." });
                }

                // 2. Rating calculate cheyyunnu (DeliveryRating table-il ninnu)
                var ratings = await _context.DeliveryRating
                    .Where(r => r.DeliveryPartnerId == partnerData.DeliveryPartnerId)
                    .Select(r => (double)r.RatingValue)
                    .ToListAsync();

                double averageRating = ratings.Any() ? ratings.Average() : 0.0;

                // 3. Final result koodi averageRating add cheythu return cheyyunnu
                var result = new
                {
                    partnerData.PartnerCode,
                    partnerData.UserCode,
                    partnerData.FullName,
                    partnerData.PhoneNumber,
                    partnerData.Email,
                    partnerData.VehicleType,
                    partnerData.VehicleNumber,
                    partnerData.LicenseNumber,
                    partnerData.PanchayatName,
                    partnerData.Role,
                    partnerData.PasswordUpdatedAt,
                    partnerData.ProfileImage,
                    averageRating = Math.Round(averageRating, 1) // Rounding to 1 decimal point
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // PUT: api/DeliveryPartner/UpdateDeliveryPartnerProfile/{partnerCode}
        [HttpPut("UpdateDeliveryPartnerProfile/{partnerCode}")]
        public async Task<IActionResult> UpdateDeliveryPartnerProfile(string partnerCode, [FromBody] UpdateDeliveryPartnerDto dto)
        {
            var partner = await _context.DeliveryPartner.FirstOrDefaultAsync(p => p.PartnerCode == partnerCode);
            if (partner == null) return NotFound(new { message = "Delivery Partner not found." });

            var reg = await _context.Registration.FirstOrDefaultAsync(r => r.UserCode == partnerCode);
            if (reg == null) return NotFound(new { message = "Registration record not found." });

            // Update main details in DeliveryPartner table
            partner.FullName = dto.FullName;
            partner.PhoneNumber = dto.PhoneNumber;
            partner.VehicleType = dto.VehicleType;
            partner.VehicleNumber = dto.VehicleNumber;
            partner.LicenseNumber = dto.LicenseNumber;
            partner.PanchayatName = dto.PanchayatName;

            // Update details in Registration table (for login)
            reg.FullName = dto.FullName;
            reg.PhoneNumber = dto.PhoneNumber;
            reg.Email = dto.Email;

            if (!string.IsNullOrWhiteSpace(dto.ProfileImageBase64))
            {
                try
                {
                    reg.ProfileImage = Convert.FromBase64String(dto.ProfileImageBase64);
                }
                catch
                {
                    // ignore invalid base64 and keep existing image
                }
            }

            try
            {
                await _context.SaveChangesAsync();
                return Ok(new { status = "Success", message = "Profile updated successfully!" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // 1. Get unique Panchayat names (GET method)
        [HttpGet("GetPanchayatName")]
        public async Task<IActionResult> GetUniquePanchayats()
        {
            try
            {
                var panchayats = await _context.DeliveryPartner
                    .Select(p => p.PanchayatName)
                    .Distinct()
                    .ToListAsync();

                return Ok(panchayats);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        // 2. Get all readers (GET method)
        [HttpGet("GetReaders")]
        public async Task<IActionResult> GetReaders()
        {
            try
            {
                var readers = await _context.Reader
                    .Select(r => new
                    {
                        r.ReaderId,
                        r.FullName,
                        r.PhoneNumber,
                        r.PanchayatName,
                        r.Address,
                        r.WardNumber,
                        r.CreatedAt
                    })
                    .ToListAsync();

                return Ok(readers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // 3. Add a new reader (POST method)
        [HttpPost("AddReader")]
        public async Task<IActionResult> AddReader([FromBody] ReaderDto readerDto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var reader = new Reader
                {
                    FullName = readerDto.FullName,
                    PhoneNumber = readerDto.PhoneNumber,
                    PanchayatName = readerDto.PanchayatName,
                    Role = readerDto.Role ?? "Reader",
                    Address = readerDto.Address ?? string.Empty,
                    WardNumber = readerDto.WardNumber ?? string.Empty,
                    AddedByPartnerCode = readerDto.AddedByPartnerCode,
                    CreatedAt = DateTime.Now
                };

                _context.Reader.Add(reader);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                try
                {
                    await _smsService.SendAddReaderSmsAsync(reader.PhoneNumber, reader.FullName);
                }
                catch { /* ignore SMS errors */ }

                return Ok(new { message = "Reader registration successful!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }
    }
}