import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../admin/add_delivery_partner.dart';
import '../admin/deliverypartner_salary_details.dart';

import 'package:vaarthahub_app/models/delivery_partner_model.dart';
import 'package:vaarthahub_app/models/reader_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedPartnerStatus = 'All';
  String selectedReaderStatus = 'All';
  bool isDeliveryPartnerView = true;
  List<DeliveryPartnerModel> partners = [];
  List<DeliveryPartnerModel> filteredPartners = [];
  List<ReaderModel> allReaders = [];
  List<ReaderModel> filteredReaders = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          isDeliveryPartnerView = _tabController.index == 0;
          // Reset search and status when switching tabs
          _searchController.clear();
          selectedPartnerStatus = 'All';
          selectedReaderStatus = 'All';
          _applyFilters();
        });
      }
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([fetchPartners(), fetchReaders()]);
    setState(() => isLoading = false);
  }

  // --- Call Function ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showFeedback("Could not launch dialer", Colors.red);
    }
  }

  Future<void> fetchPartners() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/Admin/GetDeliveryPartners'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          partners = data
              .map((item) => DeliveryPartnerModel.fromJson(item))
              .toList();
          filteredPartners = partners;
        });
      }
    } catch (e) {
      debugPrint("Partner Fetch Error: $e");
    }
  }

  Future<void> fetchReaders() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/Admin/GetReaders');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          allReaders = data.map((json) => ReaderModel.fromJson(json)).toList();
          filteredReaders = allReaders;
        });
      }
    } catch (e) {
      debugPrint("Reader Fetch Error: $e");
    }
  }

  Future<void> removePartner(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/Admin/DeletePartner/$id'),
      );
      if (response.statusCode == 200) {
        setState(() {
          partners.removeWhere((p) => p.id == id);
          _applyFilters();
        });
        _showFeedback("Delivery Partner Removed Successfully!", Colors.green);
      }
    } catch (e) {
      _showFeedback("Could not remove partner.", Colors.redAccent);
    }
  }

  void _applyFilters() {
    setState(() {
      final query = _searchController.text.toLowerCase();

      if (isDeliveryPartnerView) {
        filteredPartners = partners.where((p) {
          final matchesSearch = p.fullName.toLowerCase().contains(query);
          final matchesStatus =
              selectedPartnerStatus == 'All' ||
              p.status == selectedPartnerStatus;
          return matchesSearch && matchesStatus;
        }).toList();
      } else {
        filteredReaders = allReaders.where((r) {
          final matchesSearch = r.fullName.toLowerCase().contains(query);
          final matchesStatus =
              selectedReaderStatus == 'All' || r.status == selectedReaderStatus;
          return matchesSearch && matchesStatus;
        }).toList();
      }
    });
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                _buildToggleSwitch(),
                _buildSearchBar(),
                _buildStatusFilters(),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Delivery Partners Tab
                      RefreshIndicator(
                        onRefresh: fetchPartners,
                        color: const Color(0xFFF9C55E),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF9C55E),
                                ),
                              )
                            : filteredPartners.isEmpty
                            ? _buildEmptyState("No delivery partners found")
                            : ListView.builder(
                                padding: const EdgeInsets.all(15),
                                itemCount: filteredPartners.length,
                                itemBuilder: (context, index) =>
                                    _buildPartnerCard(filteredPartners[index]),
                              ),
                      ),
                      // Readers Tab
                      RefreshIndicator(
                        onRefresh: fetchReaders,
                        color: const Color(0xFFF9C55E),
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFF9C55E),
                                ),
                              )
                            : filteredReaders.isEmpty
                            ? _buildEmptyState("No readers found")
                            : ListView.builder(
                                padding: const EdgeInsets.all(15),
                                itemCount: filteredReaders.length,
                                itemBuilder: (context, index) =>
                                    _buildReaderCard(filteredReaders[index]),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Sections ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDeliveryPartnerView ? "Delivery Partners" : "Reader Management",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDeliveryPartnerView
                    ? "Monitor and manage delivery team"
                    : "Manage readers and subscribers",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (isDeliveryPartnerView)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDeliveryPartner(),
                    ),
                  ).then((_) => fetchPartners()),
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

  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: const Color(0xFFFEEDC5).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFFF9C55E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              // ignore: deprecated_member_use
              BoxShadow(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Delivery Partners"),
            Tab(text: "Readers"),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _applyFilters(),
        decoration: InputDecoration(
          hintText: "Search",
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
    final List<String> statuses = isDeliveryPartnerView
        ? ['All', 'Delivering', 'InActive']
        : ['All', 'Active', 'Vacation'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = isDeliveryPartnerView
                ? selectedPartnerStatus == status
                : selectedReaderStatus == status;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isDeliveryPartnerView) {
                      selectedPartnerStatus = status;
                    } else {
                      selectedReaderStatus = status;
                    }
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
      case 'Delivering':
      case 'Active':
        return Colors.green;
      case 'InActive':
      case 'Vacation':
        return Colors.red;
      default:
        return const Color(0xFFF9C55E);
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(DeliveryPartnerModel partner) {
    Color statusColor = partner.status == "Delivering"
        ? Colors.green
        : Colors.red;
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
                  Icons.local_shipping_outlined,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.fullName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      Text(
                        " ${partner.averageRating}",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              // ignore: deprecated_member_use
              _badge(partner.status, statusColor.withOpacity(0.1), statusColor),
            ],
          ),
          const SizedBox(height: 15),
          _earningsBox(partner.monthlyEarnings ?? 0),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionBtn("View Route", Icons.location_on_outlined, () {}),
              const SizedBox(width: 10),
              _actionBtn("View Salary", Icons.payments_outlined, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryPartnerSalaryDetails(
                      partnerId: partner.id!,
                      partnerName: partner.fullName,
                    ),
                  ),
                ).then((_) => fetchPartners());
              }),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _confirmDelete(partner.id!),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE9E9E9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Remove",
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReaderCard(ReaderModel reader) {
    Color statusColor = reader.status == "Active" ? Colors.green : Colors.red;
    return _readerCard(
      reader.fullName,
      reader.phoneNumber,
      reader.houseName != null && reader.houseNo != null
          ? "${reader.houseName} ${reader.houseNo}, ${reader.panchayatName}, Ward ${reader.wardNumber ?? ''}"
                .trim()
          : reader.panchayatName,
      reader.addedByPartnerCode,
      reader.status,
      statusColor,
    );
  }

  Widget _readerCard(
    String name,
    String phone,
    String address,
    String addedByPartnerCode,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "Added by: $addedByPartnerCode",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
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

  Widget _earningsBox(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      // ignore: deprecated_member_use
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        border: Border.all(color: const Color(0xFFF9C55E).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "₹ ${amount.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            "Monthly Earnings",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Remove Partner?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removePartner(id);
            },
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
