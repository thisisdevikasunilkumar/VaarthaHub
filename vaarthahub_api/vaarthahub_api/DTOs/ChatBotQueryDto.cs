namespace vaarthahub_api.DTOs
{
    public class ChatBotQueryDto
    {
        public int ReaderId { get; set; }
        public string Query { get; set; } = string.Empty;
    }
}
