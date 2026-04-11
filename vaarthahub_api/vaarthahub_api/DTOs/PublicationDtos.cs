namespace vaarthahub_api.DTOs
{
    public class AddNewspaperDto
    {
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string PaperType { get; set; } = string.Empty;
        public decimal BasePrice { get; set; }
        public string? LogoBase64 { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class AddMagazineDto
    {
        public int NewspaperId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string PublicationCycle { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? LogoBase64 { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class UpdateNewspaperDto
    {
        public int NewspaperId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string PaperType { get; set; } = string.Empty;
        public decimal BasePrice { get; set; }
        public string? LogoBase64 { get; set; }
        public bool IsActive { get; set; }
    }

    public class UpdateMagazineDto
    {
        public int MagazineId { get; set; }
        public int NewspaperId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string PublicationCycle { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string? LogoBase64 { get; set; }
        public bool IsActive { get; set; }
    }
}
