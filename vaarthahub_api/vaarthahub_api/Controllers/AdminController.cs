using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System.Runtime.Intrinsics.Arm;
using vaarthahub_api.Data;
using vaarthahub_api.DTOs;
using vaarthahub_api.Models;
using vaarthahub_api.Services;

namespace vaarthahub_api.Controllers
{
    // api url: /api/Admin/ - base route for this controller
    [Route("api/[controller]")]
    [ApiController]
    public class AdminController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ISmsService _smsService;

        public AdminController(ApplicationDbContext context, ISmsService smsService)
        {
            _context = context;
            _smsService = smsService;
        }

        // 0. Test API to verify if the Admin Controller is reachable
        // URL: https://localhost:7134/api/Admin/Test
        [HttpGet("Test")]
        public IActionResult GetTest()
        {
            return Ok("Admin Controller working fine!");
        }

        // 1. Fetch a list of all Delivery Partners with their current month's earnings and average ratings (GET method)
        [HttpGet("GetDeliveryPartners")]
        public async Task<IActionResult> GetDeliveryPartners()
        {
            try
            {
                var currentMonth = DateTime.Now.ToString("MMMM yyyy");

                // Join DeliveryPartner and Salary tables while calculating Average Rating via subquery
                var partners = await (from p in _context.DeliveryPartner
                                      join s in _context.DeliveryPartnerSalary
                                      on p.DeliveryPartnerId equals s.DeliveryPartnerId
                                      where s.MonthYear == currentMonth
                                      select new
                                      {
                                          p.DeliveryPartnerId,
                                          p.PartnerCode,
                                          p.FullName,
                                          p.PhoneNumber,
                                          p.PanchayatName,
                                          s.TotalMonthlyEarnings,
                                          p.CreatedAt,
                                          // Subquery to calculate the mean rating value for each partner
                                          AverageRating = _context.DeliveryRating
                                              .Where(r => r.DeliveryPartnerId == p.DeliveryPartnerId)
                                              .Select(r => (double?)r.RatingValue)
                                              .Average() ?? 0.0
                                      }).ToListAsync();

                // Format the final result and round the average rating to 1 decimal place
                var result = partners.Select(p => new
                {
                    p.DeliveryPartnerId,
                    p.PartnerCode,
                    p.FullName,
                    p.PhoneNumber,
                    p.PanchayatName,
                    p.TotalMonthlyEarnings,
                    p.CreatedAt,
                    AverageRating = Math.Round(p.AverageRating, 1)
                });

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // 2. Add a new Delivery Partner and initialize their salary record for the current month (POST method)
        [HttpPost("AddDeliveryPartner")]
        public async Task<IActionResult> AddDeliveryPartner([FromBody] DeliveryPartnerDto partnerDto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Save partner details to the DeliveryPartner table
                var partner = new DeliveryPartner
                {
                    FullName = partnerDto.FullName,
                    PhoneNumber = partnerDto.PhoneNumber,
                    VehicleType = partnerDto.VehicleType,
                    VehicleNumber = partnerDto.VehicleNumber,
                    LicenseNumber = partnerDto.LicenseNumber,
                    PanchayatName = partnerDto.PanchayatName,
                    BasicSalary = partnerDto.BasicSalary,
                    CreatedAt = DateTime.Now
                };

                _context.DeliveryPartner.Add(partner);
                await _context.SaveChangesAsync();

                // Initialize the salary record for the new partner
                var salary = new DeliveryPartnerSalary
                {
                    DeliveryPartnerId = partner.DeliveryPartnerId,
                    BasicSalary = partnerDto.BasicSalary,
                    TotalCommission = 0,
                    Incentive = 0,
                    MonthYear = DateTime.Now.ToString("MMMM yyyy"),
                    TotalMonthlyEarnings = partnerDto.BasicSalary, // Initial sum
                    BasicSalaryLastUpdate = DateTime.Now,
                    IncentiveLastUpdate = DateTime.Now
                };

                _context.DeliveryPartnerSalary.Add(salary);
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                // Send a welcome/confirmation SMS (Failures here will not affect the DB transaction)
                try
                {
                    await _smsService.SendAddDeliveryPartnerSmsAsync(partner.PhoneNumber, partner.FullName);
                }
                catch
                {
                    // Suppress SMS service errors
                }

                return Ok(new { message = "Partner added successfully!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }

        // 3. Delete a Delivery Partner and their associated salary records (DELETE method)
        [HttpDelete("DeletePartner/{id}")]
        public async Task<IActionResult> DeletePartner(int id)
        {
            try
            {
                var partner = await _context.DeliveryPartner.FindAsync(id);
                if (partner == null) return NotFound("Partner not found");

                // Cascade delete salary records manually
                var salaries = _context.DeliveryPartnerSalary.Where(s => s.DeliveryPartnerId == id);
                _context.DeliveryPartnerSalary.RemoveRange(salaries);

                _context.DeliveryPartner.Remove(partner);
                await _context.SaveChangesAsync();

                return Ok(new { message = "Partner removed successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        // 4. Fetch specific partner salary history and performance rating (GET method)
        [HttpGet("GetPartnerSalaryDetails/{id}")]
        public async Task<IActionResult> GetPartnerSalaryDetails(int id)
        {
            try
            {
                var partner = await _context.DeliveryPartner.FindAsync(id);
                if (partner == null) return NotFound("Partner not found");

                var ratings = await _context.DeliveryRating
                    .Where(r => r.DeliveryPartnerId == id)
                    .Select(r => (double)r.RatingValue)
                    .ToListAsync();

                var averageRating = ratings.Any() ? ratings.Average() : 0.0;
                var ratingCount = ratings.Count();

                var salaryHistory = await _context.DeliveryPartnerSalary
                    .Where(s => s.DeliveryPartnerId == id)
                    .OrderByDescending(s => s.SalaryId)
                    .Select(s => new DeliveryPartnerSalaryDto
                    {
                        DeliveryPartnerId = s.DeliveryPartnerId,
                        BasicSalary = s.BasicSalary,
                        TotalCommission = s.TotalCommission,
                        Incentive = s.Incentive,
                        MonthYear = s.MonthYear,
                        TotalMonthlyEarnings = s.TotalMonthlyEarnings,
                        BasicSalaryLastUpdate = s.BasicSalaryLastUpdate,
                        IncentiveLastUpdate = s.IncentiveLastUpdate,
                        AverageRating = Math.Round(averageRating, 1),
                        RatingCount = ratingCount
                    })
                    .ToListAsync();

                return Ok(new
                {
                    partnerName = partner.FullName,
                    averageRating = Math.Round(averageRating, 1),
                    ratingCount = ratingCount,
                    history = salaryHistory
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // 5. Update basic salary or incentives for the current month (PUT method)
        [HttpPut("UpdatePartnerSalary")]
        public async Task<IActionResult> UpdatePartnerSalary([FromBody] DeliveryPartnerSalaryDto updateDto)
        {
            try
            {
                var currentMonth = DateTime.Now.ToString("MMMM yyyy");

                // Locate the record for the current billing cycle
                var salaryRecord = await _context.DeliveryPartnerSalary
                    .FirstOrDefaultAsync(s => s.DeliveryPartnerId == updateDto.DeliveryPartnerId && s.MonthYear == currentMonth);

                if (salaryRecord == null)
                {
                    return NotFound("Record not found for this month");
                }

                bool isUpdated = false;

                // Update Basic Salary and track the update timestamp
                if (salaryRecord.BasicSalary != updateDto.BasicSalary)
                {
                    salaryRecord.BasicSalary = updateDto.BasicSalary;
                    salaryRecord.BasicSalaryLastUpdate = DateTime.Now;
                    isUpdated = true;
                }

                // Update Incentive and track the update timestamp
                if (salaryRecord.Incentive != updateDto.Incentive)
                {
                    salaryRecord.Incentive = updateDto.Incentive;
                    salaryRecord.IncentiveLastUpdate = DateTime.Now;
                    isUpdated = true;
                }

                if (isUpdated)
                {
                    // Recalculate total monthly earnings before saving
                    salaryRecord.TotalMonthlyEarnings = salaryRecord.BasicSalary + salaryRecord.TotalCommission + salaryRecord.Incentive;
                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Updated successfully!", total = salaryRecord.TotalMonthlyEarnings });
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }

        [HttpGet("GetAllPartnersPerformance")]
        public async Task<IActionResult> GetAllPartnersPerformance()
        {
            var performance = await _context.DeliveryPartner
                .Select(p => new
                {
                    p.FullName,
                    p.PartnerCode,

                    AverageRating = _context.DeliveryRating
                        .Where(r => r.DeliveryPartnerId == p.DeliveryPartnerId)
                        .Average(r => (double?)r.RatingValue) ?? 0.0,

                    RatingCount = _context.DeliveryRating
                        .Count(r => r.DeliveryPartnerId == p.DeliveryPartnerId),

                    TotalReaders = _context.Reader
                        .Count(r => r.ReaderId == p.DeliveryPartnerId),

                    ComplaintCount = _context.Complaints
                        .Count(c => c.DeliveryPartnerId == p.DeliveryPartnerId),

                    RecentRatings = _context.DeliveryRating
                        .Where(r => r.DeliveryPartnerId == p.DeliveryPartnerId)
                        .OrderByDescending(r => r.CreatedAt)
                        .Take(5)
                        .Select(r => new
                        {
                            ReviewerName = _context.Reader
                                .Where(reader => reader.ReaderId == r.ReaderId)
                                .Select(reader => reader.FullName)
                                .FirstOrDefault() ?? "Anonymous",
                            r.RatingValue,
                            r.Comments,
                            r.CreatedAt,
                            FeedbackTags = r.FeedbackTags != null ? r.FeedbackTags.Split(',', StringSplitOptions.RemoveEmptyEntries).ToList() : new List<string>()
                        }).ToList()
                }).ToListAsync();

            return Ok(performance);
        }

        // 7. Get list of all registered readers (GET method)
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
                        r.HouseName,
                        r.HouseNo,
                        r.Landmark,
                        r.PanchayatName,
                        r.WardNumber,
                        r.Pincode,
                        r.AddedByPartnerCode,
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
    }
}