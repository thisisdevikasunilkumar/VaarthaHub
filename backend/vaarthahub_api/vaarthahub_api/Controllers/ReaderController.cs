using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReaderController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ReaderController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Reader/GetReaderProfile/{readerId}
        [HttpGet("GetReaderProfile/{ReaderCode}")]
        public async Task<IActionResult> GetReaderProfile(string ReaderCode)
        {
            try
            {
                var readerProfile = await (from reader in _context.Reader
                                           join reg in _context.Registration
                                           on reader.PhoneNumber equals reg.PhoneNumber
                                           where reader.ReaderCode == ReaderCode
                                           select new
                                           {
                                               reader.ReaderCode,
                                               reader.AddedByPartnerCode,
                                               reg.UserCode,
                                               reader.FullName,
                                               reader.PhoneNumber,
                                               reg.Email,
                                               reader.Gender,
                                               reader.DateOfBirth,
                                               reader.PanchayatName,
                                               reader.Address,
                                               reader.WardNumber,
                                               reader.Role,
                                               reg.PasswordUpdatedAt,

                                               ProfileImage = reg.ProfileImage != null
                                                              ? Convert.ToBase64String(reg.ProfileImage)
                                                              : null
                                           }).FirstOrDefaultAsync();

                if (readerProfile == null)
                {
                    return NotFound(new { status = "Error", message = "Reader not found." });
                }

                return Ok(readerProfile);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // PUT: api/Reader/UpdateReaderProfile/{readerCode}
        [HttpPut("UpdateReaderProfile/{readerCode}")]
        public async Task<IActionResult> UpdateReaderProfile(string readerCode, [FromBody] UpdateReaderDto dto)
        {
            var reader = await _context.Reader.FirstOrDefaultAsync(r => r.ReaderCode == readerCode);
            if (reader == null) return NotFound(new { message = "Reader not found." });

            var reg = await _context.Registration.FirstOrDefaultAsync(r => r.UserCode == readerCode);
            if (reg == null) return NotFound(new { message = "Registration record not found." });

            // Update reader details
            reader.FullName = dto.FullName;
            reader.PhoneNumber = dto.PhoneNumber;
            reader.Gender = dto.Gender;
            reader.DateOfBirth = dto.DateOfBirth;
            reader.PanchayatName = dto.PanchayatName;
            reader.Address = dto.Address ?? string.Empty;
            reader.WardNumber = dto.WardNumber ?? string.Empty;

            // Update registration details (for login)
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
                    // ignore invalid base64; keep existing image
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

        // POST: api/Reader/SubmitRating
        [HttpPost("SubmitRating")]
        public async Task<IActionResult> SubmitRating([FromBody] DeliveryRatingDto ratingDto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                // Find DeliveryPartner by PartnerCode
                var partner = await _context.DeliveryPartner
                    .FirstOrDefaultAsync(p => p.PartnerCode == ratingDto.PartnerCode);
                if (partner == null)
                {
                    return BadRequest(new { status = "Error", message = "Invalid PartnerCode." });
                }

                // Find Reader by ReaderCode
                var reader = await _context.Reader
                    .FirstOrDefaultAsync(r => r.ReaderCode == ratingDto.ReaderCode);
                if (reader == null)
                {
                    return BadRequest(new { status = "Error", message = "Invalid ReaderCode." });
                }

                // Mapping DTO to Model
                var rating = new DeliveryRating
                {
                    DeliveryPartnerId = partner.DeliveryPartnerId,
                    ReaderId = reader.ReaderId,
                    RatingValue = ratingDto.RatingValue,
                    Comments = ratingDto.Comments,
                    CreatedAt = DateTime.Now,

                    FeedbackTags = ratingDto.FeedbackTags != null && ratingDto.FeedbackTags.Any()
                                   ? string.Join(", ", ratingDto.FeedbackTags)
                                   : null
                };

                _context.DeliveryRating.Add(rating);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    status = "Success",
                    message = "Rating submitted successfully!"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    status = "Error",
                    message = $"Internal server error: {ex.Message}"
                });
            }
        }

        // GET: api/Reader/GetPartnerRatings/{partnerCode}
        [HttpGet("GetPartnerRatings/{partnerCode}")]
        public async Task<IActionResult> GetPartnerRatings(string partnerCode)
        {
            try
            {
                // 1. partnerCode vechu partner-nte integer Id kandupidikkunnu
                var partner = await _context.DeliveryPartner
                    .Where(p => p.PartnerCode == partnerCode)
                    .Select(p => new { p.DeliveryPartnerId })
                    .FirstOrDefaultAsync();

                if (partner == null)
                {
                    return NotFound(new { status = "Error", message = "Partner not found." });
                }

                // 2. Rating details fetch cheyyunnu (DeliveryRating table-il ninnu, Reader details-um include cheythu)
                var ratings = await _context.DeliveryRating
                    .Include(r => r.Reader)
                    .Where(r => r.DeliveryPartnerId == partner.DeliveryPartnerId)
                    .OrderByDescending(r => r.CreatedAt)
                    .ToListAsync();

                if (ratings == null || !ratings.Any())
                {
                    return Ok(new
                    {
                        averageRating = 0.0,
                        totalReviews = 0,
                        starCounts = new { star1 = 0, star2 = 0, star3 = 0, star4 = 0, star5 = 0 },
                        reviews = new List<object>()
                    });
                }

                // 3. Calculations for Summary Card
                var totalReviews = ratings.Count;
                var averageRating = ratings.Average(r => (double)r.RatingValue);

                var starCounts = new Dictionary<string, int>
                {
                    { "5", ratings.Count(r => r.RatingValue == 5) },
                    { "4", ratings.Count(r => r.RatingValue == 4) },
                    { "3", ratings.Count(r => r.RatingValue == 3) },
                    { "2", ratings.Count(r => r.RatingValue == 2) },
                    { "1", ratings.Count(r => r.RatingValue == 1) }
                };

                // 4. Final Data Structure
                var result = new
                {
                    averageRating = Math.Round(averageRating, 1),
                    totalReviews = totalReviews,
                    starCounts = starCounts,
                    reviews = ratings.Select(r => new
                    {
                        readerName = r.Reader?.FullName ?? "Reader",
                        ratingValue = r.RatingValue,
                        comments = r.Comments,
                        feedbackTags = string.IsNullOrEmpty(r.FeedbackTags)
                                       ? new List<string>()
                                       : r.FeedbackTags.Split(',').Select(t => t.Trim()).ToList(),
                        date = r.CreatedAt.ToString("dd MMM yyyy")
                    })
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }
    }
}