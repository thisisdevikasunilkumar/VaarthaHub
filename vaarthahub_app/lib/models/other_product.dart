class OtherProduct {
  final int productId;
  final int itemId;
  final String itemType;
  final int newspaperId;
  final String name;
  final String? productType;
  final String? size;
  final String year;
  final double unitPrice;
  final String? imageUrl;
  final bool isActive;

  OtherProduct({
    required this.productId,
    required this.itemId,
    required this.itemType,
    required this.newspaperId,
    required this.name,
    this.productType,
    this.size,
    required this.year,
    required this.unitPrice,
    this.imageUrl,
    required this.isActive,
  });

  factory OtherProduct.fromJson(Map<String, dynamic> json) {
    return OtherProduct(
      productId: json['productId'] ?? 0,
      itemId: json['itemId'] ?? 0,
      itemType: json['itemType'] ?? '',
      newspaperId: json['newspaperId'] ?? 0,
      name: json['name'] ?? '',
      productType: json['productType'] as String?,
      size: json['size'] as String?,
      year: json['year'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId.toString(),
      'itemId': itemId.toString(),
      'itemType': itemType,
      'newspaperId': newspaperId.toString(),
      'name': name,
      'productType': productType,
      'size': size,
      'year': year,
      'unitPrice': unitPrice.toString(),
      'isActive': isActive.toString(),
    };
  }
}
