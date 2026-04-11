import 'delivery_vacation_reader.dart';

class DeliveryVacationDashboardData {
  final int readersOnVacationCount;
  final int papersSavedTodayCount;
  final int currentlyOnVacationCount;
  final List<DeliveryVacationReader> currentlyOnVacation;
  final List<DeliveryVacationReader> upcomingVacations;

  const DeliveryVacationDashboardData({
    required this.readersOnVacationCount,
    required this.papersSavedTodayCount,
    required this.currentlyOnVacationCount,
    required this.currentlyOnVacation,
    required this.upcomingVacations,
  });

  factory DeliveryVacationDashboardData.fromJson(Map<String, dynamic> json) {
    return DeliveryVacationDashboardData(
      readersOnVacationCount: parseInt(json['readersOnVacationCount']),
      papersSavedTodayCount: parseInt(json['papersSavedTodayCount']),
      currentlyOnVacationCount: parseInt(json['currentlyOnVacationCount']),
      currentlyOnVacation: _parseReaders(json['currentlyOnVacation']),
      upcomingVacations: _parseReaders(json['upcomingVacations']),
    );
  }

  static List<DeliveryVacationReader> _parseReaders(dynamic value) {
    if (value is! List) return const [];

    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return DeliveryVacationReader.fromJson(item);
          }
          if (item is Map) {
            return DeliveryVacationReader.fromJson(Map<String, dynamic>.from(item));
          }
          return null;
        })
        .whereType<DeliveryVacationReader>()
        .toList();
  }

  static int parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
