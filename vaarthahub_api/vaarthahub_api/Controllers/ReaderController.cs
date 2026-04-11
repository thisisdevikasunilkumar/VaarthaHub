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
                                               reader.ReaderId,
                                               reader.ReaderCode,
                                               reader.AddedByPartnerCode,
                                               reg.UserCode,
                                               reader.FullName,
                                               reader.PhoneNumber,
                                               reg.Email,
                                               reader.Gender,
                                               reader.DateOfBirth,
                                               reader.HouseName,
                                               reader.HouseNo,
                                               reader.Landmark,
                                               reader.PanchayatName,
                                               reader.WardNumber,
                                               reader.Pincode,
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

        [HttpPut("UpdateDetailedAddress/{readerCode}")]
        public async Task<IActionResult> UpdateDetailedAddress(string readerCode, [FromBody] ReaderDto dto)
        {
            var reader = await _context.Reader.FirstOrDefaultAsync(r => r.ReaderCode == readerCode);

            if (reader == null)
                return NotFound(new { message = "Reader not found" });

            // Updating specific address fields
            reader.HouseName = dto.HouseName;
            reader.HouseNo = dto.HouseNo;
            reader.Landmark = dto.Landmark;
            reader.PanchayatName = dto.PanchayatName;
            reader.WardNumber = dto.WardNumber;
            reader.Pincode = dto.Pincode;

            try
            {
                await _context.SaveChangesAsync();
                return Ok(new { message = "Address updated successfully" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Update failed", error = ex.Message });
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
                // 1. partnerCode വെച്ച് partnerId കണ്ടുപിടിക്കുന്നു
                var partner = await _context.DeliveryPartner
                    .Where(p => p.PartnerCode == partnerCode)
                    .Select(p => new { p.DeliveryPartnerId, p.FullName })
                    .FirstOrDefaultAsync();

                if (partner == null)
                {
                    return NotFound(new { status = "Error", message = "Partner not found." });
                }

                // 2. DeliveryRating-ഉം Reader-ഉം തമ്മിൽ Join ചെയ്യുന്നു (Navigation Property ഇല്ലാത്തതുകൊണ്ട്)
                var query = from rating in _context.DeliveryRating
                            join reader in _context.Reader on rating.ReaderId equals reader.ReaderId
                            where rating.DeliveryPartnerId == partner.DeliveryPartnerId
                            select new
                            {
                                readerName = reader.FullName,
                                ratingValue = rating.RatingValue,
                                comments = rating.Comments,
                                feedbackTags = rating.FeedbackTags,
                                createdAt = rating.CreatedAt
                            };

                var ratingsList = await query.OrderByDescending(r => r.createdAt).ToListAsync();

                if (!ratingsList.Any())
                {
                    return Ok(new
                    {
                        fullName = partner.FullName,
                        averageRating = 0.0,
                        totalReviews = 0,
                        starCounts = new { star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0 },
                        reviews = new List<object>()
                    });
                }

                // 3. Calculations
                var totalReviews = ratingsList.Count;
                var averageRating = ratingsList.Average(r => (double)r.ratingValue);

                // 4. Final Result Structure
                var result = new
                {
                    fullName = partner.FullName,
                    averageRating = Math.Round(averageRating, 1),
                    totalReviews = totalReviews,
                    starCounts = new
                    {
                        star5 = ratingsList.Count(r => r.ratingValue == 5),
                        star4 = ratingsList.Count(r => r.ratingValue == 4),
                        star3 = ratingsList.Count(r => r.ratingValue == 3),
                        star2 = ratingsList.Count(r => r.ratingValue == 2),
                        star1 = ratingsList.Count(r => r.ratingValue == 1)
                    },
                    reviews = ratingsList.Select(r => new
                    {
                        readerName = r.readerName ?? "Reader",
                        ratingValue = r.ratingValue,
                        comments = r.comments,
                        feedbackTags = string.IsNullOrEmpty(r.feedbackTags)
                                       ? new List<string>()
                                       : r.feedbackTags.Split(',').Select(t => t.Trim()).ToList(),
                        date = r.createdAt.ToString("dd MMM yyyy")
                    })
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // GET: api/Reader/GetPartnerComplaints/{partnerCode}
        [HttpGet("GetPartnerComplaints/{partnerCode}")]
        public async Task<IActionResult> GetPartnerComplaints(string partnerCode)
        {
            try
            {
                var partner = await _context.DeliveryPartner
                    .Where(p => p.PartnerCode == partnerCode)
                    .Select(p => new { p.DeliveryPartnerId })
                    .FirstOrDefaultAsync();

                if (partner == null)
                {
                    return NotFound(new { status = "Error", message = "Partner not found." });
                }

                var complaints = await _context.Complaints
                    .Include(c => c.Reader)
                    .Where(c => c.DeliveryPartnerId == partner.DeliveryPartnerId)
                    .OrderByDescending(c => c.CreatedAt)
                    .Select(c => new
                    {
                        c.ComplaintId,
                        c.ComplaintType,
                        c.Comments,
                        c.Status,
                        c.CreatedAt,
                        ReaderName = c.Reader != null ? c.Reader.FullName : "Unknown"
                    })
                    .ToListAsync();

                return Ok(complaints);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // GET: api/Reader/GetReaderRatings/{readerCode}
        [HttpGet("GetReaderRatings/{readerCode}")]
        public async Task<IActionResult> GetReaderRatings(string readerCode)
        {
            try
            {
                var reader = await _context.Reader
                    .Where(r => r.ReaderCode == readerCode)
                    .Select(r => new { r.ReaderId })
                    .FirstOrDefaultAsync();

                if (reader == null)
                {
                    return NotFound(new { status = "Error", message = "Reader not found." });
                }

                var ratings = await (from rating in _context.DeliveryRating
                                     join partner in _context.DeliveryPartner on rating.DeliveryPartnerId equals partner.DeliveryPartnerId
                                     where rating.ReaderId == reader.ReaderId
                                     select new
                                     {
                                         partnerName = partner.FullName,
                                         ratingValue = rating.RatingValue,
                                         comments = rating.Comments,
                                         feedbackTags = rating.FeedbackTags,
                                         createdAt = rating.CreatedAt
                                     }).OrderByDescending(r => r.createdAt).ToListAsync();

                var results = ratings.Select(r => new
                {
                    partnerName = r.partnerName,
                    ratingValue = r.ratingValue,
                    comments = r.comments,
                    feedbackTags = string.IsNullOrEmpty(r.feedbackTags)
                                   ? new List<string>()
                                   : r.feedbackTags.Split(',').Select(t => t.Trim()).ToList(),
                    date = r.createdAt.ToString("dd MMM yyyy")
                });

                return Ok(results);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        // GET: api/Reader/GetReaderComplaints/{readerCode}
        [HttpGet("GetReaderComplaints/{readerCode}")]
        public async Task<IActionResult> GetReaderComplaints(string readerCode)
        {
            try
            {
                var reader = await _context.Reader
                    .Where(r => r.ReaderCode == readerCode)
                    .Select(r => new { r.ReaderId })
                    .FirstOrDefaultAsync();

                if (reader == null)
                {
                    return NotFound(new { status = "Error", message = "Reader not found." });
                }

                var complaints = await (from complaint in _context.Complaints
                                        join partner in _context.DeliveryPartner on complaint.DeliveryPartnerId equals partner.DeliveryPartnerId
                                        where complaint.ReaderId == reader.ReaderId
                                        select new
                                        {
                                            complaint.ComplaintId,
                                            complaint.ComplaintType,
                                            complaint.Comments,
                                            complaint.Status,
                                            complaint.CreatedAt,
                                            PartnerName = partner.FullName
                                        }).OrderByDescending(c => c.CreatedAt).ToListAsync();

                return Ok(complaints);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }
    }
}