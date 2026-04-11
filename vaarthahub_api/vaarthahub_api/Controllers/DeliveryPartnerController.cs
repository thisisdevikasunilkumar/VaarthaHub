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

        // 1. Get delivery partner profile with average rating (GET method)
        [HttpGet("GetDeliveryPartnerProfile/{partnerCode}")]
        public async Task<IActionResult> GetDeliveryPartnerProfile(string partnerCode)
        {
            try
            {
                // 1. First, Partner details fetch 
                var partnerData = await (from partner in _context.DeliveryPartner
                                         join reg in _context.Registration
                                         on partner.PhoneNumber equals reg.PhoneNumber
                                         where partner.PartnerCode == partnerCode
                                         select new
                                         {
                                             partner.DeliveryPartnerId,
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

                // 2. Rating calculate 
                var ratings = await _context.DeliveryRating
                    .Where(r => r.DeliveryPartnerId == partnerData.DeliveryPartnerId)
                    .Select(r => (double)r.RatingValue)
                    .ToListAsync();

                double averageRating = ratings.Any() ? ratings.Average() : 0.0;

                // 3. Final result
                var result = new
                {
                    partnerData.DeliveryPartnerId,
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
                    averageRating = Math.Round(averageRating, 1) 
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // 2. Update profile details in both DeliveryPartner and Registration tables (PUT method)
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

        // 3. Get all unique Panchayat names (GET method)
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

        // 4. Get list of all registered readers (GET method)
        [HttpGet("GetMyReaders/{partnerCode}")]
        public async Task<IActionResult> GetMyReaders(string partnerCode)
        {
            try
            {
                var readers = await _context.Reader
                    .Where(r => r.AddedByPartnerCode == partnerCode)
                    .OrderByDescending(r => r.CreatedAt)
                    .Select(r => new
                    {
                        r.ReaderId,
                        r.ReaderCode,
                        r.FullName,
                        r.PhoneNumber,
                        r.HouseName,
                        r.HouseNo,
                        r.Landmark,
                        r.PanchayatName,
                        r.WardNumber,
                        r.Pincode,
                        r.CreatedAt
                    })
                    .ToListAsync();

                return Ok(readers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = $"Internal server error: {ex.Message}" });
            }
        }

        [HttpGet("GetVacationModeDashboard/{partnerCode}")]
        public async Task<IActionResult> GetVacationModeDashboard(string partnerCode)
        {
            try
            {
                var readerIds = await _context.Reader
                    .Where(r => r.AddedByPartnerCode == partnerCode)
                    .Select(r => r.ReaderId)
                    .ToListAsync();

                if (!readerIds.Any())
                {
                    return Ok(new
                    {
                        readersOnVacationCount = 0,
                        papersSavedTodayCount = 0,
                        currentlyOnVacationCount = 0,
                        currentlyOnVacation = Array.Empty<object>(),
                        upcomingVacations = Array.Empty<object>()
                    });
                }

                var today = DateTime.UtcNow.Date;

                var vacationEntries = await _context.VacationRequests
                    .Where(v => v.IsActive && readerIds.Contains(v.ReaderId))
                    .Select(v => new
                    {
                        ReaderId = v.ReaderId,
                        ReaderName = v.Reader != null ? v.Reader.FullName : string.Empty,
                        HouseName = v.Reader != null ? v.Reader.HouseName : string.Empty,
                        HouseNo = v.Reader != null ? v.Reader.HouseNo : string.Empty,
                        StartDate = v.StartDate,
                        EndDate = v.EndDate,
                        Landmark = v.Reader != null ? v.Reader.Landmark : string.Empty,
                        PanchayatName = v.Reader != null ? v.Reader.PanchayatName : string.Empty,
                        WardNumber = v.Reader != null ? v.Reader.WardNumber : string.Empty,
                        Pincode = v.Reader != null ? v.Reader.Pincode : string.Empty,
                        PublicationName = !string.IsNullOrEmpty(v.Subscription!.SubscriptionName)
                            ? v.Subscription.SubscriptionName
                            : (v.Subscription.ItemType == "Newspaper"
                                ? _context.Newspapers
                                    .Where(n => n.NewspaperId == v.Subscription.PublicationId)
                                    .Select(n => n.Name)
                                    .FirstOrDefault() ?? v.Name
                                : _context.Magazines
                                    .Where(m => m.MagazineId == v.Subscription.PublicationId)
                                    .Select(m => m.Name)
                                    .FirstOrDefault() ?? v.Name)
                    })
                    .ToListAsync();

                var normalizedEntries = vacationEntries
                    .Select(v => (
                        ReaderId: v.ReaderId,
                        ReaderName: v.ReaderName,
                        HouseName: v.HouseName,
                        HouseNo: v.HouseNo,
                        StartDate: v.StartDate,
                        EndDate: v.EndDate,
                        Landmark: v.Landmark,
                        PanchayatName: v.PanchayatName,
                        WardNumber: v.WardNumber,
                        Pincode: v.Pincode,
                        PublicationName: v.PublicationName
                    ))
                    .ToList();

                var activeEntries = normalizedEntries
                    .Where(v => v.StartDate.Date <= today && (!v.EndDate.HasValue || v.EndDate.Value.Date >= today))
                    .ToList();

                var upcomingEntries = normalizedEntries
                    .Where(v => v.StartDate.Date > today)
                    .ToList();

                static object MapVacationReader(IGrouping<int, (int ReaderId, string ReaderName, string? HouseName, string? HouseNo, DateTime StartDate, DateTime? EndDate, string? Landmark, string? PanchayatName, string? WardNumber, string? Pincode, string PublicationName)> groupedEntries)
                {
                    var first = groupedEntries.First();
                    var houseLabel = $"{first.HouseName}, {first.HouseNo}, {first.Landmark}, {first.PanchayatName}, Ward {first.WardNumber}, {first.Pincode}";

                    return new
                    {
                        readerId = first.ReaderId,
                        readerName = string.IsNullOrWhiteSpace(first.ReaderName) ? "Reader" : first.ReaderName,
                        houseLabel = houseLabel,
                        startDate = groupedEntries.Min(x => (DateTime?)x.StartDate),
                        endDate = groupedEntries.Max(x => x.EndDate),
                        publicationNames = groupedEntries
                            .Select(x => (string?)x.PublicationName)
                            .Where(name => !string.IsNullOrWhiteSpace(name))
                            .Select(name => name!.Trim())
                            .Distinct()
                            .OrderBy(name => name)
                            .ToList()
                    };
                }

                var currentlyOnVacation = activeEntries
                    .GroupBy(v => v.ReaderId)
                    .Select(MapVacationReader)
                    .ToList();

                var upcomingVacations = upcomingEntries
                    .GroupBy(v => v.ReaderId)
                    .Select(MapVacationReader)
                    .ToList();

                return Ok(new
                {
                    readersOnVacationCount = currentlyOnVacation.Count,
                    papersSavedTodayCount = activeEntries.Count,
                    currentlyOnVacationCount = currentlyOnVacation.Count,
                    currentlyOnVacation,
                    upcomingVacations
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = $"Internal server error: {ex.Message}" });
            }
        }

        // 5. Register a new reader and send confirmation SMS (POST method)
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
