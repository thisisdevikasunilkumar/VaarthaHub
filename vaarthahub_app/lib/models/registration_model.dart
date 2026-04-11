class RegistrationModel {
  final int? userId;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String? role;
  final String? profileImage;
  final String? userCode;

  RegistrationModel({
    this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    this.role,
    this.profileImage,
    this.userCode,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'email': email,
        'role': role ?? "Reader", 
        'profileImage': profileImage,
      };

  factory RegistrationModel.fromJson(Map<String, dynamic> json) {
    return RegistrationModel(
      userId: json['userId'],
      fullName: json['fullName'] ?? "",
      phoneNumber: json['phoneNumber'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "",
      profileImage: json['profileImage'] ?? "",
      userCode: json['userCode'] ?? "",
    );
  }
}