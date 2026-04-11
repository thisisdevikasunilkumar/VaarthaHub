class Magazine {
  final int magazineId;
  final int itemId;
  final int newspaperId;
  final String name;
  final String category;
  final String publicationCycle;
  final double price;
  final String? logoUrl;
  final bool isActive;

  Magazine({
    required this.magazineId,
    required this.itemId,
    required this.newspaperId,
    required this.name,
    required this.category,
    required this.publicationCycle,
    required this.price,
    this.logoUrl,
    required this.isActive,
  });

  factory Magazine.fromJson(Map<String, dynamic> json) {
    return Magazine(
      magazineId: json['magazineId'] ?? 0,
      itemId: json['itemId'] ?? 2,
      newspaperId: json['newspaperId'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      publicationCycle: json['publicationCycle'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      logoUrl: json['logoUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}
