import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../auth/otp_verification_screen.dart';

import 'package:vaarthahub_app/services/api_service.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  final String? emailOrPhone;

  const PasswordRecoveryScreen({super.key, this.emailOrPhone});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _identifierController = TextEditingController();
  String _selectedMethod = "SMS";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.emailOrPhone != null && widget.emailOrPhone!.isNotEmpty) {
      _identifierController.text = widget.emailOrPhone!;
      _selectedMethod = _isEmail(widget.emailOrPhone!) ? "Email" : "SMS";
    }
  }

  bool _isEmail(String value) {
    return value.contains("@");
  }

  // --- API Call Logic ---
  Future<void> _handleNextStep() async {
    final identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showError("Please enter your registered Email or Phone");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Auth/forgot-password');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": identifier,
          "method": _selectedMethod,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        // Go to OTP Verification Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(emailOrPhone: identifier),
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        _showError(errorData['message'] ?? "User not found!");
      }
    } catch (e) {
      _showError("Connection error! Please check your server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
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
                    "Password Recovery",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "How you would like to restore \nyour password?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 30),
                  
                  // Identifier Input Field
                  TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      hintText: "Email or Phone Number",
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: const Color(0xFFF2F5FE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _buildRecoveryOption(
                    title: "SMS",
                    isSelected: _selectedMethod == "SMS",
                    onTap: () => setState(() => _selectedMethod = "SMS"),
                    activeColor: const Color(0xFFE8EEFF),
                    checkColor: Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  _buildRecoveryOption(
                    title: "Email",
                    isSelected: _selectedMethod == "Email",
                    onTap: () => setState(() => _selectedMethod = "Email"),
                    activeColor: const Color(0xFFFFE8E8),
                    checkColor: Colors.redAccent,
                  ),

                  const SizedBox(height: 60),

                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNextStep,
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

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF9C55E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Cancel", style: TextStyle(fontSize: 18, color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
            ),
          ),
        ],
      ),
    );
  }

  // Avatar Widget
  Widget _buildAvatarSection() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: CircleAvatar(
        radius: 70,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 62,
          backgroundImage: const AssetImage('assets/images/avatar.png'),
        ),
      ),
    );
  }

  // Option Tile Widget
  Widget _buildRecoveryOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
    required Color checkColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: checkColor, width: 1) : null,
        ),
        child: Row(
          children: [
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
            const Spacer(),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? checkColor : Colors.grey,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}