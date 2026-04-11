using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.DTOs;
using System.Text.RegularExpressions;
using System.Linq;
using System.Threading.Tasks;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatBotController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public ChatBotController(ApplicationDbContext context)
        {
            _context = context;
        }

        [HttpPost("Query")]
        public async Task<IActionResult> Query([FromBody] ChatBotQueryDto dto)
        {
            if (string.IsNullOrEmpty(dto.Query)) return BadRequest("Query cannot be empty.");

            var query = dto.Query.ToLower();
            var reader = await _context.Reader.FindAsync(dto.ReaderId);
            if (reader == null) return NotFound("Reader not found.");

            string response = "";

            // Intention detection using keywords
            bool isBill = Regex.IsMatch(query, @"\b(bill|billu|ബില്ല്|ബിൽ|paisa|panam|തുക|thuka|amount|charge|pay|payment)\b");
            bool isBalance = Regex.IsMatch(query, @"\b(balance|ബാക്കി|bakki|എത്രയുണ്ട്|ethrayund|ethra)\b");
            bool isSubscription = Regex.IsMatch(query, @"\b(subscription|സബ്സ്ക്രിപ്ഷൻ|sub|details|info|vivaram|വിവരങ്ങൾ|ഏതൊക്കെ|pathram|magazine|newspaper)\b");
            bool isVacation = Regex.IsMatch(query, @"\b(vacation|ലീവ്|leave|holiday|യാത്ര|yathra|poka|off|stop|pause|maatti|maattan)\b");
            bool isGreeting = Regex.IsMatch(query, @"\b(hi|hello|hey|ഹലോ|ഹായ്|namaskaram|നമസ്കാരം)\b");
            bool isSwap = Regex.IsMatch(query, @"\b(swap|മാറ്റം|exchange|magazine swap|swap now|maattan|maatti)\b");
            bool isSubscribeHow = Regex.IsMatch(query, @"\b(subscribe|സബ്സ്ക്രൈബ്|join|new|start|എവിടെ|where|how to subscribe|engane|edukkan)\b");
            bool isAnnouncement = Regex.IsMatch(query, @"\b(announcement|അറിയിപ്പ്|booking|ad|പരസ്യം|parasyam|remembrance|birthday|wishes|anniversary)\b");
            bool isArticle = Regex.IsMatch(query, @"\b(article|ലേഖനം|lekhonam|submit|write|corner|കഥ|കവിത|katha|kavitha|സൃഷ്ടികൾ|readers corner)\b");

            if (isBill || isBalance)
            {
                var subs = await _context.Subscriptions
                    .Where(s => s.ReaderId == dto.ReaderId && s.IsActive == "Active")
                    .ToListAsync();
                
                decimal total = subs.Sum(s => s.TotalAmount);
                if (total == 0)
                {
                    response = "നിങ്ങൾക്ക് നിലവിൽ കുടിശ്ശിക ഒന്നുമില്ല. (You have no pending bills.)";
                }
                else
                {
                    response = $"നിങ്ങളുടെ നിലവിലെ ബില്ല് തുക ₹{total} ആണ്. (Your current bill amount is ₹{total}.)";
                }
            }
            else if (isSubscription && !isSubscribeHow)
            {
                var subs = await _context.Subscriptions
                    .Where(s => s.ReaderId == dto.ReaderId)
                    .ToListAsync();

                if (!subs.Any())
                {
                    response = "നിങ്ങൾക്ക് സജീവമായ സബ്സ്ക്രിപ്ഷനുകൾ ഒന്നുമില്ല. (You don't have any active subscriptions.)";
                }
                else
                {
                    var subNames = subs.Select(s => s.SubscriptionName ?? s.ItemType).ToList();
                    string list = string.Join(", ", subNames);
                    response = $"നിങ്ങൾ ഇപ്പോൾ {list} എന്നിവ സബ്സ്ക്രൈബ് ചെയ്തിട്ടുണ്ട്. (You are currently subscribed to: {list}.)";
                }
            }
            else if (isSubscribeHow)
            {
                response = "പുതിയ പത്രങ്ങളോ മാഗസിനുകളോ സബ്സ്ക്രൈബ് ചെയ്യാൻ 'Category' സെക്ഷനിൽ പോയി നിങ്ങൾക്ക് ഇഷ്ടമുള്ളത് തിരഞ്ഞെടുക്കാം. (To subscribe to new newspapers or magazines, go to the 'Category' section and select your choice.)";
            }
            else if (isSwap)
            {
                response = "മാഗസിൻ സ്വാപ്പ് ചെയ്യാൻ: Categories -> Community -> Magazine Swap എന്ന ക്രമത്തിൽ പോയി 'Swap Now' ക്ലിക്ക് ചെയ്യുക. (To swap magazines: Go to Categories -> Community -> Magazine Swap and click 'Swap Now'.)";
            }
            else if (isAnnouncement)
            {
                response = "പരസ്യങ്ങൾ ബുക്ക് ചെയ്യാൻ Categories -> Announcement സെക്ഷനിൽ പോയി നിങ്ങൾക്ക് വേണ്ട കാർഡ് (Remembrance, Birthday, etc.) തിരഞ്ഞെടുക്കാം. (To book announcements, go to Categories -> Announcement and select the card you need like Remembrance, Birthday, etc.)";
            }
            else if (isArticle)
            {
                response = "നിങ്ങളുടെ ലേഖനങ്ങളും സൃഷ്ടികളും സമർപ്പിക്കാൻ: Categories -> Community -> Reader's Corner എന്ന ഓപ്ഷൻ ഉപയോഗിക്കുക. (To submit your articles and creations, use the Categories -> Community -> Reader's Corner option.)";
            }
            else if (isVacation)
            {
                var vacations = await _context.VacationRequests
                    .Where(v => v.ReaderId == dto.ReaderId && v.IsActive == true)
                    .ToListAsync();
                
                if (!vacations.Any())
                {
                    response = "നിങ്ങൾ നിലവിൽ വെക്കേഷൻ മോഡിൽ അല്ല. (You are not currently in vacation mode.)";
                }
                else
                {
                    var latest = vacations.OrderByDescending(v => v.StartDate).First();
                    response = $"നിങ്ങൾ വെക്കേഷൻ മോഡിലാണ്. ഇത് {latest.EndDate?.ToString("dd-MM-yyyy") ?? "അടുത്ത അറിയിപ്പ് വരെ"} തുടരും. (You are on vacation mode until {latest.EndDate?.ToString("dd-MM-yyyy") ?? "further notice"}.)";
                }
            }
            else if (isGreeting)
            {
                response = $"ഹലോ {reader.FullName}! ഞാൻ വാർത്താബോട്ട്. നിങ്ങളെ എങ്ങനെ സഹായിക്കണം? (Hello! I'm VaarthaBot. How can I help you today?)";
            }
            else
            {
                response = "ക്ഷമിക്കണം, എനിക്ക് അത് മനസ്സിലായില്ല. ബില്ല്, ബാലൻസ് അല്ലെങ്കിൽ സബ്സ്ക്രിപ്ഷൻ വിവരങ്ങൾ എന്നിവയെക്കുറിച്ച് എന്നോട് ചോദിക്കാം. (Sorry, I didn't get that. You can ask about bills, balance, or subscription details.)";
            }

            return Ok(new { response });
        }
    }
}
