import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _lastUpdated;
  String? _userCode;
  String? _role; // "Reader" or "DeliveryPartner"

  @override
  void initState() {
    super.initState();
    _loadLastUpdated();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    _userCode = prefs.getString('readerCode') ?? prefs.getString('partnerCode');
    _role = _userCode != null ? (_userCode!.startsWith('R-') ? 'Reader' : 'DeliveryPartner') : null;

    if (_userCode == null || _role == null) return;

    try {
      final endpoint = _role == 'Reader' ? 'Reader/GetReaderProfile' : 'DeliveryPartner/GetDeliveryPartnerProfile';
      final url = Uri.parse('${ApiConstants.baseUrl}/$endpoint/$_userCode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedAt = data['passwordUpdatedAt'];
        if (updatedAt != null) {
          final date = DateTime.tryParse(updatedAt);
          if (date != null) {
            setState(() {
              _lastUpdated = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading last updated: $e');
    }
  }

  Future<void> _changePassword() async {
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (newPass != confirmPass) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (newPass.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (_userCode == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Auth/change-password');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userCode': _userCode,
          'oldPassword': oldPass,
          'newPassword': newPass,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
        // Clear fields
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        // Reload last updated
        await _loadLastUpdated();
      } else {
        final data = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to update password'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Ivide 'title' koode pass cheyyanam
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- LAST UPDATED STATUS ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB4B4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Last updated: ${_lastUpdated ?? 'Never'}",
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text("Old Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _oldPasswordController,
              hint: "Enter current password",
              isObscured: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),

            const SizedBox(height: 20),
            const Text("New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _newPasswordController,
              hint: "Enter new password",
              isObscured: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),

            const SizedBox(height: 20),
            const Text("Confirm New Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            _buildPasswordField(
              controller: _confirmPasswordController,
              hint: "Re-type new password",
              isObscured: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),

            const SizedBox(height: 40),

            /// UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Update Password",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar Helper
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Change Password",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscured,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        filled: true,
        // ignore: deprecated_member_use
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF2F5FE).withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFF2F5FE), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFF9C55E), width: 2),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: Icon(
              isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.grey,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}