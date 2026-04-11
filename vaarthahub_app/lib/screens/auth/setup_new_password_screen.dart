import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vaarthahub_app/services/api_service.dart';

class SetupNewPasswordScreen extends StatefulWidget {
  final String emailOrPhone;

  const SetupNewPasswordScreen({super.key, required this.emailOrPhone});

  @override
  State<SetupNewPasswordScreen> createState() => _SetupNewPasswordScreenState();
}

class _SetupNewPasswordScreenState extends State<SetupNewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController = TextEditingController();

  bool _isNewPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;
  bool _isLoading = false; 

  @override
  void dispose() {
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  // --- API CALL FUNCTION ---
  Future<void> _handleSave() async {
    String newPass = _newPasswordController.text;
    String repeatPass = _repeatPasswordController.text;

    if (newPass.isEmpty || repeatPass.isEmpty) {
      _showFeedback("Please fill in both fields", Colors.orange);
      return;
    }

    if (newPass != repeatPass) {
      _showFeedback("Passwords do not match!", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Auth/reset-password');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "emailOrPhone": widget.emailOrPhone, 
          "newPassword": newPass,
        }),
      );

      if (response.statusCode == 200) {
        _showFeedback("Password updated successfully!", Colors.green);
        
        // Navigate to Login Screen after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
        });
      } else {
        final errorData = jsonDecode(response.body);
        _showFeedback(errorData['message'] ?? "Update failed!", Colors.redAccent);
      }
    } catch (e) {
      _showFeedback("Connection Error!", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
                    "Setup New Password",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Please, setup a new password for\nyour account",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  _buildPasswordField(
                    controller: _newPasswordController,
                    hint: "New Password",
                    isVisible: _isNewPasswordVisible,
                    onToggle: () => setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(
                    controller: _repeatPasswordController,
                    hint: "Repeat Password",
                    isVisible: _isRepeatPasswordVisible,
                    onToggle: () => setState(() => _isRepeatPasswordVisible = !_isRepeatPasswordVisible),
                  ),

                  const SizedBox(height: 80),

                  // Save Button with Loader
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C55E),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text("Save", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off_outlined, color: Colors.black54),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFF2F5FE), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFF9C55E), width: 2),
        ),
      ),
    );
  }
}