import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

import 'package:vaarthahub_app/models/delivery_partner_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class AddDeliveryPartner extends StatefulWidget {
  const AddDeliveryPartner({super.key});

  @override
  State<AddDeliveryPartner> createState() => _AddDeliveryPartnerState();
}

class _AddDeliveryPartnerState extends State<AddDeliveryPartner> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _panchayatController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  String? selectedVehicle;
  bool _isLoading = false;

  final List<String> vehicleTypes = [
    "Bicycle",    
    "Bike",
    "Scooter",
    "Auto Rickshaw",
    "Four Wheeler"
  ];

  // API function to submit data
  Future<void> _submitData() async {
    // 1. Basic Field Validation
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        selectedVehicle == null ||
        _regNumberController.text.isEmpty ||
        _licenseController.text.isEmpty ||
        _panchayatController.text.isEmpty) {
      _showFeedback("Please fill all required fields", Colors.orange);
      return;
    }

    // --- Country Code Validation Start ---
    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+91')) {
      _showFeedback(
        "Please include the country code (e.g., +91) with your phone number.", 
        Colors.redAccent
      );
      return;
    }

    if (phoneNumber.length != 13) {
      _showFeedback(
        "Please enter a valid 10-digit phone number after +91.", 
        Colors.orange
      );
      return;
    }
    // --- Country Code Validation End ---

    setState(() => _isLoading = true);

    // 2. Create Model Object
    final partnerData = DeliveryPartnerModel(
      fullName: _nameController.text.trim(),
      phoneNumber: phoneNumber, // Validated phone number with +91
      vehicleType: selectedVehicle!,
      vehicleNumber: _regNumberController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      panchayatName: _panchayatController.text.trim(),
      basicSalary: double.tryParse(_salaryController.text.trim()) ?? 0.0,
    );

    // API Call to submit partner data
    final url = Uri.parse('${ApiConstants.baseUrl}/Admin/AddDeliveryPartner');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(partnerData),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showFeedback("Delivery Partner Added Successfully!", Colors.green);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context);
      } else {
        String errorMessage = "Server Error: ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        _showFeedback(errorMessage, Colors.redAccent);
      }
    } catch (e) {
      if (!mounted) return;
      _showFeedback("Connection Error: Please check your internet.", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Refactored Snackbar Helper
  void _showFeedback(String message, Color color) {
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regNumberController.dispose();
    _licenseController.dispose();
    _panchayatController.dispose();
    _salaryController.dispose();
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
            child: Image.asset('assets/ui_elements/element5.png', fit: BoxFit.fill),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildSectionHeader("Personal Information"),
                        _buildTextField("Full Name", "Enter Full name", _nameController, isRequired: true),
                        _buildTextField("Phone Number", "Enter Phone number", _phoneController, isRequired: true),
                        const SizedBox(height: 25),
                        _buildSectionHeader("Vehicle Details"),
                        _buildDropdownField("Vehicle Type", "Select Vehicle type", isRequired: true),
                        _buildTextField("Vehicle Registration Number", "KL-01-AB-1234", _regNumberController, isRequired: true),
                        _buildTextField("Driving License Number", "KL123456789", _licenseController, isRequired: true),
                        const SizedBox(height: 25),
                        _buildSectionHeader("Service Location Details"),
                        _buildTextField("Distribution Panchayat", "Enter Panchayat", _panchayatController, isRequired: true),
                        const SizedBox(height: 25),
                        _buildSectionHeader("Salary Details"),
                        _buildTextField("Basic Monthly Salary", "₹ Enter basic salary amount", _salaryController, isRequired: true),                        
                        const SizedBox(height: 30),
                        _buildSubmitButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Add Delivery Partner",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9C55E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : const Text(
                "Add Delivery Partner",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.black45, thickness: 0.8),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 14),
              children: isRequired ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: _inputDecoration(hint),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String hint, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Color(0xFF333333), fontWeight: FontWeight.w600, fontSize: 14),
              children: isRequired ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD1E1FF)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedVehicle,
                hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                items: vehicleTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => selectedVehicle = newValue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF9C55E)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}