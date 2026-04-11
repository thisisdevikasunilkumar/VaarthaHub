class Newspaper {
  final int id;
  final String name;
  final String language;
  final double baseDailyRate;
  final double? specialEditionRate;
  final String? imageUrl;
  final bool isActive;

  Newspaper({
    required this.id,
    required this.name,
    required this.language,
    required this.baseDailyRate,
    this.specialEditionRate,
    this.imageUrl,
    required this.isActive,
  });

  factory Newspaper.fromJson(Map<String, dynamic> json) {
    return Newspaper(
      id: json['id'],
      name: json['name'],
      language: json['language'],
      baseDailyRate: (json['baseDailyRate'] as num).toDouble(),
      specialEditionRate: json['specialEditionRate'] != null
          ? (json['specialEditionRate'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'language': language,
      'baseDailyRate': baseDailyRate,
      'specialEditionRate': specialEditionRate,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
