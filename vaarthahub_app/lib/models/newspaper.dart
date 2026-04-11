class Newspaper {
  final int newspaperId;
  final int itemId;
  final String name;
  final String category;
  final String paperType;
  final double basePrice;
  final String? logoUrl;
  final bool isActive;

  Newspaper({
    required this.newspaperId,
    required this.itemId,
    required this.name,
    required this.category,
    required this.paperType,
    required this.basePrice,
    this.logoUrl,
    required this.isActive,
  });

  factory Newspaper.fromJson(Map<String, dynamic> json) {
    return Newspaper(
      newspaperId: json['newspaperId'] ?? 0,
      itemId: json['itemId'] ?? 1,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      paperType: json['paperType'] ?? '',
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      logoUrl: json['logoUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}
