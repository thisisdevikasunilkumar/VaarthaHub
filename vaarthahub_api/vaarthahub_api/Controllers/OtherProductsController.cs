using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OtherProductsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _environment;

        public OtherProductsController(ApplicationDbContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        // GET: api/OtherProducts
        [HttpGet]
        public async Task<ActionResult<IEnumerable<OtherProduct>>> GetOtherProducts()
        {
            return await _context.OtherProducts.Include(p => p.Newspaper).ToListAsync();
        }

        // GET: api/OtherProducts/5
        [HttpGet("{id}")]
        public async Task<ActionResult<OtherProduct>> GetOtherProduct(int id)
        {
            var otherProduct = await _context.OtherProducts.Include(p => p.Newspaper).FirstOrDefaultAsync(p => p.ProductId == id);

            if (otherProduct == null)
            {
                return NotFound();
            }

            return otherProduct;
        }

        // PUT: api/OtherProducts/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutOtherProduct(int id, [FromForm] OtherProduct otherProduct, IFormFile? imageFile)
        {
            if (id != otherProduct.ProductId)
            {
                return BadRequest();
            }

            var existingProduct = await _context.OtherProducts.FindAsync(id);
            if (existingProduct == null)
            {
                return NotFound();
            }

            // Update fields
            existingProduct.ItemType = otherProduct.ItemType;
            if (existingProduct.ItemType.Contains("Calendar", StringComparison.OrdinalIgnoreCase))
            {
                existingProduct.ItemId = 3;
            }
            else if (existingProduct.ItemType.Contains("Diary", StringComparison.OrdinalIgnoreCase))
            {
                existingProduct.ItemId = 4;
            }
            else
            {
                existingProduct.ItemId = otherProduct.ItemId;
            }
            existingProduct.NewspaperId = otherProduct.NewspaperId;
            existingProduct.Name = otherProduct.Name;
            existingProduct.ProductType = otherProduct.ProductType;
            existingProduct.Size = otherProduct.Size;
            existingProduct.Year = otherProduct.Year;
            existingProduct.UnitPrice = otherProduct.UnitPrice;
            existingProduct.IsActive = otherProduct.IsActive;

            // Handle image upload
            if (imageFile != null && imageFile.Length > 0)
            {
                var uploadsFolder = Path.Combine(_environment.WebRootPath ?? "wwwroot", "images", "products");
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                var uniqueFileName = Guid.NewGuid().ToString() + "_" + imageFile.FileName;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(fileStream);
                }

                // Delete old image if needed (optional)

                existingProduct.ImageUrl = "/images/products/" + uniqueFileName;
            }

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!OtherProductExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // POST: api/OtherProducts
        [HttpPost]
        public async Task<ActionResult<OtherProduct>> PostOtherProduct([FromForm] OtherProduct otherProduct, IFormFile? imageFile)
        {
            // Handle image upload
            if (imageFile != null && imageFile.Length > 0)
            {
                var uploadsFolder = Path.Combine(_environment.WebRootPath ?? "wwwroot", "images", "products");
                if (!Directory.Exists(uploadsFolder))
                {
                    Directory.CreateDirectory(uploadsFolder);
                }

                var uniqueFileName = Guid.NewGuid().ToString() + "_" + imageFile.FileName;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);

                using (var fileStream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(fileStream);
                }

                otherProduct.ImageUrl = "/images/products/" + uniqueFileName;
            }

            // Ensure Newspaper is null to avoid EF Core trying to insert a new newspaper
            otherProduct.Newspaper = null;

            if (otherProduct.ItemType != null)
            {
                if (otherProduct.ItemType.Contains("Calendar", StringComparison.OrdinalIgnoreCase))
                {
                    otherProduct.ItemId = 3;
                }
                else if (otherProduct.ItemType.Contains("Diary", StringComparison.OrdinalIgnoreCase))
                {
                    otherProduct.ItemId = 4;
                }
            }

            _context.OtherProducts.Add(otherProduct);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetOtherProduct", new { id = otherProduct.ProductId }, otherProduct);
        }

        // DELETE: api/OtherProducts/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOtherProduct(int id)
        {
            var otherProduct = await _context.OtherProducts.FindAsync(id);
            if (otherProduct == null)
            {
                return NotFound();
            }

            _context.OtherProducts.Remove(otherProduct);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool OtherProductExists(int id)
        {
            return _context.OtherProducts.Any(e => e.ProductId == id);
        }
    }
}
