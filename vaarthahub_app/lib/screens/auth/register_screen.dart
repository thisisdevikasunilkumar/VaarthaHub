import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();

  bool _isNameValid = false;
  bool _isPhoneValid = false;
  bool _isEmailValid = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _phoneController.addListener(_validatePhone);
    _emailController.addListener(_validateEmail);
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().length >= 3;
    });
  }

  void _validatePhone() {
    setState(() {
      _isPhoneValid = _phoneController.text.trim().length >= 10;
    });
  }

  void _validateEmail() {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isEmailValid = emailRegex.hasMatch(_emailController.text.trim());
    });
  }

  // --- API CALL WITH OPTIONAL IMAGE ---
  Future<void> _handleRegister() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showFeedback("Please fill in all fields", Colors.orange);
      return;
    }

    if (!_isNameValid || !_isPhoneValid || !_isEmailValid) {
      _showFeedback("Please fix the errors in the form", Colors.redAccent);
      return;
    }

    // --- Country Code Validation Start ---
    if (!phone.contains('@')) { 
      
      // 1. Check for the +91 prefix
      if (!phone.startsWith('+91')) {
        _showFeedback(
          "Please include the country code +91 with your phone number.",
          Colors.redAccent,
        );
        return;
      }

      // 2. Validate length (+91 + 10 digits = 13 characters)
      if (phone.length != 13) {
        _showFeedback(
          "Please enter a valid 10-digit phone number after +91.",
          Colors.orange,
        );
        return;
      }
    }

    if (password.length < 6) {
      _showFeedback("Password must be at least 6 characters", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    // 1. Image Conversion to Base64 (Optional)
    String? base64Image;
    if (_image != null) {
      try {
        final bytes = await _image!.readAsBytes();
        base64Image = base64Encode(bytes);
      } catch (e) {
        debugPrint("Image conversion error: $e");
      }
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/Auth/registration');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'fullName': name,
          'phoneNumber': phone,
          'email': email,
          'password': password,
          'role': "Reader",
          'profileImage': base64Image, // This field is optional and can be null
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showFeedback("Registration Successful!", Colors.green);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        String errorMessage = "Error: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData is String ? errorData : (errorData['message'] ?? errorMessage);
        } catch (_) {}
        _showFeedback(errorMessage, Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback("Connection Error: Please check your server.", Colors.redAccent);
    } finally {
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

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // To keep the base64 string size manageable
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset('assets/ui_elements/element1.png', fit: BoxFit.fill),
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
                          MaterialPageRoute(builder: (context) => const OnboardingScreen())
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
                    "Create your account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CustomPaint(
                      painter: DashedCirclePainter(color: const Color(0xFF004CFF)),
                      child: Container(
                        height: 110,
                        width: 110,
                        alignment: Alignment.center,
                        child: _image != null
                            ? ClipOval(
                                child: Image.file(_image!,
                                    height: 100, width: 100, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.camera_alt_outlined,
                                color: Color(0xFF004CFF), size: 35),
                      ),
                    ),
                  ),
                  const SizedBox(height: 45),
                  _buildRegisterTextField(
                    controller: _nameController,
                    hint: "Full Name",
                    icon: _isNameValid ? Icons.check_circle : null,
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 15),
                  _buildRegisterTextField(
                    controller: _phoneController,
                    hint: "Phone Number",
                    icon: _isPhoneValid ? Icons.check_circle : null,
                    iconColor: Colors.green,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  _buildRegisterTextField(
                    controller: _emailController,
                    hint: "Email Address",
                    icon: _isEmailValid ? Icons.check_circle : null,
                    iconColor: Colors.green,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _buildRegisterTextField(
                    controller: _passwordController,
                    hint: "Password",
                    isPassword: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9C55E),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 25, width: 25,
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          )
                        : const Text(
                            "GET STARTED",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "LOG IN",
                          style: TextStyle(color: Color(0xFFF9C55E), fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 180),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    Color iconColor = Colors.grey,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.black54,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : (icon != null ? Icon(icon, color: iconColor) : null),
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

class DashedCirclePainter extends CustomPainter {
  final Color color;
  DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 8, dashSpace = 15, startRadius = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final circumference = 2 * 3.1415926535 * radius;
    final dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startRadius,
        (dashWidth / circumference) * 2 * 3.1415926535,
        false,
        paint,
      );
      startRadius += ((dashWidth + dashSpace) / circumference) * 2 * 3.1415926535;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}