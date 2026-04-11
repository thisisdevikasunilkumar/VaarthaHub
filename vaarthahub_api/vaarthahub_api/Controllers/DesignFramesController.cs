using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DesignFramesController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public DesignFramesController(ApplicationDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        // GET: api/DesignFrames
        [HttpGet]
        public async Task<ActionResult<IEnumerable<DesignFrame>>> GetDesignFrames()
        {
            return await _context.DesignFrames
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();
        }

        // POST: api/DesignFrames
        [HttpPost]
        public async Task<IActionResult> PostDesignFrame([FromForm] AddDesignFrameDto dto)
        {
            if (dto.Image == null || dto.Image.Length == 0)
            {
                return BadRequest(new { message = "Image file is required." });
            }

            try
            {
                // 1. (wwwroot/uploads/frames)
                string uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", "frames");
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                string uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetFileName(dto.Image.FileName);
                string filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await dto.Image.CopyToAsync(fileStream);
                }

                var designFrame = new DesignFrame
                {
                    Category = dto.Category,
                    FrameName = dto.FrameName,
                    CardType = dto.CardType,
                    Price = dto.Price,
                    IsActive = dto.IsActive,
                    ImagePath = "/uploads/frames/" + uniqueFileName,
                    CreatedAt = DateTime.Now
                };

                _context.DesignFrames.Add(designFrame);
                await _context.SaveChangesAsync();

                return Ok(designFrame);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Internal server error", error = ex.Message });
            }
        }

        // PUT: api/DesignFrames/5
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateDesignFrame(int id, [FromForm] AddDesignFrameDto dto)
        {
            var frame = await _context.DesignFrames.FindAsync(id);
            if (frame == null) return NotFound(new { message = "Frame not found" });

            try
            {
                if (dto.Image != null && dto.Image.Length > 0)
                {
                    string uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", "frames");

                    var oldFilePath = Path.Combine(_environment.WebRootPath, frame.ImagePath.TrimStart('/'));
                    if (System.IO.File.Exists(oldFilePath))
                    {
                        System.IO.File.Delete(oldFilePath);
                    }

                    string uniqueFileName = Guid.NewGuid().ToString() + "_" + Path.GetFileName(dto.Image.FileName);
                    string filePath = Path.Combine(uploadsFolder, uniqueFileName);

                    using (var fileStream = new FileStream(filePath, FileMode.Create))
                    {
                        await dto.Image.CopyToAsync(fileStream);
                    }

                    frame.ImagePath = "/uploads/frames/" + uniqueFileName;
                }

                frame.Category = dto.Category;
                frame.FrameName = dto.FrameName;
                frame.CardType = dto.CardType;
                frame.Price = dto.Price;
                frame.IsActive = dto.IsActive;

                _context.Entry(frame).State = EntityState.Modified;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Frame updated successfully", data = frame });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Internal server error", error = ex.Message });
            }
        }

        [HttpPatch("toggle/{id}")]
        public async Task<IActionResult> ToggleStatus(int id, [FromBody] bool isActive)
        {
            var frame = await _context.DesignFrames.FindAsync(id);
            if (frame == null) return NotFound();

            frame.IsActive = isActive;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Status updated" });
        }

        // DELETE: api/DesignFrames/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteDesignFrame(int id)
        {
            var frame = await _context.DesignFrames.FindAsync(id);
            if (frame == null) return NotFound();

            var fullPath = Path.Combine(_environment.WebRootPath, frame.ImagePath.TrimStart('/'));
            if (System.IO.File.Exists(fullPath))
            {
                System.IO.File.Delete(fullPath);
            }

            _context.DesignFrames.Remove(frame);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Frame deleted successfully" });
        }

        // 3. Get all unique CardType names (GET method)
        [HttpGet("GetCardType")]
        public async Task<IActionResult> GetUniqueCardType()
        {
            try
            {
                var cardtype = await _context.DesignFrames
                    .Select(d => d.CardType)
                    .Distinct()
                    .ToListAsync();

                return Ok(cardtype);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        // 4. Get Design Frames by Category (GET method)
        [HttpGet("ByCategory/{category}")]
        public async Task<ActionResult<IEnumerable<DesignFrame>>> GetDesignFramesByCategory(string category)
        {
            try
            {
                var frames = await _context.DesignFrames
                    .Where(f => f.Category.ToLower() == category.ToLower())
                    .OrderByDescending(x => x.CreatedAt)
                    .ToListAsync();

                if (frames == null || !frames.Any())
                {
                    return NotFound(new { message = $"No frames found in the '{category}' category." });
                }

                return Ok(frames);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Internal server error", error = ex.Message });
            }
        }
    }
}