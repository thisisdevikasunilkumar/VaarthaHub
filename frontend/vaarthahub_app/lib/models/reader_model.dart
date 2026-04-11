class ReaderModel {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String panchayatName;
  final String addedByPartnerCode;
  final String? address;
  final String? wardNumber;
  final DateTime? createdAt;

  ReaderModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.panchayatName,
    required this.addedByPartnerCode,
    this.address,
    this.wardNumber,
    this.createdAt,
  });

  // POST - Add Reader (Updated)
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'panchayatName': panchayatName,
        'addedByPartnerCode': addedByPartnerCode,
      };

  // GET - Fetch Readers (Updated)
  factory ReaderModel.fromJson(Map<String, dynamic> json) {
    return ReaderModel(
      id: json['readerId'],
      fullName: json['fullName'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      panchayatName: json['panchayatName'] ?? "",
      addedByPartnerCode: json['addedByPartnerCode'] ?? "",
      address: json['address'],
      wardNumber: json['wardNumber'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}