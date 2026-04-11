namespace vaarthahub_api.DTOs
{
    public class AddSwapRequestDto
    {
        public int RequestReaderId { get; set; }
        public string OfferedMagazine { get; set; } = string.Empty;
        public string? IssueEdition { get; set; }
        public string RequestedMagazine { get; set; } = string.Empty;
        public decimal MagazinePrice { get; set; }
        public string? Category { get; set; }
        public string? Condition { get; set; }
    }

    public class AcceptSwapRequestDto
    {
        public int ReceiverReaderId { get; set; }
        public decimal RequestedMagazinePrice { get; set; }
    }

    public class CompleteSwapRequestDto
    {
        public string PartnerCode { get; set; } = string.Empty;
    }
}
