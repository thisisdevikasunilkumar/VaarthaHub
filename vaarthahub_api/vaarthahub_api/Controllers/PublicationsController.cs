using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using vaarthahub_api.DTOs;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PublicationsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public PublicationsController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("AddNewspaper")]
        public async Task<IActionResult> AddNewspaper([FromBody] AddNewspaperDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                var newspaper = new Newspaper
                {
                    Name = dto.Name,
                    Category = dto.Category,
                    PaperType = dto.PaperType,
                    BasePrice = dto.BasePrice,
                    LogoUrl = dto.LogoBase64, // Storing Base64 inline for now as string
                    IsActive = dto.IsActive
                };

                _context.Newspapers.Add(newspaper);
                await _context.SaveChangesAsync();
                return Ok(new { status = "Success", message = "Newspaper added successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        [HttpPost("AddMagazine")]
        public async Task<IActionResult> AddMagazine([FromBody] AddMagazineDto dto)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                var magazine = new Magazine
                {
                    NewspaperId = dto.NewspaperId,
                    Name = dto.Name,
                    Category = dto.Category,
                    PublicationCycle = dto.PublicationCycle,
                    Price = dto.Price,
                    LogoUrl = dto.LogoBase64, // Storing Base64 inline as string
                    IsActive = dto.IsActive
                };

                _context.Magazines.Add(magazine);
                await _context.SaveChangesAsync();
                return Ok(new { status = "Success", message = "Magazine added successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        [HttpGet("GetNewspapers")]
        public async Task<IActionResult> GetNewspapers()
        {
            try
            {
                var newspapers = await _context.Newspapers.ToListAsync();
                return Ok(newspapers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        [HttpGet("GetMagazines")]
        public async Task<IActionResult> GetMagazines()
        {
            try
            {
                var magazines = await _context.Magazines.ToListAsync();
                return Ok(magazines);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        [HttpPut("UpdateNewspaper/{id}")]
        public async Task<IActionResult> UpdateNewspaper(int id, [FromBody] UpdateNewspaperDto dto)
        {
            if (id != dto.NewspaperId) return BadRequest("ID mismatch");

            var newspaper = await _context.Newspapers.FindAsync(id);
            if (newspaper == null) return NotFound("Newspaper not found");

            newspaper.Name = dto.Name;
            newspaper.Category = dto.Category;
            newspaper.PaperType = dto.PaperType;
            newspaper.BasePrice = dto.BasePrice;
            newspaper.IsActive = dto.IsActive;
            
            if (!string.IsNullOrEmpty(dto.LogoBase64))
            {
                newspaper.LogoUrl = dto.LogoBase64;
            }

            try
            {
                _context.Update(newspaper);
                await _context.SaveChangesAsync();
                return Ok(new { status = "Success", message = "Newspaper updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }

        [HttpPut("UpdateMagazine/{id}")]
        public async Task<IActionResult> UpdateMagazine(int id, [FromBody] UpdateMagazineDto dto)
        {
            if (id != dto.MagazineId) return BadRequest("ID mismatch");

            var magazine = await _context.Magazines.FindAsync(id);
            if (magazine == null) return NotFound("Magazine not found");

            magazine.NewspaperId = dto.NewspaperId;
            magazine.Name = dto.Name;
            magazine.Category = dto.Category;
            magazine.PublicationCycle = dto.PublicationCycle;
            magazine.Price = dto.Price;
            magazine.IsActive = dto.IsActive;

            if (!string.IsNullOrEmpty(dto.LogoBase64))
            {
                magazine.LogoUrl = dto.LogoBase64;
            }

            try
            {
                _context.Update(magazine);
                await _context.SaveChangesAsync();
                return Ok(new { status = "Success", message = "Magazine updated successfully" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { status = "Error", message = ex.Message });
            }
        }
    }
}
