import 'package:vaarthahub_app/models/newspaper.dart';
import 'package:vaarthahub_app/models/reader_model.dart';
import 'package:vaarthahub_app/models/delivery_partner_model.dart';

class Subscription {
  final int id;
  final int readerId;
  final int newspaperId;
  final int? deliveryPartnerId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final Newspaper? newspaper;
  final ReaderModel? reader;
  final DeliveryPartnerModel? deliveryPartner;

  Subscription({
    required this.id,
    required this.readerId,
    required this.newspaperId,
    this.deliveryPartnerId,
    required this.startDate,
    this.endDate,
    required this.status,
    this.newspaper,
    this.reader,
    this.deliveryPartner,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      readerId: json['readerId'],
      newspaperId: json['newspaperId'],
      deliveryPartnerId: json['deliveryPartnerId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'],
      newspaper: json['newspaper'] != null
          ? Newspaper.fromJson(json['newspaper'])
          : null,
      reader: json['reader'] != null ? ReaderModel.fromJson(json['reader']) : null,
      deliveryPartner: json['deliveryPartner'] != null
          ? DeliveryPartnerModel.fromJson(json['deliveryPartner'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'readerId': readerId,
      'newspaperId': newspaperId,
      'deliveryPartnerId': deliveryPartnerId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
    };
  }
}

class VacationLog {
  final int id;
  final int subscriptionId;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  VacationLog({
    required this.id,
    required this.subscriptionId,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory VacationLog.fromJson(Map<String, dynamic> json) {
    return VacationLog(
      id: json['id'] ?? 0, // Id might be 0 for new objects
      subscriptionId: json['subscriptionId'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? 'Scheduled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriptionId': subscriptionId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
    };
  }
}
