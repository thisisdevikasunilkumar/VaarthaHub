// ignore_for_file: dead_null_aware_expression

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../delivery/add_readers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/models/reader_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ReadersManagement extends StatefulWidget {
  const ReadersManagement({super.key});

  @override
  State<ReadersManagement> createState() => _ReadersManagementState();
}

class _ReadersManagementState extends State<ReadersManagement> {
  // ignore: unused_field
  bool _isLoading = true;
  // ignore: unused_field
  String? _errorMessage;

  String selectedReaderStatus = "All";
  final TextEditingController _searchController = TextEditingController();

  List<ReaderModel> allReaders = [];
  List<ReaderModel> filteredReaders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReaders();
  }

  // --- Call Function ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showSnackBar("Could not launch dialer", Colors.red);
    }
  }

  Future<void> fetchReaders() async {
    final prefs = await SharedPreferences.getInstance();
    final partnerCode = prefs.getString('partnerCode');

    if (partnerCode == null) {
      setState(() {
        _isLoading = false;
        isLoading = false;
        _errorMessage = "Partner session not found. Please login again.";
      });
      return;
    }

    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/DeliveryPartner/GetMyReaders/$partnerCode',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          allReaders = data.map((json) => ReaderModel.fromJson(json)).toList();
          filteredReaders = allReaders;
          isLoading = false;
        });
      } else {
        _showSnackBar("Failed to load readers", Colors.red);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
      setState(() => isLoading = false);
    }
  }

  // Search filter function
  void _filterSearch(String query) {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      final query = _searchController.text.toLowerCase();

      filteredReaders = allReaders.where((r) {
        final matchesSearch =
            r.fullName.toLowerCase().contains(query) ||
            r.phoneNumber.contains(query);

        final matchesStatus =
            selectedReaderStatus == 'All' || (r.status == selectedReaderStatus);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  Container(height: 160, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 25),
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterButtons(),

                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFF9C55E),
                          ),
                        )
                      : filteredReaders.isEmpty
                      ? const Center(child: Text("No Readers Found"))
                      : RefreshIndicator(
                          onRefresh: fetchReaders,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filteredReaders.length,
                            itemBuilder: (context, index) {
                              final reader = filteredReaders[index];
                               String computedAddress = "${reader.houseName}, ${reader.houseNo}, ${reader.landmark}, ${reader.panchayatName}, Ward ${reader.wardNumber}, ${reader.pincode}";

                              return _buildReaderCard(
                                reader.fullName,
                                reader.phoneNumber,
                                computedAddress,
                                reader.status,
                                _getStatusColor(reader.status),
                              );
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
      padding: const EdgeInsets.fromLTRB(25, 20, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Reader Management",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Manage readers and subscribers",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddReaders()),
                  );
                  fetchReaders();
                },
                child: const Text(
                  "+ Add",
                  style: TextStyle(
                    color: Color(0xFFF9C55E),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch,
        decoration: InputDecoration(
          hintText: "Search by name or phone",
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

  Widget _buildFilterButtons() {
    List<String> filters = ["All", "Active", "Vacation"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((status) {
            final isSelected = selectedReaderStatus == status;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedReaderStatus = status;
                    _applyFilters();
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
        return Colors.red;
      default:
        return const Color(0xFFF9C55E);
    }
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildReaderCard(
    String name,
    String phone,
    String address,
    String status,
    Color color,
  ) {
    bool isActive = status == "Active";
    Color statusColor = isActive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ignore: deprecated_member_use
              _badge(status, color.withOpacity(0.1), color),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              address,
              style: TextStyle(
                fontSize: 12,
                color: address == "Address Not Updated" ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w500,
                fontStyle: address == "Address Not Updated" ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionBtn("Call", Icons.call, () {
                _makePhoneCall(phone);
              }),
              const SizedBox(width: 8),
              _actionBtn("View Details", Icons.visibility_outlined, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
