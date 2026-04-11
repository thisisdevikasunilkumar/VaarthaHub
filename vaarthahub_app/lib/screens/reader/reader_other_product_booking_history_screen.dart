import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/screens/reader/reader_order_details_screen.dart';

class ReaderOtherProductBookingHistoryScreen extends StatefulWidget {
  final int readerId;
  final String readerCode;
  const ReaderOtherProductBookingHistoryScreen({
    super.key,
    required this.readerId,
    required this.readerCode,
  });

  @override
  State<ReaderOtherProductBookingHistoryScreen> createState() =>
      _ReaderOtherProductBookingHistoryScreenState();
}

class _ReaderOtherProductBookingHistoryScreenState
    extends State<ReaderOtherProductBookingHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _allBookings = [];
  List<dynamic> _filteredBookings = [];
  final TextEditingController _searchController = TextEditingController();

  // Filters
  List<String> _selectedStatuses = [];
  String? _selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchBookingHistory();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBookingHistory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/OtherProductBookings/GetBookingsByReader/${widget.readerId}",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _allBookings = json.decode(response.body);
            _filteredBookings = List.from(_allBookings);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching booking history: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBookings = _allBookings.where((booking) {
        // Search Filter
        bool matchesSearch =
            booking['productName'].toString().toLowerCase().contains(query) ||
            booking['bookingId'].toString().contains(query) ||
            (booking['status'] ?? '').toString().toLowerCase().contains(query);

        // Status Filter
        bool matchesStatus =
            _selectedStatuses.isEmpty ||
            _selectedStatuses.any(
              (status) =>
                  booking['status']?.toString().toLowerCase() ==
                  status.toLowerCase(),
            );

        // Time Filter
        bool matchesTime = true;
        if (_selectedTime != null) {
          DateTime date = DateTime.parse(booking['bookingDate']);
          if (_selectedTime == "Last 30 days") {
            matchesTime = date.isAfter(
              DateTime.now().subtract(const Duration(days: 30)),
            );
          } else if (_selectedTime == "2025") {
            matchesTime = date.year == 2025;
          } else if (_selectedTime == "2026") {
            matchesTime = date.year == 2026;
          } else if (_selectedTime == "2024") {
            matchesTime = date.year == 2024;
          } else if (_selectedTime == "Older") {
            matchesTime = date.year < 2024;
          }
        }

        return matchesSearch && matchesStatus && matchesTime;
      }).toList();
    });
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
                _buildSearchBar(),
                _buildSummaryRow(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchBookingHistory,
                    color: const Color(0xFFF9C55E),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF9C55E),
                            ),
                          )
                        : _filteredBookings.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredBookings.length,
                            itemBuilder: (context, index) {
                              return _buildBookingCard(
                                    _filteredBookings[index],
                                    index,
                                  )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 50).ms,
                                    duration: 300.ms,
                                  )
                                  .slideX(begin: 0.1, end: 0);
                            },
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "My Orders",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchBookingHistory,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: "Search orders...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF1F1F1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _showFiltersBottomSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (_selectedStatuses.isNotEmpty || _selectedTime != null)
                    ? const Color(0xFFF9C55E)
                    : const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: (_selectedStatuses.isNotEmpty ||
                            _selectedTime != null)
                        ? Colors.black
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Filter",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: (_selectedStatuses.isNotEmpty ||
                              _selectedTime != null)
                          ? Colors.black
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking, int index) {
    final status = booking['status'] ?? 'Pending';
    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'Shipped':
        statusColor = Colors.blue; // Keep original color
        statusBgColor = Colors.blue.withValues(alpha: 0.1);
        break;
      case 'Delivered':
        statusColor = Colors.green; // Keep original color
        statusBgColor = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withValues(alpha: 0.1);
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusBgColor = const Color(0xFFFFF4D8);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReaderOrderDetailsScreen(
              booking: booking,
              readerCode: widget.readerCode,
            ),
          ),
        ).then((_) => _fetchBookingHistory());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF9C55E)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Booking ID + Status
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Booking #${booking['bookingId']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(
                          DateTime.parse(booking['bookingDate']),
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: booking['imageUrl'] != null
                          ? Image.network(
                              booking['imageUrl'].startsWith('http')
                                  ? booking['imageUrl']
                                  : '${ApiConstants.baseUrl.replaceAll('/api', '')}${booking['imageUrl']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${booking['productName']} (${booking['year']})",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${booking['itemType']} • ${booking['productType'] ?? 'Standard'}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        if (booking['size'] != null)
                          Text(
                            "Size: ${booking['size']}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Qty: ${booking['quantity']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "₹${booking['totalAmount']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFFF9C55E),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Delivery Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 18,
                        color: Color(0xFFF9C55E),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Delivery Info",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (booking['assignedPartnerCode'] != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Partner: ${booking['partnerName'] ?? booking['assignedPartnerCode']}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (booking['partnerPhone'] != null)
                            Text(
                              "Phone: ${booking['partnerPhone']}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Awaiting delivery partner assignment",
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "View Details",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final total = _filteredBookings.length;
    final pending = _filteredBookings
        .where((b) => b['status'] == 'Pending')
        .length;
    final delivered = _filteredBookings
        .where((b) => b['status'] == 'Delivered')
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _summaryChip("Total", total.toString(), Colors.black87),
          const SizedBox(width: 8),
          _summaryChip("Pending", pending.toString(), const Color(0xFFD97706)),
          const SizedBox(width: 8),
          _summaryChip("Delivered", delivered.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20), // Keep original radius
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "$label: $count",
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    _selectedStatuses.isNotEmpty ||
                    _selectedTime != null
                ? "No results found"
                : "No orders found",
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (_searchController.text.isNotEmpty ||
              _selectedStatuses.isNotEmpty ||
              _selectedTime != null)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedStatuses = [];
                  _selectedTime = null;
                });
                _applyFilters();
              },
              child: const Text(
                "Clear Filters",
                style: TextStyle(color: Color(0xFFF9C55E)),
              ),
            ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        selectedStatuses: _selectedStatuses,
        selectedTime: _selectedTime,
        onApply: (statuses, time) {
          setState(() {
            _selectedStatuses = statuses;
            _selectedTime = time;
          });
          _applyFilters();
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<String> selectedStatuses;
  final String? selectedTime;
  final Function(List<String>, String?) onApply;

  const _FilterSheet({
    required this.selectedStatuses,
    required this.selectedTime,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<String> _statuses;
  String? _time;

  @override
  void initState() {
    super.initState();
    _statuses = List.from(widget.selectedStatuses);
    _time = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSheetHeader(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Order Status",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip("On the way", "Shipped"),
                    _filterChip("Delivered"),
                    _filterChip("Pending"),
                    _filterChip("Cancelled"),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Order Time",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _timeChip("Last 30 days"),
                    _timeChip("2026"),
                    _timeChip("2025"),
                    _timeChip("2024"),
                    _timeChip("Older"),
                  ],
                ),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Filters",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _statuses = [];
                _time = null;
              });
            },
            child: const Text(
              "Clear Filter",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, [String? value]) {
    final chipValue = value ?? label;
    final isSelected = _statuses.contains(chipValue);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _statuses.remove(chipValue);
          } else {
            _statuses.add(chipValue);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? const Color(0xFFF9C55E) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? const Color(0xFFF9C55E).withValues(alpha: 0.15)
              : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected)
              const Icon(Icons.close, size: 14, color: Colors.black)
            else
              const Icon(Icons.add, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String label) {
    final isSelected = _time == label;
    return InkWell(
      onTap: () {
        setState(() {
          _time = isSelected ? null : label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? const Color(0xFFF9C55E) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? const Color(0xFFF9C55E).withValues(alpha: 0.15)
              : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[700],
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            if (isSelected)
              const Icon(Icons.close, size: 14, color: Colors.black)
            else
              const Icon(Icons.add, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_statuses, _time);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C55E),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Apply",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
