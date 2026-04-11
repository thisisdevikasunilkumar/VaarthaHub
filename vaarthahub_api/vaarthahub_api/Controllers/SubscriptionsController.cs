using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.Models;
using System.Collections.Generic;
using vaarthahub_api.DTOs;
using System.Linq;
using System.Threading.Tasks;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SubscriptionsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public SubscriptionsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/Subscriptions/AddSubscription
        [HttpPost("AddSubscription")]
        public async Task<IActionResult> AddSubscription([FromBody] Subscription subscription)
        {
            if (subscription == null) return BadRequest("Invalid data.");

            try
            {
                subscription.IsActive = "Active";
                subscription.IsVacationMode = false;
                
                _context.Subscriptions.Add(subscription);
                await _context.SaveChangesAsync();

                // --- Notify the reader's delivery partner ---
                var reader = await _context.Reader.FindAsync(subscription.ReaderId);
                if (reader != null && !string.IsNullOrEmpty(reader.AddedByPartnerCode))
                {
                    var itemLabel = !string.IsNullOrEmpty(subscription.SubscriptionName)
                        ? subscription.SubscriptionName
                        : subscription.ItemType;

                    var notification = new Notification
                    {
                        UserCode = reader.AddedByPartnerCode,
                        Title = "New Subscription",
                        Message = $"{reader.FullName} has subscribed to {itemLabel} for {subscription.DurationMonths} month(s).",
                        RelatedId = subscription.SubscriptionId,
                        Type = "NewSubscription",
                        IsRead = false,
                        CreatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(notification);
                    await _context.SaveChangesAsync();
                }

                return Ok(new { message = "Subscription added successfully!", subscriptionId = subscription.SubscriptionId });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        // GET: api/Subscriptions/GetReaderSubscriptions/{readerId}
        [HttpGet("GetReaderSubscriptions/{readerId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetReaderSubscriptions(int readerId)
        {
            var today = DateTime.UtcNow.Date;

            // Automatically start scheduled vacations
            var scheduledToStart = await _context.VacationRequests
                .Where(v => v.ReaderId == readerId && v.IsActive == true && v.StartDate <= today)
                .Include(v => v.Subscription)
                .ToListAsync();

            foreach (var v in scheduledToStart)
            {
                if (v.Subscription != null && v.Subscription.IsActive == "Active")
                {
                    v.Subscription.IsActive = "Vacation";
                    v.Subscription.IsVacationMode = true;
                }
            }

            // Automatically end completed vacations
            var scheduledToEnd = await _context.VacationRequests
                .Where(v => v.ReaderId == readerId && v.IsActive == true && v.EndDate.HasValue && v.EndDate.Value < today)
                .Include(v => v.Subscription)
                .ToListAsync();

            foreach (var v in scheduledToEnd)
            {
                v.IsActive = false; // Vacation is complete
                if (v.Subscription != null && v.Subscription.IsActive == "Vacation")
                {
                    // Check if there are no other active vacations for this subscription spanning today
                    var otherActiveVacations = await _context.VacationRequests
                        .Where(other => other.SubscriptionId == v.SubscriptionId && other.IsActive == true && other.RequestId != v.RequestId && other.StartDate <= today)
                        .AnyAsync();
                        
                    if (!otherActiveVacations)
                    {
                        v.Subscription.IsActive = "Active";
                        v.Subscription.IsVacationMode = false;
                    }
                }
            }

            if (scheduledToStart.Any() || scheduledToEnd.Any())
            {
                await _context.SaveChangesAsync();
            }

            var subscriptions = await _context.Subscriptions
                .Where(s => s.ReaderId == readerId)
                .Select(s => new {
                    s.SubscriptionId,
                    s.ReaderId,
                    s.ItemId,
                    s.ItemType,
                    s.SubscriptionName,
                    s.Category,
                    s.DurationMonths,
                    s.TotalAmount,
                    s.StartDate,
                    s.EndDate,
                    s.IsVacationMode,
                    s.IsActive,
                    s.DeliverySlot,
                    ItemName = !string.IsNullOrEmpty(s.SubscriptionName) ? s.SubscriptionName : (s.ItemType == "Newspaper" 
                        ? _context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.Name).FirstOrDefault()
                        : _context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.Name).FirstOrDefault()),
                    Price = s.TotalAmount != 0 ? s.TotalAmount : (s.ItemType == "Newspaper"
                        ? _context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.BasePrice).FirstOrDefault()
                        : _context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.Price).FirstOrDefault()),
                    LogoUrl = s.ItemType == "Newspaper"
                        ? _context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.LogoUrl).FirstOrDefault()
                        : _context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.LogoUrl).FirstOrDefault()
                })
                .ToListAsync();

            return Ok(subscriptions);
        }

        // POST: api/Subscriptions/ToggleVacation/{subscriptionId}
        [HttpPost("ToggleVacation/{subscriptionId}")]
        public async Task<IActionResult> ToggleVacation(int subscriptionId)
        {
            var subscription = await _context.Subscriptions.FindAsync(subscriptionId);
            if (subscription == null) return NotFound("Subscription not found.");

            if (subscription.IsActive == "Active")
            {
                // Pause it
                subscription.IsActive = "Vacation";
                subscription.IsVacationMode = true;
                
                var vacationRequest = new VacationRequest
                {
                    ReaderId = subscription.ReaderId,
                    SubscriptionId = subscription.SubscriptionId,
                    Category = subscription.Category ?? "Unknown",
                    Name = subscription.SubscriptionName ?? subscription.ItemType,
                    StartDate = DateTime.UtcNow.Date,
                    TotalAmount = subscription.TotalAmount,
                    IsActive = true
                };
                
                _context.VacationRequests.Add(vacationRequest);
            }
            else if (subscription.IsActive == "Vacation")
            {
                // Resume it
                subscription.IsActive = "Active";
                subscription.IsVacationMode = false;
                
                var activeVacation = await _context.VacationRequests
                    .Where(v => v.SubscriptionId == subscriptionId && v.IsActive == true)
                    .OrderByDescending(v => v.StartDate)
                    .FirstOrDefaultAsync();
                    
                if (activeVacation != null)
                {
                    activeVacation.EndDate = DateTime.UtcNow.Date;
                    activeVacation.IsActive = false;
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Subscription is now {subscription.IsActive}", isActive = subscription.IsActive });
        }

        // POST: api/Subscriptions/SetVacationDates
        [HttpPost("SetVacationDates")]
        public async Task<IActionResult> SetVacationDates([FromBody] SetVacationDto dto)
        {
            if (dto.SubscriptionIds == null || !dto.SubscriptionIds.Any())
                return BadRequest("No subscriptions selected for vacation.");

            var activeSubscriptions = await _context.Subscriptions
                .Where(s => s.ReaderId == dto.ReaderId && s.IsActive == "Active" && dto.SubscriptionIds.Contains(s.SubscriptionId))
                .ToListAsync();

            if (!activeSubscriptions.Any()) return BadRequest("No valid active subscriptions found to pause.");

            foreach (var sub in activeSubscriptions)
            {
                // Check if already got an overlapping vacation
                var exists = await _context.VacationRequests.AnyAsync(v => 
                    v.SubscriptionId == sub.SubscriptionId && 
                    v.IsActive == true && 
                    ((dto.StartDate >= v.StartDate && (!v.EndDate.HasValue || dto.StartDate <= v.EndDate.Value)) || 
                     (dto.EndDate >= v.StartDate && (!v.EndDate.HasValue || dto.EndDate <= v.EndDate.Value))));
                     
                if (exists) continue; // Skip if it already has a conflicting vacation scheduled
                
                var vacationRequest = new VacationRequest
                {
                    ReaderId = sub.ReaderId,
                    SubscriptionId = sub.SubscriptionId,
                    Category = sub.Category ?? "Unknown",
                    Name = sub.SubscriptionName ?? sub.ItemType,
                    StartDate = dto.StartDate.Date,
                    EndDate = dto.EndDate.Date,
                    TotalAmount = sub.TotalAmount,
                    IsActive = true
                };
                
                _context.VacationRequests.Add(vacationRequest);
                
                // If it starts today, pause immediately
                if (dto.StartDate.Date <= DateTime.UtcNow.Date && dto.EndDate.Date >= DateTime.UtcNow.Date) {
                    sub.IsActive = "Vacation";
                    sub.IsVacationMode = true;
                }
            }
            
            await _context.SaveChangesAsync();
            return Ok(new { message = "Vacation dates scheduled successfully." });
        }

        [HttpGet("GetPartnerSubscriptions/{partnerId}")]
        public async Task<ActionResult<IEnumerable<object>>> GetPartnerSubscriptions(int partnerId)
        {
            var partner = await _context.DeliveryPartner.FindAsync(partnerId);
            if (partner == null) return NotFound("Partner not found.");

            var readerIdsInArea = await _context.Reader
                .Where(r => r.AddedByPartnerCode == partner.PartnerCode)
                .Select(r => r.ReaderId)
                .ToListAsync();

            var subscriptions = await _context.Subscriptions
                .Where(s => readerIdsInArea.Contains(s.ReaderId))
                .Select(s => new {
                    s.SubscriptionId,
                    s.ReaderId, // Added for completeness
                    ReaderName = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.FullName).FirstOrDefault(),
                    ReaderPhone = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.PhoneNumber).FirstOrDefault(),
                    s.SubscriptionName,
                    s.ItemType,
                    s.Category,
                    s.DurationMonths,
                    s.TotalAmount,
                    s.IsActive,
                    HouseName = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.HouseName).FirstOrDefault(),
                    HouseNo = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.HouseNo).FirstOrDefault(),
                    PanchayatName = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.PanchayatName).FirstOrDefault(),
                    WardNumber = _context.Reader.Where(r => r.ReaderId == s.ReaderId).Select(r => r.WardNumber).FirstOrDefault(),
                    ItemName = !string.IsNullOrEmpty(s.SubscriptionName) ? s.SubscriptionName : (s.ItemType == "Newspaper" 
                        ? _context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.Name).FirstOrDefault()
                        : _context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.Name).FirstOrDefault())
                })
                .ToListAsync();

            return Ok(subscriptions);
        }

        // Get vacation mode information for admin
        [HttpGet("GetVacationModeData")]
        public async Task<IActionResult> GetVacationModeData()
        {
            try
            {
                var today = DateTime.UtcNow.Date;

                // Get all readers with their subscriptions in vacation mode
                var vacationReaders = await (from r in _context.Reader
                                           join s in _context.Subscriptions
                                           on r.ReaderId equals s.ReaderId
                                           where s.IsActive == "Vacation" && s.IsVacationMode == true
                                           select new
                                           {
                                               r.ReaderId,
                                               r.FullName,
                                               r.PhoneNumber,
                                               r.PanchayatName,
                                               r.AddedByPartnerCode,
                                               s.SubscriptionId,
                                               s.SubscriptionName,
                                               s.ItemType,
                                               s.Category,
                                               VacationStartDate = _context.VacationRequests
                                                   .Where(v => v.SubscriptionId == s.SubscriptionId && v.IsActive == true)
                                                   .OrderByDescending(v => v.StartDate)
                                                   .Select(v => v.StartDate)
                                                   .FirstOrDefault(),
                                               VacationEndDate = _context.VacationRequests
                                                   .Where(v => v.SubscriptionId == s.SubscriptionId && v.IsActive == true)
                                                   .OrderByDescending(v => v.StartDate)
                                                   .Select(v => v.EndDate)
                                                   .FirstOrDefault(),
                                               r.HouseName,
                                               r.HouseNo,
                                               r.Landmark,
                                               r.WardNumber,
                                               r.Pincode
                                           }).ToListAsync();

                // Get upcoming vacations (scheduled but not yet started)
                var upcomingVacations = await (from v in _context.VacationRequests
                                             join r in _context.Reader
                                             on v.ReaderId equals r.ReaderId
                                             join s in _context.Subscriptions
                                             on v.SubscriptionId equals s.SubscriptionId
                                             where v.IsActive == true && v.StartDate > today
                                             select new
                                             {
                                                 r.ReaderId,
                                                 r.FullName,
                                                 r.PhoneNumber,
                                                 r.PanchayatName,
                                                 r.AddedByPartnerCode,
                                                 s.SubscriptionId,
                                                 s.SubscriptionName,
                                                 s.ItemType,
                                                 s.Category,
                                                 v.StartDate,
                                                 v.EndDate,
                                                 r.HouseName,
                                                 r.HouseNo,
                                                 r.Landmark,
                                                 r.WardNumber,
                                                 r.Pincode
                                             }).ToListAsync();

                // Get delivery partners info
                var partners = await _context.DeliveryPartner
                    .Select(p => new
                    {
                        p.DeliveryPartnerId,
                        p.PartnerCode,
                        p.FullName,
                        p.PhoneNumber,
                        p.PanchayatName
                    }).ToListAsync();

                return Ok(new
                {
                    currentVacations = vacationReaders,
                    upcomingVacations = upcomingVacations,
                    deliveryPartners = partners
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
        // Get all reader subscriptions for admin
        [HttpGet("GetAllSubscriptionsWithDetails")]
        public async Task<ActionResult<IEnumerable<object>>> GetAllSubscriptionsWithDetails()
        {
            try
            {
                var today = DateTime.UtcNow.Date;
                var subscriptions = await _context.Subscriptions
                    .Include(s => s.Reader)
                    .ToListAsync();

                var detailedSubscriptions = subscriptions.Select(s => {
                    // Calculate Next Bill Date logic
                    // If subscription is monthly, find the next occurrence of StartDate's day
                    DateTime? nextBillDate = null;
                    if (s.EndDate >= today)
                    {
                        var potentialNext = s.StartDate;
                        while (potentialNext <= today && potentialNext < s.EndDate)
                        {
                            potentialNext = potentialNext.AddMonths(1);
                        }
                        if (potentialNext <= s.EndDate)
                        {
                            nextBillDate = potentialNext;
                        }
                    }

                    return new
                    {
                        s.SubscriptionId,
                        s.ReaderId,
                        ReaderName = s.Reader?.FullName ?? "Unknown",
                        ReaderPhone = s.Reader?.PhoneNumber ?? "",
                        ItemName = !string.IsNullOrEmpty(s.SubscriptionName) ? s.SubscriptionName : (s.ItemType == "Newspaper" 
                            ? _context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.Name).FirstOrDefault()
                            : _context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.Name).FirstOrDefault()),
                        ItemType = s.ItemType == "Newspaper" 
                            ? (_context.Newspapers.Where(n => n.NewspaperId == s.PublicationId).Select(n => n.ItemType).FirstOrDefault() ?? "Newspaper")
                            : (_context.Magazines.Where(m => m.MagazineId == s.PublicationId).Select(m => m.ItemType).FirstOrDefault() ?? "Magazine"),
                        s.DurationMonths,
                        s.TotalAmount,
                        s.StartDate,
                        s.EndDate,
                        s.IsVacationMode,
                        s.IsActive, // This stores 'Active', 'Vacation', etc.
                        HouseName = s.Reader?.HouseName,
                        HouseNo = s.Reader?.HouseNo,
                        PanchayatName = s.Reader?.PanchayatName,
                        WardNumber = s.Reader?.WardNumber,
                        Landmark = s.Reader?.Landmark,
                        Pincode = s.Reader?.Pincode,
                        PartnerCode = s.Reader?.AddedByPartnerCode ?? "No Partner",
                        NextBillDate = nextBillDate
                    };
                }).ToList();

                return Ok(detailedSubscriptions);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
