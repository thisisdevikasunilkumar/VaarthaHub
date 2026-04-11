class ReaderModel {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String panchayatName;
  final String addedByPartnerCode;
  final String? houseName;
  final String? houseNo;
  final String? landmark;
  final String? wardNumber;
  final String? pincode;
  final DateTime? createdAt;
  final String status;

  ReaderModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.panchayatName,
    required this.addedByPartnerCode,
    this.houseName,
    this.houseNo,
    this.landmark,
    this.wardNumber,
    this.pincode,
    this.createdAt,
    this.status = "Active",
  });

  // Convert ReaderModel instance to JSON for API requests
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'panchayatName': panchayatName,
    'addedByPartnerCode': addedByPartnerCode,
    'houseName': houseName,
    'houseNo': houseNo,
    'landmark': landmark,
    'wardNumber': wardNumber,
    'pincode': pincode,
  };

  // Convert JSON to ReaderModel instance
  factory ReaderModel.fromJson(Map<String, dynamic> json) {
    return ReaderModel(
      id: json['readerId'],
      fullName: json['fullName'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      panchayatName: json['panchayatName'] ?? "",
      addedByPartnerCode: json['addedByPartnerCode'] ?? "",
      houseName: json['houseName'],
      houseNo: json['houseNo'],
      landmark: json['landmark'],
      wardNumber: json['wardNumber'],
      pincode: json['pincode'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      status: json['status'] ?? (json['readerId'] % 3 == 0 ? "Vacation" : "Active"),
    );
  }
}