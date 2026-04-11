import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../auth/setup_new_password_screen.dart';

import 'package:vaarthahub_app/services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String emailOrPhone;

  const OtpVerificationScreen({
    super.key,
    required this.emailOrPhone,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // --- OTP VERIFICATION FUNCTION ---
  Future<void> _verifyOtp() async {
    final identifier = widget.emailOrPhone;
    String otp = _controllers.map((controller) => controller.text).join();

    if (otp.length < 4) {
      _showMessage("Please enter the 4-digit code", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Auth/verify-otp');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": identifier,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showMessage("OTP Verified Successfully!", Colors.green);
        Navigator.push(context,
          MaterialPageRoute(
            builder: (context) => SetupNewPasswordScreen(emailOrPhone: identifier)
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage(errorData['message'] ?? "Invalid OTP!", Colors.redAccent);
      }
    } catch (e) {
      _showMessage("Connection error!", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- OTP (Send Again) ---
  Future<void> _resendOtp() async {
    _showMessage("Resending OTP...", Colors.blue);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Auth/forgot-password');
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": widget.emailOrPhone,
          "method": widget.emailOrPhone.contains('@') ? "Email" : "SMS",
        }),
      );
    } catch (e) {
       _showMessage("Error resending code.", Colors.redAccent);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset('assets/ui_elements/element3.png', fit: BoxFit.fill),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  _buildAvatarSection(),
                  const SizedBox(height: 45),
                  const Text(
                    "Verification",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Enter 4-digits code we sent you\non your registered identifier",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.emailOrPhone, 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 30),

                  // 4-Digit OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) => _buildOtpBox(index)),
                  ),

                  const SizedBox(height: 80),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C55E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Send Again Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resendOtp,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF9C55E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Send Again", style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 55,
      height: 55,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: const Color(0xFFF2F5FE),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: const CircleAvatar(
        radius: 70,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 62,
          backgroundImage: AssetImage('assets/images/avatar.png'),
        ),
      ),
    );
  }
}