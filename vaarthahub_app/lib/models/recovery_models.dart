class ForgotPasswordRequest {
  final String emailOrPhone;
  final String method; // "SMS" or "Email"

  ForgotPasswordRequest({required this.emailOrPhone, required this.method});

  Map<String, dynamic> toJson() => {
        'emailOrPhone': emailOrPhone,
        'method': method,
      };
}

class VerifyOtpRequest {
  final String emailOrPhone;
  final String otp;

  VerifyOtpRequest({required this.emailOrPhone, required this.otp});

  Map<String, dynamic> toJson() => {
        'emailOrPhone': emailOrPhone,
        'otp': otp,
      };
}