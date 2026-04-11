import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../delivery/add_readers.dart';

import 'package:vaarthahub_app/models/reader_model.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ReadersManagement extends StatefulWidget {
  const ReadersManagement({super.key});

  @override
  State<ReadersManagement> createState() => _ReadersManagementState();
}

class _ReadersManagementState extends State<ReadersManagement> {
  String selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();
  
  List<ReaderModel> allReaders = []; // Original list from API
  List<ReaderModel> filteredReaders = []; // List after search/filter
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReaders();
  }

  // --- API Call to Fetch Readers ---
  Future<void> fetchReaders() async {
    try {
      // API call to fetch readers
      final url = Uri.parse('${ApiConstants.baseUrl}/DeliveryPartner/GetReaders');
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

  // --- Search & Filter Logic ---
  void _filterSearch(String query) {
    setState(() {
      filteredReaders = allReaders
          .where((reader) =>
              reader.fullName.toLowerCase().contains(query.toLowerCase()) ||
              reader.phoneNumber.contains(query))
          .toList();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
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
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 160, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                _buildSearchBar(),
                _buildFilterButtons(),
                
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
                      : filteredReaders.isEmpty
                          ? const Center(child: Text("No Readers Found"))
                          : RefreshIndicator(
                              onRefresh: fetchReaders,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: filteredReaders.length,
                                itemBuilder: (context, index) {
                                  final reader = filteredReaders[index];
                                  return _buildReaderCard(
                                    reader.fullName,
                                    reader.phoneNumber,
                                    reader.address ?? reader.panchayatName,
                                    "Active", // Backend-il status ippo illathath kond default
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

  // --- Header Section ---
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
                  // Wait for AddReader screen to close and refresh list
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

  // --- Search Bar ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch, // Call search logic on change
        decoration: InputDecoration(
          hintText: "Search by name or phone",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // --- Filter Buttons ---
  Widget _buildFilterButtons() {
    List<String> filters = ["All", "Active", "Vacation"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: filters.map((filter) {
          bool isSelected = selectedFilter == filter;
          Color selectedBg = const Color(0xFFFDEBB7); 
          Color textColor = Colors.black;

          if (filter == "Active") {
            selectedBg = const Color(0xFFC8F5C8);
            textColor = isSelected ? Colors.green.shade800 : Colors.black;
          } else if (filter == "Vacation") {
            selectedBg = const Color(0xFFFCE1DE);
            textColor = isSelected ? Colors.red.shade800 : Colors.black;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() => selectedFilter = filter);
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

  // --- Reader Card Widget ---
  Widget _buildReaderCard(String name, String phone, String address, String status) {
    bool isActive = status == "Active";
    Color statusColor = isActive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: statusColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_outline_rounded, size: 28),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(phone, style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 50, top: 4),
            child: Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionBtn("Call", Icons.call, Colors.blue, const Color(0xFFF2F6FF)),
              const SizedBox(width: 8),
              _actionBtn("View Details", Icons.visibility_outlined, Colors.grey.shade700, const Color(0xFFEFEFEF)),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}