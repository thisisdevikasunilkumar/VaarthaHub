import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class PartnerRatingsScreen extends StatefulWidget {
  const PartnerRatingsScreen({super.key});

  @override
  State<PartnerRatingsScreen> createState() => _PartnerRatingsScreenState();
}

class _PartnerRatingsScreenState extends State<PartnerRatingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingRatings = true;
  bool _isLoadingComplaints = true;
  String? _partnerCode;
  List<dynamic> _performanceData = [];
  List<dynamic> _complaintsData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _partnerCode = prefs.getString('partnerCode');
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadPerformanceData(), _loadComplaintsData()]);
  }

  Future<void> _loadPerformanceData() async {
    if (!mounted || _partnerCode == null) return;
    setState(() => _isLoadingRatings = true);
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.baseUrl}/Reader/GetPartnerRatings/$_partnerCode",
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // If the API returns a single object, wrap it in a list so the UI can map over it.
          _performanceData = data is List ? data : [data];
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRatings = false);
    }
  }

  Future<void> _loadComplaintsData() async {
    if (!mounted || _partnerCode == null) return;
    setState(() => _isLoadingComplaints = true);
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConstants.baseUrl}/Reader/GetPartnerComplaints/$_partnerCode",
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaintsData = data is List ? data : [data];
          _isLoadingComplaints = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComplaints = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Orange decorative curve at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _buildHeader(),
                const SizedBox(height: 10),
                _buildStatsRow(),
                _buildCustomTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildRatingsTab(),
                      _buildComplaintsTab(),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Delivery Performance",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final partner = _performanceData.isNotEmpty ? _performanceData.first : null;
    final int reviewsCount =
        partner?['totalReviews'] ?? partner?['ratingCount'] ?? 0;
    final int complaintsCount = _complaintsData.length;
    final double rating = (partner?['averageRating'] ?? 0.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total Ratings",
              reviewsCount.toString(),
              "Avg: ${rating.toStringAsFixed(1)} ★",
              const Color(0xFFFFF7E6),
              Colors.orange,
              Icons.star_rounded,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              "Total Complaints",
              complaintsCount.toString(),
              complaintsCount > 0 ? "Needs attention" : "All clear!",
              const Color(0xFFFFF0F0),
              Colors.redAccent,
              Icons.report_problem_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String subtext,
    Color bgColor,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              // ignore: deprecated_member_use
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              // ignore: deprecated_member_use
              color: color.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFF9C55E),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color(0xFFF9C55E).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black45,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: "Ratings"),
          Tab(text: "Complaints"),
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    if (_isLoadingRatings) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
      );
    }

    final partner = _performanceData.isNotEmpty ? _performanceData.first : null;
    final List<dynamic> ratingsList =
        partner?['reviews'] ?? partner?['recentRatings'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
      color: const Color(0xFFF9C55E),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text(
            "Customer Reviews",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (ratingsList.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: Text("No reviews found yet"),
              ),
            )
          else
            ...List.generate(ratingsList.length, (index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildRecentRatingItem(ratingsList[index]),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRecentRatingItem(dynamic data) {
    // Handle both DateTime and pre-formatted string from backend
    final String dateString = data['date'] ?? data['createdAt'] ?? "";
    final int stars = data['ratingValue'] ?? 0;
    final List<dynamic> tags = data['feedbackTags'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['readerName'] ?? data['reviewerName'] ?? "Anonymous",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                dateString,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                Icons.star_rounded,
                size: 14,
                color: index < stars
                    ? const Color(0xFFF9C55E)
                    : Colors.grey.shade300,
              ),
            ),
          ),
          if (data['comments'] != null &&
              data['comments'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              data['comments'],
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((tag) => _buildTagChip(tag.toString()))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6B5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "#$tag",
        style: const TextStyle(
          color: Color(0xFFCC7A00),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_isLoadingComplaints) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaintsData,
      color: const Color(0xFFF9C55E),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text(
            "Customer Complaints",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          if (_complaintsData.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("No complaints found"),
              ),
            )
          else
            ...List.generate(_complaintsData.length, (index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildComplaintCard(_complaintsData[index]),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final DateTime _ = DateTime.parse(complaint['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                complaint['complaintType'] ??
                    complaint['ComplaintType'] ??
                    "N/A",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.red,
                ),
              ),
              Text(
                complaint['createdAt'] != null
                    ? DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(complaint['createdAt']))
                    : (complaint['CreatedAt'] != null
                          ? DateFormat(
                              'dd MMM yyyy',
                            ).format(DateTime.parse(complaint['CreatedAt']))
                          : "N/A"),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "by ${complaint['readerName'] ?? complaint['ReaderName'] ?? 'Unknown'}",
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              complaint['comments'] ?? complaint['Comments'] ?? "No comments",
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
