namespace vaarthahub_api.DTOs
{
    public class ComplaintDto
    {
        public string ReaderCode { get; set; } = string.Empty;
        public string ComplaintType { get; set; } = string.Empty;
        public string? Comments { get; set; }
    }
}
