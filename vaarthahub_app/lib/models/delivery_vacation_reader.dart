class DeliveryVacationReader {
  final int readerId;
  final String readerName;
  final String houseLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> publicationNames;

  const DeliveryVacationReader({
    required this.readerId,
    required this.readerName,
    required this.houseLabel,
    required this.startDate,
    required this.endDate,
    required this.publicationNames,
  });

  factory DeliveryVacationReader.fromJson(Map<String, dynamic> json) {
    final publicationNames = (json['publicationNames'] as List<dynamic>?)
            ?.map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList() ??
        const [];

    return DeliveryVacationReader(
      readerId: _parseInt(json['readerId']),
      readerName: (json['readerName'] ?? 'Reader').toString(),
      houseLabel: (json['houseLabel'] ?? 'Address not available').toString(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      publicationNames: publicationNames,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
