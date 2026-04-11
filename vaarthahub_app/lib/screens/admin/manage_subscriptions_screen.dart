import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ManageSubscriptionsScreen extends StatefulWidget {
  const ManageSubscriptionsScreen({super.key});

  @override
  State<ManageSubscriptionsScreen> createState() =>
      _ManageSubscriptionsScreenState();
}

class _ManageSubscriptionsScreenState extends State<ManageSubscriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _subscriptions = [];
  List<dynamic> _filteredSubscriptions = [];
  String _searchQuery = "";
  String _selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/Subscriptions/GetAllSubscriptionsWithDetails',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _subscriptions = data;
          _filterList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching subscriptions: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterList() {
    setState(() {
      _filteredSubscriptions = _subscriptions.where((s) {
        final nameMatch =
            (s['readerName'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (s['itemName'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (s['partnerCode'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (s['itemType'] ?? '').toString().toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

        final statusMatch =
            _selectedStatus == "All" || s['isActive'] == _selectedStatus;

        return nameMatch && statusMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
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
                const SizedBox(height: 32),
                _buildAppBar(),
                _buildSearchBar(),
                _buildStatusFilters(),
                const SizedBox(height: 15),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _buildSubscriptionList(),
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
            "Reader Subscriptions",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchSubscriptions,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: TextField(
        onChanged: (value) {
          _searchQuery = value;
          _filterList();
        },
        decoration: InputDecoration(
          hintText: "Search reader, item or partner code...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    final List<String> filters = ["All", "Active", "Vacation", "Expired"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((status) {
            final isSelected = _selectedStatus == status;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                    _filterList();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        // ignore: deprecated_member_use
                        ? _getStatusColor(status).withOpacity(0.2)
                        // ignore: deprecated_member_use
                        : const Color(0xFFFEEDC5).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: _getStatusColor(status), width: 1.5)
                        : null,
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSelected
                          ? _getStatusColor(status)
                          : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Vacation':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      default:
        return const Color(0xFFF9C55E);
    }
  }

  Widget _buildSubscriptionList() {
    if (_filteredSubscriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.newspaper_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No subscriptions found",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _filteredSubscriptions.length,
      itemBuilder: (context, index) {
        final sub = _filteredSubscriptions[index];
        return _buildSubscriptionCard(sub, index);
      },
    );
  }

  Widget _buildSubscriptionCard(dynamic sub, int index) {
    Color statusColor;
    IconData statusIcon;

    switch (sub['isActive'].toString()) {
      case 'Active':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Vacation':
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.beach_access_outlined;
        break;
      default:
        statusColor = const Color(0xFFE91E63);
        statusIcon = Icons.error_outline;
    }

    String formattedNextBill = "N/A";
    if (sub['nextBillDate'] != null) {
      formattedNextBill = DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(sub['nextBillDate']));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Top Row: Reader & Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub['readerName'] ?? 'Unknown Reader',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Partner ID: ${sub['partnerCode']}",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: Colors.orange),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "${sub['houseName'] ?? ''}, ${sub['houseNo'] ?? ''}, ${sub['landmark'] ?? ''}, ${sub['panchayatName'] ?? ''}, Ward ${sub['wardNumber'] ?? ''}, ${sub['pincode'] ?? ''}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      sub['isActive'],
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle: Subscription Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoColumn("PRODUCT", sub['itemName'] ?? 'Unknown Item'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoColumn("TYPE", sub['itemType'] ?? 'N/A'),
                      _infoColumn("DURATION", "${sub['durationMonths']} Mon"),
                      _infoColumn("AMOUNT", "₹${sub['totalAmount']}"),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom: Next Bill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Next Payout Cycle:",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    formattedNextBill,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideX(begin: 0.1, end: 0);
  }

  Widget _infoColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
