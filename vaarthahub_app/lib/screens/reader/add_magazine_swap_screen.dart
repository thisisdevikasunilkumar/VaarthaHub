import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class AddMagazineSwapScreen extends StatefulWidget {
  final Map<String, dynamic>? editData;
  const AddMagazineSwapScreen({super.key, this.editData});

  @override
  State<AddMagazineSwapScreen> createState() => _AddMagazineSwapScreenState();
}

class _AddMagazineSwapScreenState extends State<AddMagazineSwapScreen> {
  // Dropdown values
  String selectedCategory = 'Women';
  String selectedCondition = 'Excellent';

  // Text editing controllers
  final TextEditingController _magazineNameController = TextEditingController();
  final TextEditingController _issueEditionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _lookingForController = TextEditingController();

  int? _readerId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editData != null) {
      _magazineNameController.text = widget.editData!['offeredMagazine'] ?? '';
      _issueEditionController.text = widget.editData!['issueEdition'] ?? '';
      _priceController.text = widget.editData!['magazinePrice']?.toString() ?? '';
      _lookingForController.text = widget.editData!['requestedMagazine'] ?? '';
      selectedCategory = widget.editData!['category'] ?? 'Women';
      selectedCondition = widget.editData!['condition'] ?? 'Excellent';
    }
    _loadReaderProfile();
  }

  Future<void> _loadReaderProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final readerCode = prefs.getString('readerCode');

    if (readerCode == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/Reader/GetReaderProfile/$readerCode',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _readerId = data['readerId'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching reader profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_magazineNameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _lookingForController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_readerId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Reader ID not found', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      bool isEdit = widget.editData != null;
      final url = isEdit 
          ? Uri.parse('${ApiConstants.baseUrl}/SwapRequests/${widget.editData!['swapId']}')
          : Uri.parse('${ApiConstants.baseUrl}/SwapRequests/request');
      
      final body = {
        'requestReaderId': _readerId,
        'offeredMagazine': _magazineNameController.text.trim(),
        'issueEdition': _issueEditionController.text.trim(),
        'requestedMagazine': _lookingForController.text.trim(),
        'magazinePrice': double.tryParse(_priceController.text) ?? 0.0,
        'category': selectedCategory,
        'condition': selectedCondition
      };

      final response = isEdit 
          ? await http.put(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
          : await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog(isEdit);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to list magazine for swap.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(bool isEdit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  ),
                ),
                Icon(
                  isEdit ? Icons.edit_note : Icons.swap_horizontal_circle,
                  size: 100,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                Text(
                  isEdit ? 'Listing Updated\nSuccessfully!' : 'Magazine Listed for\nSwap Successfully!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9C55E),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFDC055)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Curved Background Element
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 120, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 35,
                        ), // Adjusted for better spacing
                        _buildAppBar(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel("Magazine Name"),
                                _buildTextField(
                                  _magazineNameController,
                                  "e.g. Vanitha, Balarama",
                                ),

                                _buildLabel("Issue / Edition"),
                                _buildTextField(
                                  _issueEditionController,
                                  "e.g. January 2026 - Week 2",
                                ),

                                _buildLabel("Category"),
                                _buildDropdown(
                                  [
                                    "Automobile",
                                    "Career",
                                    "Children",
                                    "Education",
                                    "English",
                                    "Family",
                                    "Farming",
                                    "Finance",
                                    "Food",
                                    "General Knowledge",
                                    "Health",
                                    "Lifestyle",
                                    "Literary",
                                    "Sports",
                                    "Travel",
                                    "Weekly",
                                    "Women"
                                  ],
                                  selectedCategory,
                                  (val) {
                                    setState(() => selectedCategory = val!);
                                  },
                                ),

                                _buildLabel("Condition"),
                                _buildDropdown(
                                  ["Excellent", "Good", "Fair"],
                                  selectedCondition,
                                  (val) {
                                    setState(() => selectedCondition = val!);
                                  },
                                ),

                                _buildLabel("Magazine Price"),
                                _buildPriceField("Enter Price"),

                                _buildLabel("What are you looking for?"),
                                _buildTextField(
                                  _lookingForController,
                                  "e.g. Any Balarama issue from last month",
                                  maxLines: 5,
                                ),

                                const SizedBox(height: 40),

                                _buildSubmitButton(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _magazineNameController.dispose();
    _issueEditionController.dispose();
    _priceController.dispose();
    _lookingForController.dispose();
    super.dispose();
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
          Text(
            widget.editData != null ? "Update Swap Listing" : "Add Magazine for Swap",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // --- Label Helper ---
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Text Field Helper ---
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _buildInputDecoration(hint),
    );
  }

  // --- Input Decoration Helper ---
  InputDecoration _buildInputDecoration(
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.blue.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFDC055), width: 1.5),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  // --- Dropdown Helper ---
  Widget _buildDropdown(
    List<String> items,
    String currentVal,
    Function(String?) onChange,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  Widget _buildPriceField(String hint) {
    return TextField(
      controller: _priceController,
      decoration: _buildInputDecoration(
        hint,
        prefixIcon: _buildPrefixIcon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFD1E1FF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: const Color(0xFF4A69FF), size: 20),
    );
  }

  // --- Submit Button ---
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDC055),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isSubmitting 
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            )
          : Text(
          widget.editData != null ? "Update Listing" : "List Magazine for Swap",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
