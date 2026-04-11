import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class PartnerRatingsScreen extends StatefulWidget {
  const PartnerRatingsScreen({super.key});

  @override
  State<PartnerRatingsScreen> createState() => _PartnerRatingsScreenState();
}

class _PartnerRatingsScreenState extends State<PartnerRatingsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _ratingData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerCode = prefs.getString('partnerCode');

    if (partnerCode == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Partner session not found. Please login again.";
      });
      return;
    }

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Reader/GetPartnerRatings/$partnerCode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _ratingData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No ratings received yet!";
        });
      } else {
        throw Exception("Failed to load ratings");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Something went wrong. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Performance & Ratings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
          : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _fetchRatings,
                  color: const Color(0xFFF9C55E),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 30),
                        const Text(
                          "Customer Reviews",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        _buildReviewsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final double avg = double.tryParse(_ratingData!['averageRating'].toString()) ?? 0.0;
    final int total = _ratingData!['totalReviews'] ?? 0;
    final starCounts = _ratingData!['starCounts'] as Map<String, dynamic>;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          // Left: Big Rating Circle/Column
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Color(0xFF2D2D2D)),
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star_rounded,
                  color: index < avg.floor() ? const Color(0xFFF9C55E) : Colors.grey.shade300,
                  size: 18,
                )),
              ),
              const SizedBox(height: 8),
              Text("$total Reviews", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(width: 25),
          // Right: Star Bars
          Expanded(
            child: Column(
              children: ["5", "4", "3", "2", "1"].map((star) {
                double progress = total == 0 ? 0 : (starCounts[star] ?? 0) / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(star, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade100,
                            color: const Color(0xFFF9C55E),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    final List reviews = _ratingData!['reviews'] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    review['readerName'] ?? "Reader",
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    review['date'] ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  color: i < (review['ratingValue'] ?? 0) ? const Color(0xFFF9C55E) : Colors.grey.shade200,
                  size: 16,
                )),
              ),
              if (review['comments'] != null && review['comments'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review['comments'],
                  style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                ),
              ],
              if (review['feedbackTags'] != null && (review['feedbackTags'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (review['feedbackTags'] as List).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: const Color(0xFFF9C55E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "#$tag",
                      style: const TextStyle(fontSize: 10, color: Color(0xFFC48E1D), fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          TextButton(onPressed: _fetchRatings, child: const Text("Retry", style: TextStyle(color: Color(0xFFF9C55E)))),
        ],
      ),
    );
  }
}