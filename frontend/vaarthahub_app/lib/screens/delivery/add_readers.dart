import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vaarthahub_app/models/reader_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class AddReaders extends StatefulWidget {
  const AddReaders({super.key});

  @override
  State<AddReaders> createState() => _AddReadersState();
}

class _AddReadersState extends State<AddReaders> {
  // 1. Controllers and Variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? selectedPanchayat; 
  List<String> dynamicPanchayats = []; 
  bool isLoading = true; // For fetching panchayats
  bool _isLoading = false; // For submission loading

  @override
  void initState() {
    super.initState();
    fetchPanchayats(); 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Fetch Panchayat Names
  Future<void> fetchPanchayats() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/DeliveryPartner/GetPanchayatName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          dynamicPanchayats = data.cast<String>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showFeedback("Error fetching panchayats: $e", Colors.redAccent);
      setState(() => isLoading = false);
    }
  }

  // --- API function to submit data ---
  Future<void> _submitData() async {
    // 1. Basic Validation
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        selectedPanchayat == null) {
          _showFeedback("Please fill all required fields", Colors.orange);
      return;
    }

    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+91')) {
      _showFeedback("Please include the country code (e.g., +91) with your phone number.", Colors.redAccent);
      return;
    }

    if (phoneNumber.length != 13) {
      _showFeedback("Please enter a valid 10-digit phone number after +91.", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- PARTNER CODE RETRIEVAL ---
      final prefs = await SharedPreferences.getInstance();
      String? partnerCode = prefs.getString('partnerCode');

      if (partnerCode == null) {
        _showFeedback("Session expired. Please login again.", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      // 2. Create Model Object with addedByPartnerCode
      final readerData = ReaderModel(
        fullName: _nameController.text.trim(),
        phoneNumber: phoneNumber, 
        panchayatName: selectedPanchayat!,
        addedByPartnerCode: partnerCode,
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/DeliveryPartner/AddReader');
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(readerData.toJson()),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showFeedback("Reader Added Successfully!", Colors.green);
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
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
            ),
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
                        _buildTextField("Phone Number", "Enter Phone number", _phoneController, isRequired: true, isNumber: true),
                        
                        isLoading 
                          ? const Center(child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            )) 
                          : _buildDropdownField("Panchayat", "Select Panchayat", isRequired: true),                       
                        
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
            "Add Reader",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
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

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isRequired = false, bool isNumber = false}) {
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
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
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
            ),
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
                value: selectedPanchayat,
                hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                items: dynamicPanchayats.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedPanchayat = newValue;
                  });
                },
              ),
            ),
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
                "Add Reader",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }   
}