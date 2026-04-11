using Microsoft.AspNetCore.Mvc;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;
using Microsoft.EntityFrameworkCore;
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

        // 0. Test API to verify controller is working
        // URL: https://localhost:7134/api/Admin/Test
        [HttpGet("Test")]
        public IActionResult GetTest()
        {
            return Ok("Admin Controller working fine!");
        }

        // 1. Delivery Partner list get (GET method)
        [HttpGet("GetDeliveryPartners")]
        public async Task<IActionResult> GetDeliveryPartners()
        {
            try
            {
                var currentMonth = DateTime.Now.ToString("MMMM yyyy");

                // DeliveryPartner & Salary table join
                var partners = await (from p in _context.DeliveryPartner
                                      join s in _context.DeliveryPartnerSalary
                                      on p.DeliveryPartnerId equals s.DeliveryPartnerId
                                      where s.MonthYear == currentMonth
                                      select new
                                      {
                                          p.DeliveryPartnerId,
                                          p.FullName,
                                          p.PhoneNumber,
                                          s.TotalMonthlyEarnings,
                                          p.CreatedAt
                                      }).ToListAsync();

                return Ok(partners);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // 2. Delivery Partner add (POST method)
        [HttpPost("AddDeliveryPartner")]
        public async Task<IActionResult> AddDeliveryPartner([FromBody] DeliveryPartnerDto partnerDto)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Save to DeliveryPartner table
                var partner = new DeliveryPartner
                {
                    FullName = partnerDto.FullName,
                    PhoneNumber = partnerDto.PhoneNumber,
                    VehicleType = partnerDto.VehicleType,
                    VehicleNumber = partnerDto.VehicleNumber,
                    LicenseNumber = partnerDto.LicenseNumber,
                    PanchayatName = partnerDto.PanchayatName,
                    BasicSalary = partnerDto.BasicSalary, // Saved here
                    CreatedAt = DateTime.Now
                };

                _context.DeliveryPartner.Add(partner);
                await _context.SaveChangesAsync();

                // 2. Save to DeliveryPartnerSalary table
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

                // Send add SMS (non-blocking for user flow). Failures won't break the request.
                try
                {
                    await _smsService.SendAddDeliveryPartnerSmsAsync(partner.PhoneNumber, partner.FullName);
                }
                catch
                {
                    // ignore SMS errors
                }

                return Ok(new { message = "Partner added successfully!" });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, ex.Message);
            }
        }

        // 3. Delivery Partner delete (DELETE method)
        [HttpDelete("DeletePartner/{id}")]
        public async Task<IActionResult> DeletePartner(int id)
        {
            try
            {
                var partner = await _context.DeliveryPartner.FindAsync(id);
                if (partner == null) return NotFound("Partner not found");

                // Salary
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

        // 4. Delivery Partner Salary details get (GET method)
        [HttpGet("GetPartnerSalaryDetails/{id}")]
        public async Task<IActionResult> GetPartnerSalaryDetails(int id)
        {
            try
            {
                var partner = await _context.DeliveryPartner.FindAsync(id);
                if (partner == null)
                {
                    return NotFound("Partner not found");
                }

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
                        IncentiveLastUpdate = s.IncentiveLastUpdate
                    })
                    .ToListAsync();

                return Ok(new
                {
                    partnerName = partner.FullName,
                    history = salaryHistory
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // 5. Delivery Partner Salary update (PUT method)
        [HttpPut("UpdatePartnerSalary")]
        public async Task<IActionResult> UpdatePartnerSalary([FromBody] DeliveryPartnerSalaryDto updateDto)
        {
            try
            {
                var currentMonth = DateTime.Now.ToString("MMMM yyyy");

                var salaryRecord = await _context.DeliveryPartnerSalary
                    .FirstOrDefaultAsync(s => s.DeliveryPartnerId == updateDto.DeliveryPartnerId && s.MonthYear == currentMonth);

                if (salaryRecord == null)
                {
                    return NotFound("Record not found for this month");
                }

                bool isUpdated = false;

                // Basic Salary check & update
                if (salaryRecord.BasicSalary != updateDto.BasicSalary)
                {
                    salaryRecord.BasicSalary = updateDto.BasicSalary;
                    salaryRecord.BasicSalaryLastUpdate = DateTime.Now;
                    isUpdated = true;
                }

                // Incentive check & update
                if (salaryRecord.Incentive != updateDto.Incentive)
                {
                    salaryRecord.Incentive = updateDto.Incentive;
                    salaryRecord.IncentiveLastUpdate = DateTime.Now;
                    isUpdated = true;
                }

                if (isUpdated)
                {
                    // 4. Total calculate cheythu save cheyyunnu
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
    }
}