import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ReaderFeedbackHistoryScreen extends StatefulWidget {
  final String readerCode;
  const ReaderFeedbackHistoryScreen({super.key, required this.readerCode});

  @override
  State<ReaderFeedbackHistoryScreen> createState() => _ReaderFeedbackHistoryScreenState();
}

class _ReaderFeedbackHistoryScreenState extends State<ReaderFeedbackHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingRatings = true;
  bool _isLoadingComplaints = true;
  List<dynamic> _ratingsData = [];
  List<dynamic> _complaintsData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadRatingsData(), _loadComplaintsData()]);
  }

  Future<void> _loadRatingsData() async {
    if (!mounted) return;
    setState(() => _isLoadingRatings = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/Reader/GetReaderRatings/${widget.readerCode}"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ratingsData = data is List ? data : [data];
          _isLoadingRatings = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRatings = false);
    }
  }

  Future<void> _loadComplaintsData() async {
    if (!mounted) return;
    setState(() => _isLoadingComplaints = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/Reader/GetReaderComplaints/${widget.readerCode}"),
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Feedback History",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
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
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: "My Ratings"),
          Tab(text: "My Complaints"),
        ],
      ),
    );
  }

  Widget _buildRatingsTab() {
    if (_isLoadingRatings) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)));
    }

    return RefreshIndicator(
      onRefresh: _loadRatingsData,
      color: const Color(0xFFF9C55E),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          if (_ratingsData.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: Text("You haven't rated any partners yet")),
            )
          else
            ...List.generate(_ratingsData.length, (index) {
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
                child: _buildRatingCard(_ratingsData[index]),
              );
            }),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildRatingCard(dynamic data) {
    final String partnerName = data['partnerName'] ?? data['deliveryPartnerName'] ?? "Delivery Partner";
    final String dateString = data['date'] ?? data['createdAt'] ?? "";
    final int stars = data['ratingValue'] ?? 0;
    final List<dynamic> tags = data['feedbackTags'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCEBFF)),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                partnerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                dateString,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) => Icon(
              Icons.star_rounded,
              size: 18,
              color: index < stars ? const Color(0xFFF9C55E) : Colors.grey.shade300,
            )),
          ),
          if (data['comments'] != null && data['comments'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['comments'],
                style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => _buildTagChip(tag.toString())).toList(),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "#$tag",
        style: const TextStyle(color: Color(0xFFCC7A00), fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_isLoadingComplaints) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)));
    }

    return RefreshIndicator(
      onRefresh: _loadComplaintsData,
      color: const Color(0xFFF9C55E),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          if (_complaintsData.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(child: Text("No complaints recorded")),
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
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final String partnerName = complaint['partnerName'] ?? complaint['deliveryPartnerName'] ?? "Delivery Partner";
    final String type = complaint['complaintType'] ?? "N/A";
    final String dateString = complaint['createdAt'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(complaint['createdAt']))
        : "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.red.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
              Text(
                dateString,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "against $partnerName",
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              complaint['comments'] ?? "No comments",
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
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
