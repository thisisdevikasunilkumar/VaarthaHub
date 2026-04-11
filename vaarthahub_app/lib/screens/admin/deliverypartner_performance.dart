import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class DeliveryPartnerPerformance extends StatefulWidget {
  const DeliveryPartnerPerformance({super.key});

  @override
  State<DeliveryPartnerPerformance> createState() =>
      _DeliveryPartnerPerformanceState();
}

class _DeliveryPartnerPerformanceState extends State<DeliveryPartnerPerformance>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingRatings = true;
  bool _isLoadingComplaints = true;
  List<dynamic> _performanceData = [];
  List<dynamic> _complaintsData = [];
  final TextEditingController _searchController = TextEditingController();
  final Set<dynamic> _expandedPartnerIds = {};
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([_loadPerformanceData(), _loadComplaintsData()]);
  }

  Future<void> _loadPerformanceData() async {
    if (!mounted) return;
    setState(() => _isLoadingRatings = true);
    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/Admin/GetAllPartnersPerformance"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _performanceData = jsonDecode(response.body);
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
        Uri.parse("${ApiConstants.baseUrl}/Complaints/GetAllComplaints"),
      );
      if (response.statusCode == 200) {
        setState(() {
          _complaintsData = jsonDecode(response.body);
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
                _buildSearchBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _buildCustomTabBar(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _tabController.index == 0
                        ? "Customer Reviews"
                        : "Customer Complaints",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDCEBFF)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            hintText: "Search partner name...",
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEABF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFFF9C55E),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.black54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        onTap: (index) => setState(() {}),
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

    final filteredData = _performanceData.where((partner) {
      final name = (partner['fullName'] ?? "").toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(_searchQuery.isEmpty
            ? "No performance data found"
            : "No partners match '$_searchQuery'"),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPerformanceData,
      color: const Color(0xFFF9C55E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
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
            child: _buildPartnerCard(filteredData[index]),
          );
        },
      ),
    );
  }

  Widget _buildPartnerCard(dynamic partner) {
    final double rating = (partner['averageRating'] ?? 0.0).toDouble();
    final int reviews = partner['ratingCount'] ?? 0;
    final int complaints = partner['complaintCount'] ?? 0;
    final List<dynamic> recentRatings = partner['recentRatings'] ?? [];

    // Unique key to track expansion state (ID or fallback to Name)
    final dynamic partnerKey = partner['deliveryPartnerId'] ?? partner['fullName'];
    final bool isExpanded = _expandedPartnerIds.contains(partnerKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBFF), width: 1),
      ),
      child: Column( // Keep original column
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.black, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner['fullName'] ?? "N/A",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text("$reviews Reviews",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedPartnerIds.remove(partnerKey);
                                } else {
                                  _expandedPartnerIds.add(partnerKey);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEABF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    isExpanded ? "Less" : "All",
                                    style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF9C55E), size: 20),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: complaints > 0
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaints > 0 ? "$complaints complaints" : "No complaints",
                        style: TextStyle(
                          color: complaints > 0 ? Colors.red : Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (recentRatings.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Recent Ratings:",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                // Show only 2 ratings by default, show all if expanded
                final displayRatings = isExpanded 
                    ? recentRatings 
                    : recentRatings.take(2).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemCount: displayRatings.length,
                  itemBuilder: (context, rIndex) {
                    final r = displayRatings[rIndex];
                final DateTime date = DateTime.parse(r['createdAt']);
                final List<dynamic> tags = r['feedbackTags'] ?? [];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FF),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r['reviewerName'] ?? "Anonymous",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: i < (r['ratingValue'] ?? 0)
                                ? const Color(0xFFF9C55E)
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      if (r['comments'] != null &&
                          r['comments'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          r['comments'],
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAB9),
                                borderRadius: BorderRadius.circular(6),
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
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
                );
              },
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }

  Widget _buildComplaintsTab() {
    if (_isLoadingComplaints) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
      );
    }

    if (_complaintsData.isEmpty) {
      return const Center(child: Text("No complaints found"));
    }

    return RefreshIndicator(
      onRefresh: _loadComplaintsData,
      color: const Color(0xFFF9C55E),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _complaintsData.length,
        itemBuilder: (context, index) {
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
        },
      ),
    );
  }

  Widget _buildComplaintCard(dynamic complaint) {
    final DateTime date = DateTime.parse(complaint['createdAt']);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                complaint['complaintType'] ?? "N/A",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.red,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(date),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "by ${complaint['readerName']} • against ${complaint['partnerName']}",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              complaint['comments'] ?? "No comments",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
