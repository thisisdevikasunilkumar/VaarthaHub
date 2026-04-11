using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NotificationsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public NotificationsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // GET: api/Notifications/{userCode}
        [HttpGet("{userCode}")]
        public async Task<IActionResult> GetNotifications(string userCode)
        {
            var notifications = await _context.Notifications
                .Where(n => n.UserCode == userCode)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return Ok(notifications);
        }

        // GET: api/Notifications/unread-count/{userCode}
        [HttpGet("unread-count/{userCode}")]
        public async Task<IActionResult> GetUnreadCount(string userCode)
        {
            var count = await _context.Notifications
                .CountAsync(n => n.UserCode == userCode && !n.IsRead);

            return Ok(new { count });
        }

        // PUT: api/Notifications/mark-as-read/{id}
        [HttpPut("mark-as-read/{id}")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound();

            notification.IsRead = true;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Notification marked as read" });
        }

        // PUT: api/Notifications/mark-all-read/{userCode}
        [HttpPut("mark-all-read/{userCode}")]
        public async Task<IActionResult> MarkAllRead(string userCode)
        {
            var unread = await _context.Notifications
                .Where(n => n.UserCode == userCode && !n.IsRead)
                .ToListAsync();

            foreach (var n in unread)
            {
                n.IsRead = true;
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "All notifications marked as read" });
        }

        // DELETE: api/Notifications/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteNotification(int id)
        {
            var notification = await _context.Notifications.FindAsync(id);
            if (notification == null) return NotFound();

            _context.Notifications.Remove(notification);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Notification deleted" });
        }
    }
}
