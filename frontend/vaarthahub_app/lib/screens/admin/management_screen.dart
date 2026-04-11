import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class _ManagementScreenState extends State<ManagementScreen> {
  String selectedFilter = 'All';
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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchPartners(),
      fetchReaders(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchPartners() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/Admin/GetDeliveryPartners'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          partners = data.map((item) => DeliveryPartnerModel.fromJson(item)).toList();
          filteredPartners = partners;
        });
      }
    } catch (e) {
      debugPrint("Partner Fetch Error: $e");
    }
  }

  Future<void> fetchReaders() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/DeliveryPartner/GetReaders');
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
      final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/Admin/DeletePartner/$id'));
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
        filteredPartners = partners.where((p) => p.fullName.toLowerCase().contains(query)).toList();
      } else {
        filteredReaders = allReaders.where((r) => r.fullName.toLowerCase().contains(query)).toList();
      }
    });
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png', 
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => Container(height: 150, color: const Color(0xFFF9C55E)),
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
                _buildFilterButtons(),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
                      : isDeliveryPartnerView
                          ? _buildPartnerListView() 
                          : _buildReaderListView(), 
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
                isDeliveryPartnerView ? "Monitor and manage delivery team" : "Manage readers and subscribers",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              if (isDeliveryPartnerView)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDeliveryPartner())).then((_) => fetchPartners()),
                  child: const Text("+ Add", style: TextStyle(color: Color(0xFFF9C55E), fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: const Color(0xFFFDEBB7).withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            _toggleItem("Delivery Partners", isDeliveryPartnerView, () => setState(() => isDeliveryPartnerView = true)),
            _toggleItem("Readers", !isDeliveryPartnerView, () => setState(() => isDeliveryPartnerView = false)),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTap();
          _searchController.clear();
          _applyFilters();
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF9C55E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _applyFilters(),
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    List<String> currentFilters = isDeliveryPartnerView 
        ? ["All", "Delivering", "InActive"] 
        : ["All", "Active", "Vacation"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: currentFilters.map((filter) {
          bool isSelected = selectedFilter == filter;
          Color selectedBg = const Color(0xFFFDEBB7); 
          Color textColor = Colors.black;

          if (filter == "Delivering" || filter == "Active") {
            selectedBg = const Color(0xFFC8F5C8);
            textColor = isSelected ? Colors.green.shade800 : Colors.black;
          } else if (filter == "InActive" || filter == "Vacation") {
            selectedBg = const Color(0xFFFCE1DE);
            textColor = isSelected ? Colors.red.shade800 : Colors.black;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: textColor)),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() => selectedFilter = filter);
                _applyFilters();
              },
              selectedColor: selectedBg,
              backgroundColor: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPartnerListView() {
    if (filteredPartners.isEmpty) return const Center(child: Text("No partners found"));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredPartners.length,
      itemBuilder: (context, index) {
        final partner = filteredPartners[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.green.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.local_shipping_outlined, color: Colors.black),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Row(children: [Icon(Icons.star, size: 16, color: Colors.orange), Text(" 4.5", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))]),
                    ],
                  ),
                  const Spacer(),
                  _badge("Delivering", Colors.green.shade50, Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              _earningsBox(partner.monthlyEarnings ?? 0),
              const SizedBox(height: 12),
              Row(
                children: [
                  _actionBtn("View Route", Icons.location_on_outlined, () {}),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmDelete(partner.id!),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1F1F1), elevation: 0),
                  child: const Text("Remove", style: TextStyle(color: Colors.black54)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

Widget _buildReaderListView() {
    if (filteredReaders.isEmpty) return const Center(child: Text("No readers found"));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredReaders.length,
      itemBuilder: (context, index) {
        final reader = filteredReaders[index];
        
        const String currentStatus = "Active"; 

        return _readerCard(
          reader.fullName,
          reader.phoneNumber,
          reader.address ?? "Address not available", 
          currentStatus, 
          Colors.green,
        );
      },
    );
  }

  Widget _readerCard(String name, String phone, String address, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_outline, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(phone, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              // ignore: deprecated_member_use
              _badge(status, color.withOpacity(0.1), color),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 4),
            child: Text(address, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionBtn("Call", Icons.call, () {}),
              const SizedBox(width: 8),
              _actionBtn("View Details", Icons.visibility_outlined, () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _earningsBox(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      // ignore: deprecated_member_use
      decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF9C55E).withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("₹ ${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Monthly Earnings", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: const Color(0xFFF2F6FF), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () { Navigator.pop(context); removePartner(id); }, child: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}