using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using vaarthahub_api.Data;
using vaarthahub_api.DTOs;
using vaarthahub_api.Models;

namespace vaarthahub_api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SwapRequestsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;

        public SwapRequestsController(ApplicationDbContext context)
        {
            _context = context;
        }

        // POST: api/SwapRequests/request
        [HttpPost("request")]
        public async Task<IActionResult> CreateSwapRequest([FromBody] AddSwapRequestDto dto)
        {
            var swapRequest = new SwapRequest
            {
                RequestReaderId = dto.RequestReaderId,
                OfferedMagazine = dto.OfferedMagazine,
                IssueEdition = dto.IssueEdition,
                RequestedMagazine = dto.RequestedMagazine,
                MagazinePrice = dto.MagazinePrice,
                Category = dto.Category,
                Condition = dto.Condition,
                Status = "Requested",
                CreatedAt = DateTime.Now
            };

            _context.SwapRequests.Add(swapRequest);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Swap request listed successfully", swapId = swapRequest.SwapId });
        }

        // GET: api/SwapRequests/available-requests/{readerId}
        [HttpGet("available-requests/{readerId}")]
        public async Task<IActionResult> GetAvailableRequests(int readerId)
        {
            var currentReader = await _context.Reader.FindAsync(readerId);
            if (currentReader == null) return NotFound(new { message = "Reader not found" });

            string partnerCode = currentReader.AddedByPartnerCode;

            var requests = await (from s in _context.SwapRequests
                                  join r in _context.Reader on s.RequestReaderId equals r.ReaderId
                                  where s.Status == "Requested" && 
                                        s.RequestReaderId != readerId && 
                                        s.ReceiverReaderId == 0 &&
                                        r.AddedByPartnerCode == partnerCode
                                  orderby s.CreatedAt descending
                                  select new
                                  {
                                      s.SwapId,
                                      s.RequestReaderId,
                                      RequestorName = r.FullName,
                                      s.OfferedMagazine,
                                      s.IssueEdition,
                                      s.RequestedMagazine,
                                      s.MagazinePrice,
                                      s.Category,
                                      s.Condition,
                                      s.CreatedAt
                                  }).ToListAsync();

            return Ok(requests);
        }

        // GET: api/SwapRequests/reader/{readerId}
        [HttpGet("reader/{readerId}")]
        public async Task<IActionResult> GetReaderSwaps(int readerId)
        {
            var requests = await (from s in _context.SwapRequests
                                  join reqReader in _context.Reader on s.RequestReaderId equals reqReader.ReaderId into reqJoin
                                  from req in reqJoin.DefaultIfEmpty()
                                  join recReader in _context.Reader on s.ReceiverReaderId equals recReader.ReaderId into recJoin
                                  from rec in recJoin.DefaultIfEmpty()
                                  where s.RequestReaderId == readerId || s.ReceiverReaderId == readerId
                                  orderby s.CreatedAt descending
                                  select new
                                  {
                                      s.SwapId,
                                      IsInitiator = s.RequestReaderId == readerId,
                                      OtherPartyName = s.RequestReaderId == readerId 
                                          ? (s.ReceiverReaderId != 0 && rec != null ? rec.FullName : "Waiting...") 
                                          : (req != null ? req.FullName : "Unknown"),
                                      s.OfferedMagazine,
                                      s.IssueEdition,
                                      s.RequestedMagazine,
                                      s.MagazinePrice,
                                      s.RequestedMagazinePrice,
                                      s.Status,
                                      s.CreatedAt,
                                      s.CompletedAt,
                                      ProposalCount = _context.SwapProposals.Count(p => p.SwapRequestId == s.SwapId && p.Status == "Pending")
                                  }).ToListAsync();

            return Ok(requests);
        }

        // POST: api/SwapRequests/propose/{swapId}
        [HttpPost("propose/{swapId}")]
        public async Task<IActionResult> ProposeSwapRequest(int swapId, [FromBody] AcceptSwapRequestDto dto)
        {
            var request = await _context.SwapRequests.FindAsync(swapId);
            if (request == null) return NotFound(new { message = "Request not found" });

            if (request.Status != "Requested")
                return BadRequest(new { message = "Request is no longer available" });

            if (request.RequestReaderId == dto.ReceiverReaderId)
                return BadRequest(new { message = "You cannot swap with yourself" });

            // Check if this user already proposed
            var existingProposal = await _context.SwapProposals
                .FirstOrDefaultAsync(p => p.SwapRequestId == swapId && p.ReceiverReaderId == dto.ReceiverReaderId);
            
            if (existingProposal != null)
                return BadRequest(new { message = "You have already proposed a swap for this magazine." });

            var proposal = new SwapProposal
            {
                SwapRequestId = swapId,
                ReceiverReaderId = dto.ReceiverReaderId,
                OfferedMagazinePrice = dto.RequestedMagazinePrice,
                Status = "Pending",
                CreatedAt = DateTime.Now
            };

            _context.SwapProposals.Add(proposal);

            // Create Notification for the owner
            var owner = await _context.Reader.FindAsync(request.RequestReaderId);
            var proposer = await _context.Reader.FindAsync(dto.ReceiverReaderId);
            
            if (owner != null && proposer != null)
            {
                var notification = new Notification
                {
                    UserCode = owner.ReaderCode,
                    Title = "New Swap Proposal",
                    Message = $"{proposer.FullName} has proposed a swap for your magazine '{request.OfferedMagazine}'.",
                    RelatedId = swapId,
                    Type = "SwapProposal",
                    CreatedAt = DateTime.Now
                };
                _context.Notifications.Add(notification);
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Swap proposal sent to the owner." });
        }

        // GET: api/SwapRequests/{swapId}/proposals
        [HttpGet("{swapId}/proposals")]
        public async Task<IActionResult> GetSwapProposals(int swapId)
        {
            var proposals = await (from p in _context.SwapProposals
                                   join r in _context.Reader on p.ReceiverReaderId equals r.ReaderId
                                   where p.SwapRequestId == swapId && p.Status == "Pending"
                                   select new
                                   {
                                       p.ProposalId,
                                       p.ReceiverReaderId,
                                       ReceiverName = r.FullName,
                                       p.OfferedMagazinePrice,
                                       p.CreatedAt
                                   }).ToListAsync();

            return Ok(proposals);
        }

        // PUT: api/SwapRequests/accept-proposal/{proposalId}
        [HttpPut("accept-proposal/{proposalId}")]
        public async Task<IActionResult> AcceptProposal(int proposalId)
        {
            var proposal = await _context.SwapProposals.FindAsync(proposalId);
            if (proposal == null) return NotFound(new { message = "Proposal not found" });

            var request = await _context.SwapRequests.FindAsync(proposal.SwapRequestId);
            if (request == null) return NotFound(new { message = "Request not found" });

            if (request.Status != "Requested")
                return BadRequest(new { message = "Swap request is no longer available" });

            // Accept this proposal
            proposal.Status = "Accepted";
            
            // Reject other proposals
            var otherProposals = await _context.SwapProposals
                .Where(p => p.SwapRequestId == request.SwapId && p.ProposalId != proposalId)
                .ToListAsync();
            
            foreach (var op in otherProposals)
            {
                op.Status = "Rejected";
            }

            // Update SwapRequest
            request.ReceiverReaderId = proposal.ReceiverReaderId;
            request.RequestedMagazinePrice = proposal.OfferedMagazinePrice;
            request.Status = "Pending";
            
            // Calculate fees (50% of respective prices)
            request.ServiceFee_Requestor = Math.Round(request.MagazinePrice * 0.50m, 2);
            request.ServiceFee_Receiver = Math.Round(request.RequestedMagazinePrice * 0.50m, 2);

            // Create Notification for the proposer
            var proposer = await _context.Reader.FindAsync(proposal.ReceiverReaderId);
            if (proposer != null)
            {
                var notification = new Notification
                {
                    UserCode = proposer.ReaderCode,
                    Title = "Swap Proposal Accepted!",
                    Message = $"Your proposal for '{request.OfferedMagazine}' has been accepted. A delivery partner will contact you soon.",
                    RelatedId = request.SwapId,
                    Type = "SwapAccepted",
                    CreatedAt = DateTime.Now
                };
                _context.Notifications.Add(notification);

                // ALSO: Notify the Delivery Partner of this area
                var requestor = await _context.Reader.FindAsync(request.RequestReaderId);
                if (requestor != null && !string.IsNullOrEmpty(requestor.AddedByPartnerCode))
                {
                    var deliveryNotification = new Notification
                    {
                        UserCode = requestor.AddedByPartnerCode,
                        Title = "New Swap Action Required",
                        Message = $"A magazine swap between {requestor.FullName} and {proposer.FullName} is now pending your delivery.",
                        RelatedId = request.SwapId,
                        Type = "SwapDeliveryPending",
                        CreatedAt = DateTime.Now
                    };
                    _context.Notifications.Add(deliveryNotification);
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Proposal accepted successfully" });
        }

        // (Legacy endpoint kept for compatibility if needed, but logic moved to accept-proposal)
        // PUT: api/SwapRequests/accept/{swapId}
        [HttpPut("accept/{swapId}")]
        public async Task<IActionResult> AcceptSwapRequest(int swapId)
        {
            return BadRequest(new { message = "Please use accept-proposal/{proposalId} instead." });
        }

        // GET: api/SwapRequests/pending/{partnerCode}
        [HttpGet("pending/{partnerCode}")]
        public async Task<IActionResult> GetPendingSwaps(string partnerCode)
        {
            var requests = await (from s in _context.SwapRequests
                                  join reqReader in _context.Reader on s.RequestReaderId equals reqReader.ReaderId into reqJoin
                                  from req in reqJoin.DefaultIfEmpty()
                                  join recReader in _context.Reader on s.ReceiverReaderId equals recReader.ReaderId into recJoin
                                  from rec in recJoin.DefaultIfEmpty()
                                  where s.Status == "Pending" && req.AddedByPartnerCode == partnerCode
                                  orderby s.CreatedAt descending
                                  select new
                                  {
                                      s.SwapId,
                                      RequestorName = req != null ? req.FullName : "Unknown",
                                      ReceiverName = rec != null ? rec.FullName : "",
                                      s.OfferedMagazine,
                                      s.IssueEdition,
                                      s.RequestedMagazine,
                                      s.ServiceFee_Requestor,
                                      s.ServiceFee_Receiver,
                                      TotalServiceFee = s.ServiceFee_Requestor + s.ServiceFee_Receiver,
                                      s.Status,
                                      s.CreatedAt
                                  }).ToListAsync();

            return Ok(requests);
        }
        // GET: api/SwapRequests/completed/{partnerCode}
        [HttpGet("completed/{partnerCode}")]
        public async Task<IActionResult> GetCompletedSwaps(string partnerCode)
        {
            var requests = await (from s in _context.SwapRequests
                                  join reqReader in _context.Reader on s.RequestReaderId equals reqReader.ReaderId into reqJoin
                                  from req in reqJoin.DefaultIfEmpty()
                                  join recReader in _context.Reader on s.ReceiverReaderId equals recReader.ReaderId into recJoin
                                  from rec in recJoin.DefaultIfEmpty()
                                  where s.Status == "Completed" && s.AcceptedByPartnerCode == partnerCode
                                  orderby s.CompletedAt descending
                                  select new
                                  {
                                      s.SwapId,
                                      RequestorName = req != null ? req.FullName : "Unknown",
                                      ReceiverName = rec != null ? rec.FullName : "",
                                      s.OfferedMagazine,
                                      s.IssueEdition,
                                      s.RequestedMagazine,
                                      s.ServiceFee_Requestor,
                                      s.ServiceFee_Receiver,
                                      TotalServiceFee = s.ServiceFee_Requestor + s.ServiceFee_Receiver,
                                      s.Status,
                                      s.CreatedAt,
                                      s.CompletedAt
                                  }).ToListAsync();

            return Ok(requests);
        }

        // PUT: api/SwapRequests/complete/{swapId}
        [HttpPut("complete/{swapId}")]
        public async Task<IActionResult> CompleteSwapRequest(int swapId, [FromBody] CompleteSwapRequestDto dto)
        {
            var request = await _context.SwapRequests.FindAsync(swapId);
            if (request == null) return NotFound(new { message = "Request not found" });

            if (request.Status != "Pending")
                return BadRequest(new { message = "Request must be in Pending status to be completed" });

            request.Status = "Completed";
            request.CompletedAt = DateTime.Now;
            request.AcceptedByPartnerCode = dto.PartnerCode;
            request.TotalServiceFee = request.ServiceFee_Requestor + request.ServiceFee_Receiver;

            // Notify both readers that the swap is complete
            var requestor = await _context.Reader.FindAsync(request.RequestReaderId);
            var receiver = await _context.Reader.FindAsync(request.ReceiverReaderId);
            
            if (requestor != null)
            {
                _context.Notifications.Add(new Notification
                {
                    UserCode = requestor.ReaderCode,
                    Title = "Swap Completed!",
                    Message = $"Your swap for '{request.OfferedMagazine}' has been completed successfully.",
                    RelatedId = request.SwapId,
                    Type = "SwapCompleted",
                    CreatedAt = DateTime.Now
                });
            }

            if (receiver != null)
            {
                _context.Notifications.Add(new Notification
                {
                    UserCode = receiver.ReaderCode,
                    Title = "Swap Completed!",
                    Message = $"Your exchange for '{request.RequestedMagazine}' has been completed successfully.",
                    RelatedId = request.SwapId,
                    Type = "SwapCompleted",
                    CreatedAt = DateTime.Now
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Swap completed successfully", totalServiceFee = request.TotalServiceFee });
        }

        // DELETE: api/SwapRequests/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSwapRequest(int id)
        {
            var request = await _context.SwapRequests.FindAsync(id);
            if (request == null) return NotFound(new { message = "Request not found" });

            if (request.Status != "Requested")
                return BadRequest(new { message = "Only 'Requested' swaps can be removed." });

            _context.SwapRequests.Remove(request);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Swap request removed successfully" });
        }

        // PUT: api/SwapRequests/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateSwapRequest(int id, [FromBody] AddSwapRequestDto dto)
        {
            var request = await _context.SwapRequests.FindAsync(id);
            if (request == null) return NotFound(new { message = "Request not found" });

            if (request.Status != "Requested")
                return BadRequest(new { message = "Only 'Requested' swaps can be edited." });

            request.OfferedMagazine = dto.OfferedMagazine;
            request.IssueEdition = dto.IssueEdition;
            request.RequestedMagazine = dto.RequestedMagazine;
            request.MagazinePrice = dto.MagazinePrice;
            request.Category = dto.Category;
            request.Condition = dto.Condition;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Swap request updated successfully" });
        }
    }
}
