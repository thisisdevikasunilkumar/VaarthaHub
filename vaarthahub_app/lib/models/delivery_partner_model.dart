class DeliveryPartnerModel {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String vehicleType;
  final String vehicleNumber;
  final String licenseNumber;
  final String panchayatName;
  final double basicSalary;
  final double? monthlyEarnings;
  final double averageRating;
  final String status;

  DeliveryPartnerModel({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.licenseNumber,
    required this.panchayatName,
    required this.basicSalary,
    this.monthlyEarnings,
    this.averageRating = 0.0,
    this.status = "Delivering",
  });

  // 1. (POST - Add Partner)
  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'licenseNumber': licenseNumber,
        'panchayatName': panchayatName,
        'basicSalary': basicSalary,
      };

  // 2. (GET - List Partners)
  factory DeliveryPartnerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerModel(
      id: json['deliveryPartnerId'],
      fullName: json['fullName'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      vehicleType: json['vehicleType'] ?? "",
      vehicleNumber: json['vehicleNumber'] ?? "",
      licenseNumber: json['licenseNumber'] ?? "",
      panchayatName: json['panchayatName'] ?? "",
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      monthlyEarnings: (json['totalMonthlyEarnings'] as num?)?.toDouble() ?? 0.0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? (json['deliveryPartnerId'] % 2 == 0 ? "Delivering" : "InActive"),
    );
  }
}