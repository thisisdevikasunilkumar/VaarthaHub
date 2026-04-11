import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaarthahub_app/services/api_service.dart';

class ManualAddressFormScreen extends StatefulWidget {
  final String readerCode;
  const ManualAddressFormScreen({super.key, required this.readerCode});

  @override
  State<ManualAddressFormScreen> createState() => _ManualAddressFormScreenState();
}

class _ManualAddressFormScreenState extends State<ManualAddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final TextEditingController _houseNameController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _panchayatController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updateData = {
      "houseName": _houseNameController.text,
      "houseNo": _houseNoController.text,
      "landmark": _landmarkController.text,
      "panchayatName": _panchayatController.text,
      "wardNumber": _wardController.text,
      "pincode": _pincodeController.text,
    };

    try {
      final response = await http.put(
        Uri.parse("${ApiConstants.baseUrl}/Reader/UpdateDetailedAddress/${widget.readerCode}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address Saved!")));
          Navigator.pop(context, true);
        }
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Network failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manual Address", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white, 
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildField("House Name", "Enter House Name", _houseNameController, isReq: true)),
                        const SizedBox(width: 15),
                        Expanded(child: _buildField("House No.", "Enter House Number", _houseNoController)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField("Landmark / Street", "Enter Landmark or Street", _landmarkController, isReq: true),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _buildField("Panchayat", "Enter Panchayat Name", _panchayatController, isReq: true)),
                        const SizedBox(width: 15),
                        Expanded(flex: 1, child: _buildField("Ward No.", "Enter Ward Number", _wardController, isNum: true, isReq: true)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildField("Pincode", "Enter Pincode", _pincodeController, isNum: true, isReq: true, limit: 6),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9C55E), 
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                        ),
                        onPressed: _handleSave,
                        child: const Text("Save Address", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
              ),
            ),
    );
  }

  Widget _buildField(String label, String hintText, TextEditingController controller, {bool isReq = false, bool isNum = false, int? limit}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isNum ? TextInputType.number : TextInputType.text,
          validator: (v) => (isReq && (v == null || v.isEmpty)) ? "Required" : (limit != null && v!.length != limit) ? "Invalid" : null,
          decoration: InputDecoration(
            hintText: hintText, // Hint Text added here
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true, 
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF9C55E))),
          ),
        ),
      ],
    );
  }
}