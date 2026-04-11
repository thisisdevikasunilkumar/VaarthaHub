// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  List<dynamic> _allBookings = [];
  List<dynamic> _filteredBookings = [];
  List<dynamic> _partners = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = "All";

  final List<String> _statusFilters = [
    "All",
    "Pending",
    "Shipped",
    "Delivered",
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingsResponse = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/OtherProductBookings/GetAdminBookings',
        ),
      );
      final partnersResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Admin/GetDeliveryPartners'),
      );

      if (bookingsResponse.statusCode == 200 &&
          partnersResponse.statusCode == 200) {
        setState(() {
          _allBookings = jsonDecode(bookingsResponse.body);
          _partners = jsonDecode(partnersResponse.body);
          _isLoading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _error = "Failed to load data from server";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBookings = _allBookings.where((booking) {
        final matchesSearch =
            booking['readerName'].toString().toLowerCase().contains(query) ||
            booking['bookingId'].toString().contains(query) ||
            booking['productName'].toString().toLowerCase().contains(query) ||
            (booking['phoneNumber'] ?? '').toString().contains(query);

        final matchesStatus =
            _selectedStatus == "All" ||
            (booking['status'] ?? '').toString() == _selectedStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _assignPartner(int bookingId, String partnerCode) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/OtherProductBookings/AssignPartner'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"bookingId": bookingId, "partnerCode": partnerCode}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Partner assigned successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to assign partner: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
                _buildSearchBar(),
                _buildStatusFilters(),
                const SizedBox(height: 8),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF9C55E),
                          ),
                        )
                      : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _filteredBookings.isEmpty
                      ? const Center(child: Text("No bookings found"))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
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
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Manage Bookings",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchData,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: "Search reader, booking ID, product...",
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = _selectedStatus == status;
            Color filterColor = _getStatusColor(status);

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                  });
                  _applyFilters();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration( // Keep original decoration
                    color: isSelected
                        ? filterColor.withValues(alpha: 0.15)
                        : const Color(0xFFFEEDC5).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(color: filterColor, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isSelected ? filterColor : Colors.black87,
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
      case 'Pending':
        return const Color(0xFFD97706);
      case 'Shipped':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return const Color(0xFFF9C55E);
    }
  }

  Widget _buildBookingCard(dynamic booking) {
    bool isAssigned =
        booking['status'] == 'Shipped' ||
        booking['status'] == 'Delivered' ||
        booking['assignedPartnerCode'] != null;

    final status = booking['status'] ?? 'Pending';
    final statusColor = _getStatusColor(status);

    return Container(
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
          // Header with Status Badge
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
                      DateFormat(
                        'dd MMM yyyy, hh:mm a',
                      ).format(DateTime.parse(booking['bookingDate'])),
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
                    decoration: BoxDecoration( // Keep original decoration
                    color: statusColor.withValues(alpha: 0.1),
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

          // Reader Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Color(0xFFF9C55E),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Reader Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailRow("Name", booking['readerName']),
                _detailRow("Phone", booking['phoneNumber']),
                _detailRow(
                  "Address",
                  "${booking['houseName']}, ${booking['houseNo']}, ${booking['landmark']}, ${booking['panchayatName']}, Ward ${booking['wardNumber']}, ${booking['pincode']}",
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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

          // Assignment Section
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
                      "Delivery Assignment",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isAssigned)
                  Container(
                    width: double.infinity,
                      padding: const EdgeInsets.all(12), // Keep original padding
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12), // Keep original radius
                        border: Border.all( // Keep original border
                          color: Colors.green.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      "Assigned to: ${booking['assignedPartnerCode']}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  _buildPartnerPicker(booking),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerPicker(dynamic booking) {
    String readerPanchayat = booking['panchayatName'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suggested Partners (Local):",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _partners.map((partner) {
              bool isLocal = partner['panchayatName'] == readerPanchayat;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        partner['fullName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        partner['panchayatName'],
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  selected: false,
                  selectedColor: const Color(0xFFF9C55E),
                  backgroundColor: isLocal
                      ? const Color(0xFFE0F2FE)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isLocal ? Colors.blue : Colors.grey.shade300,
                      width: isLocal ? 1.5 : 1,
                    ),
                  ),
                  onSelected: (selected) {
                    _showAssignmentConfirmation(
                      booking['bookingId'],
                      partner['partnerCode'],
                      partner['fullName'],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAssignmentConfirmation(
    int bookingId,
    String partnerCode,
    String partnerName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Assignment"),
        content: Text(
          "Assign partner $partnerName ($partnerCode) to this booking?\nStatus will change to 'Shipped'.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _assignPartner(bookingId, partnerCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9C55E),
            ),
            child: const Text(
              "Confirm",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
