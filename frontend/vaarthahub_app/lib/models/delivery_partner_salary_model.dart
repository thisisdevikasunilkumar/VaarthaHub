class DeliveryPartnerSalaryModel {
  final int? deliveryPartnerId;
  final double basicSalary;
  final double totalCommission;
  final double incentive;
  final String monthYear;
  final double totalMonthlyEarnings;
  final DateTime? basicSalaryLastUpdate;
  final DateTime? incentiveLastUpdate;

  DeliveryPartnerSalaryModel({
    this.deliveryPartnerId,
    required this.basicSalary,
    required this.totalCommission,
    required this.incentive,
    required this.monthYear,
    required this.totalMonthlyEarnings,
    this.basicSalaryLastUpdate,
    this.incentiveLastUpdate,
  });

  // 1. (GET - Salary History)
  factory DeliveryPartnerSalaryModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerSalaryModel(
      deliveryPartnerId: json['deliveryPartnerId'],
      basicSalary: (json['basicSalary'] as num?)?.toDouble() ?? 0.0,
      totalCommission: (json['totalCommission'] as num?)?.toDouble() ?? 0.0,
      incentive: (json['incentive'] as num?)?.toDouble() ?? 0.0,
      monthYear: json['monthYear'] ?? "",
      totalMonthlyEarnings: (json['totalMonthlyEarnings'] as num?)?.toDouble() ?? 0.0,
      basicSalaryLastUpdate: json['basicSalaryLastUpdate'] != null 
          ? DateTime.parse(json['basicSalaryLastUpdate']) 
          : null,
      incentiveLastUpdate: json['incentiveLastUpdate'] != null 
          ? DateTime.parse(json['incentiveLastUpdate']) 
          : null,
    );
  }

  // 2. (PUT - Salary Update)
  Map<String, dynamic> toJson() => {
        'deliveryPartnerId': deliveryPartnerId,
        'basicSalary': basicSalary,
        'incentive': incentive,
      };
}