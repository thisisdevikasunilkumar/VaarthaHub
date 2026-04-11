using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ComplaintsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ComplaintsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("RegisterComplaint")]
        public async Task<IActionResult> RegisterComplaint([FromBody] ComplaintDto dto)
        {
            try
            {
                var reader = await _context.Reader.FirstOrDefaultAsync(r => r.ReaderCode == dto.ReaderCode);
                if (reader == null)
                    return BadRequest(new { status = "Error", message = "Invalid Reader Code" });

                var partner = await _context.DeliveryPartner.FirstOrDefaultAsync(p => p.PartnerCode == reader.AddedByPartnerCode);
                if (partner == null)
                    return BadRequest(new { status = "Error", message = "Delivery Partner not found for this reader" });

                var complaint = new Complaint
                {
                    ReaderId = reader.ReaderId,
                    DeliveryPartnerId = partner.DeliveryPartnerId,
                    ComplaintType = dto.ComplaintType,
                    Comments = dto.Comments,
                    Status = "Open",
                    CreatedAt = DateTime.Now
                };

                _context.Complaints.Add(complaint);
                await _context.SaveChangesAsync();

                return Ok(new { status = "Success", message = "Complaint registered successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }
        [HttpGet("GetAllComplaints")]
        public async Task<IActionResult> GetAllComplaints()
        {
            try
            {
                var complaints = await _context.Complaints
                    .Include(c => c.Reader)
                    .Include(c => c.DeliveryPartner)
                    .OrderByDescending(c => c.CreatedAt)
                    .Select(c => new
                    {
                        c.ComplaintId,
                        c.ComplaintType,
                        c.Comments,
                        c.Status,
                        c.CreatedAt,
                        ReaderName = c.Reader != null ? c.Reader.FullName : "Unknown",
                        PartnerName = c.DeliveryPartner != null ? c.DeliveryPartner.FullName : "Unknown"
                    })
                    .ToListAsync();

                return Ok(complaints);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }
    }
}
