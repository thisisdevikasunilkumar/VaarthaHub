import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vaarthahub_app/services/api_service.dart';

class DeliveryRatingScreen extends StatefulWidget {
  final String partnerCode;
  final String? partnerName;

  const DeliveryRatingScreen({
    super.key,
    required this.partnerCode,
    this.partnerName,
  });

  @override
  State<DeliveryRatingScreen> createState() => _DeliveryRatingScreenState();
}

class _DeliveryRatingScreenState extends State<DeliveryRatingScreen> {
  int _selectedRating = 0;
  bool _isLoading = false;
  String? _partnerName;
  String? _readerCode;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _feedbackTags = [
    "On Time Delivery",
    "Polite Behavior",
    "Proper Handling",
    "Good Communication",
    "Followed Instructions"
  ];
  final List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final prefs = await SharedPreferences.getInstance();
    final storedReaderCode = prefs.getString('readerCode');

    String? partnerName = widget.partnerName;
    final partnerCode = widget.partnerCode;

    if ((partnerName == null || partnerName.isEmpty) && partnerCode.isNotEmpty) {
      try {
        final url = Uri.parse(
          "${ApiConstants.baseUrl}/DeliveryPartner/GetDeliveryPartnerProfile/$partnerCode",
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          partnerName = data['fullName'] ?? partnerName;
        }
      } catch (_) {
        // ignore
      }
    }

    if (!mounted) return;

    setState(() {
      _readerCode = storedReaderCode;
      _partnerName = partnerName;
    });
  }

  // --- API Call Function ---
  Future<void> _submitReview() async {
    if (widget.partnerCode.isEmpty || _readerCode == null || _readerCode!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Unable to submit rating: missing user or partner info.")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final String readerCode = _readerCode!;
    final String partnerCode = widget.partnerCode;

    final url = Uri.parse("${ApiConstants.baseUrl}/Reader/SubmitRating");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "partnerCode": partnerCode,
          "readerCode": readerCode,
          "ratingValue": _selectedRating,
          "feedbackTags": _selectedTags,
          "comments": _commentController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Rating submitted successfully! ❤️"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Failed to submit rating");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFFFCC66),
              backgroundImage: AssetImage("assets/logo/vaarthaHub-logo.png"),
            ),
            const SizedBox(height: 15),
            const Text(
              "How was your delivery?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _partnerName != null && _partnerName!.isNotEmpty
                  ? "Rate your experience with $_partnerName"
                  : "Rate your delivery partner",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            /// STAR RATING BAR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF9C55E),
                    size: 45,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),

            /// FEEDBACK TAGS
            if (_selectedRating > 0) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "What did you like the most?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _feedbackTags.map((tag) {
                  bool isSelected = _selectedTags.contains(tag);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        isSelected ? _selectedTags.remove(tag) : _selectedTags.add(tag);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: isSelected ? const Color(0xFFF9C55E).withOpacity(0.2) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF9C55E) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFC48E1D) : Colors.black87,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 30),

            /// ADDITIONAL COMMENTS
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Write additional feedback...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 50),

            /// SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: (_selectedRating == 0 || _isLoading || widget.partnerCode.isEmpty || _readerCode == null || _readerCode!.isEmpty)
                    ? null
                    : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text("Submit Review", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

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
        "Rate Delivery",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}