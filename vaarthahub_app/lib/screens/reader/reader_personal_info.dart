import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ReaderPersonalInformation extends StatefulWidget {
  const ReaderPersonalInformation({super.key});

  @override
  State<ReaderPersonalInformation> createState() => _ReaderPersonalInformationState();
}

class _ReaderPersonalInformationState extends State<ReaderPersonalInformation> {
  File? _image;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _panchayatController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _gender;
  DateTime? _dob;

  String? _readerCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReaderProfile();
  }

  Future<void> _loadReaderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _readerCode = prefs.getString('readerCode');

    if (_readerCode == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Reader/GetReaderProfile/$_readerCode');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phoneNumber'] ?? '';
          _emailController.text = data['email'] ?? '';
          _gender = data['gender'];

          final dobString = data['dateOfBirth'];
          if (dobString != null && dobString is String && dobString.isNotEmpty) {
            _dob = DateTime.tryParse(dobString);
            if (_dob != null) {
              _dobController.text = '${_dob!.day.toString().padLeft(2, '0')}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.year}';
            }
          }

          _panchayatController.text = data['panchayatName'] ?? '';
          _wardController.text = data['wardNumber'] ?? '';
          _addressController.text = data['address'] ?? '';
          _base64Image = data['profileImage'];
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to load profile.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error fetching reader profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_readerCode == null) return;

    setState(() => _isLoading = true);

    String? imageBase64 = _base64Image;
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Reader/UpdateReaderProfile/$_readerCode');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': _nameController.text,
          'phoneNumber': _phoneController.text,
          'email': _emailController.text,
          'gender': _gender,
          'dateOfBirth': _dob?.toIso8601String(),
          'panchayatName': _panchayatController.text,
          'wardNumber': _wardController.text,
          'address': _addressController.text,
          'profileImageBase64': imageBase64,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update profile.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _panchayatController.dispose();
    _wardController.dispose();
    _addressController.dispose();
    _dobController.dispose();
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))),
      );
    }

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

            _buildLabel("Full Name"),
            _buildCustomTextField(controller: _nameController, hint: "Enter your name"),
            const SizedBox(height: 15),

            _buildLabel("Phone Number"),
            _buildCustomTextField(controller: _phoneController, hint: "Enter phone number", keyboardType: TextInputType.phone),
            const SizedBox(height: 15),

            _buildLabel("Email Address"),
            _buildCustomTextField(controller: _emailController, hint: "Enter email", keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),

            _buildLabel("Gender"),
            _buildGenderDropdown(),
            const SizedBox(height: 15),

            _buildLabel("Date of Birth"),
            _buildDobField(),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Panchayat"),
                      _buildCustomTextField(controller: _panchayatController, hint: "Panchayat Name"),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Ward Number"),
                      _buildCustomTextField(controller: _wardController, hint: "Ward Number"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            _buildLabel("Address"),
            _buildCustomTextField(controller: _addressController, hint: "Enter address"),
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
                            "Update Profile",
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
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
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
        "Personal Information",
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
        fillColor: const Color(0x4DF2F5FE), // Subtly filled (30% opacity)
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

  Widget _buildGenderDropdown() {
    const options = ['Male', 'Female', 'Other'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F5FE), width: 1.2),
        color: const Color(0x4DF2F5FE),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender != null && options.contains(_gender) ? _gender : null,
          hint: const Text('Select gender'),
          isExpanded: true,
          items: options
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) => setState(() => _gender = val),
        ),
      ),
    );
  }

  Widget _buildDobField() {
    return TextField(
      controller: _dobController,
      readOnly: true,
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: _dob ?? DateTime(now.year - 20),
          firstDate: DateTime(1900),
          lastDate: now,
        );
        if (selected != null) {
          setState(() {
            _dob = selected;
            _dobController.text = '${selected.day.toString().padLeft(2, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.year}';
          });
        }
      },
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Select date of birth',
        hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        filled: true,
        fillColor: const Color(0x4DF2F5FE),
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