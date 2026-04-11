import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/register_screen.dart';
import '../auth/password_recovery_screen.dart';

import '../admin/admin_dashboard.dart';
import '../delivery/delivery_home_screen.dart';
import '../reader/reader_home_screen.dart';

import 'package:vaarthahub_app/services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController(); // Email or Phone
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- LOGIN FUNCTION ---
  Future<void> _handleLogin() async {
    String identifier = _identifierController.text.trim();
    String password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showFeedback("Please fill in both fields", Colors.orange);
      return;
    }

    // --- Country Code Validation Start ---
    if (!identifier.contains('@')) { // phone number case

      if (!identifier.startsWith('+91')) {
        _showFeedback(
          "Please include the country code (e.g., +91) with your phone number.",
          Colors.redAccent,
        );
        return;
      }

      if (identifier.length != 13) {
        _showFeedback(
          "Please enter a valid 10-digit phone number after +91.",
          Colors.orange,
        );
        return;
      }
    }
    // --- Country Code Validation End ---

    setState(() => _isLoading = true);

    // API call to login user
    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/login');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'emailOrPhone': identifier, // API expects 'emailOrPhone' as the key
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String role = data['role'];
        
        // --- ID SAVE LOGIC START ---
        if (role == "Reader" && data['code'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('readerCode', data['code']);
        } else if (role == "DeliveryPartner" && data['code'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('partnerCode', data['code']);
        }
        // --- ID SAVE LOGIC END ---

        _showFeedback("Login Successful!", Colors.green);

        // ROLE BASED NAVIGATION
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          
          if (role == "Admin") 
          {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
          }
          else if (role == "DeliveryPartner") 
          {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DeliveryHomeScreen()));
          } 
          else if (role == "Reader") 
          {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ReaderHomeScreen()));
          }
        });
      } 
      else {
        String errorMsg = "Invalid Credentials";
        try {
          final errorData = jsonDecode(response.body);
          errorMsg = errorData['message'] ?? errorMsg;
        } catch (_) {}
        _showFeedback(errorMsg, Colors.redAccent);
      }
    } 
    catch (e) {
      if (!mounted) return;
      _showFeedback("Connection Error: Please check your server.", Colors.redAccent);
    } 
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset('assets/ui_elements/element2.png', fit: BoxFit.fill),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (context) => const RegisterScreen())
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.2),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Profile Avatar
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        )
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 70, 
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 62, 
                        backgroundImage: AssetImage('assets/images/avatar.png'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),
                  
                  _buildCustomTextField(
                    controller: _identifierController,
                    hint: "Email or Phone Number",
                    isPassword: false,
                  ),

                  const SizedBox(height: 15),

                  _buildCustomTextField(
                    controller: _passwordController,
                    hint: "Password",
                    isPassword: true,
                  ),

                  const SizedBox(height: 15),

                  // LOGIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C55E),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "LOG IN",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      String identifier = _identifierController.text.trim();

                      if (identifier.isEmpty) {
                        _showFeedback("Please enter your email or phone number.", Colors.orange);
                        return;
                      }

                      // Phone number validation
                      if (!identifier.contains('@')) {
                        if (!identifier.startsWith('+91')) {
                          _showFeedback(
                            "Please include the country code (e.g., +91) with your phone number.",
                            Colors.redAccent,
                          );
                          return;
                        }

                        if (identifier.length != 13) {
                          _showFeedback(
                            "Please enter a valid 10-digit phone number after +91.",
                            Colors.orange,
                          );
                          return;
                        }
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PasswordRecoveryScreen(
                            emailOrPhone: identifier,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(0xFF5D5E61),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.black)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                        },
                        child: const Text(
                          "SIGN UP",
                          style: TextStyle(
                            color: Color(0xFFF9C55E),
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller, 
    required String hint, 
    required bool isPassword
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
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