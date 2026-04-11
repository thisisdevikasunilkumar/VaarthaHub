class DesignFrameItem {
  final int frameId;
  final String category;
  final String frameName;
  final String cardType;
  final String imagePath;
  bool isActive;
  final double price;

  DesignFrameItem({
    required this.frameId,
    required this.category,
    required this.frameName,
    required this.cardType,
    required this.imagePath,
    required this.isActive,
    required this.price,
  });

  factory DesignFrameItem.fromJson(Map<String, dynamic> json) {
    return DesignFrameItem(
      frameId: json['frameId'] as int? ?? 0,
      category: json['category']?.toString() ?? '',
      frameName: json['frameName']?.toString() ?? '',
      cardType: json['cardType']?.toString() ?? '',
      imagePath: json['imagePath']?.toString() ?? '',
      isActive: json['isActive'] as bool? ?? true,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get priceLabel => price.toStringAsFixed(2);
}