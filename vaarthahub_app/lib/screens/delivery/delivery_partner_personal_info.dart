import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class DeliveryPartnerPersonalInfo extends StatefulWidget {
  const DeliveryPartnerPersonalInfo({super.key});

  @override
  State<DeliveryPartnerPersonalInfo> createState() => _DeliveryPartnerPersonalInfoState();
}

class _DeliveryPartnerPersonalInfoState extends State<DeliveryPartnerPersonalInfo> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _licenseNoController = TextEditingController();
  final TextEditingController _panchayatController = TextEditingController();
  
  String? _partnerCode;
  bool _isLoading = true;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _partnerCode = prefs.getString('partnerCode');

    if (_partnerCode == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/DeliveryPartner/GetDeliveryPartnerProfile/$_partnerCode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _emailController.text = data['email'] ?? '';
          _vehicleTypeController.text = data['vehicleType'] ?? '';
          _vehicleNoController.text = data['vehicleNumber'] ?? '';
          _licenseNoController.text = data['licenseNumber'] ?? '';
          _panchayatController.text = data['panchayatName'] ?? '';
          _base64Image = data['profileImage'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_partnerCode == null) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/DeliveryPartner/UpdateDeliveryPartnerProfile/$_partnerCode");

      String? imageBase64 = _base64Image;
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final body = json.encode({
        "fullName": _nameController.text,
        "phoneNumber": _phoneController.text,
        "email": _emailController.text,
        "vehicleType": _vehicleTypeController.text,
        "vehicleNumber": _vehicleNoController.text,
        "licenseNumber": _licenseNoController.text,
        "panchayatName": _panchayatController.text,
        "profileImageBase64": imageBase64,
      });

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: Colors.green));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile."), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNoController.dispose();
    _licenseNoController.dispose();
    _panchayatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar with back button and title
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PROFILE PICTURE SECTION
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200, // Slightly darker grey for better icon contrast
                    backgroundImage: _image != null
                        ? FileImage(_image!) as ImageProvider
                        : (_base64Image != null && _base64Image!.isNotEmpty)
                            ? MemoryImage(base64Decode(_base64Image!)) as ImageProvider
                            : null, // Set to null so the 'child' icon shows up
                    child: (_image == null && (_base64Image == null || _base64Image!.isEmpty))
                        ? const Icon(
                            Icons.person_rounded,
                            size: 65,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  PositionBag(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            /// DELIVERY PARTNER FIELDS
            _buildLabel("Full Name"),
            _buildCustomTextField(controller: _nameController, hint: "Partner Name"),              
            const SizedBox(height: 15),

            _buildLabel("Phone Number"),
            _buildCustomTextField(controller: _phoneController, hint: "Phone", keyboardType: TextInputType.phone),
            const SizedBox(height: 15),

            _buildLabel("Email Address"),
            _buildCustomTextField(controller: _emailController, hint: "Enter email"),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Vehicle Type"),
                      _buildCustomTextField(controller: _vehicleTypeController, hint: "eg: Bike"),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Vehicle Number"),
                      _buildCustomTextField(controller: _vehicleNoController, hint: "Vehicle No"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            _buildLabel("Driving License Number"),
            _buildCustomTextField(controller: _licenseNoController, hint: "License No"),

            const SizedBox(height: 15),
            _buildLabel("Panchayat"),
            _buildCustomTextField(controller: _panchayatController, hint: "Panchayat Name"),

            const SizedBox(height: 40),

            /// BUTTONS SECTION
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const CircularProgressIndicator(color: Color(0xFFF9C55E))
                        : const Text(
                            "Update Partner Profile", 
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF9C55E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text(
                      "Cancel", 
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  // AppBar with back button and title
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
        "Partner Information",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller, 
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
      ),
    );
  }
}

class PositionBag extends StatelessWidget {
  final double? bottom;
  final double? right;
  final Widget child;
  const PositionBag({super.key, this.bottom, this.right, required this.child});
  @override
  Widget build(BuildContext context) => Positioned(bottom: bottom, right: right, child: child);
}