import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:vaarthahub_app/services/api_service.dart';

class SubscribedReadersScreen extends StatefulWidget {
  final int partnerId;

  const SubscribedReadersScreen({super.key, required this.partnerId});

  @override
  State<SubscribedReadersScreen> createState() =>
      _SubscribedReadersScreenState();
}

class _SubscribedReadersScreenState extends State<SubscribedReadersScreen> {
  bool _isLoading = true;
  List<dynamic> _allSubscriptions = [];
  String _selectedFilter = "All";
  final TextEditingController _searchController = TextEditingController();

  // Group subscriptions by reader
  Map<String, List<dynamic>> get _groupedByReader {
    final Map<String, List<dynamic>> grouped = {};
    for (final s in _allSubscriptions) {
      final key = "${s['readerName'] ?? 'Unknown'}_${s['readerPhone'] ?? ''}";
      grouped.putIfAbsent(key, () => []).add(s);
    }
    return grouped;
  }

  List<MapEntry<String, List<dynamic>>> get _filteredReaders {
    final query = _searchController.text.toLowerCase();
    return _groupedByReader.entries.where((entry) {
      final subs = entry.value;
      final name = (subs.first['readerName'] ?? '').toLowerCase();
      final phone = (subs.first['readerPhone'] ?? '').toLowerCase();

      final matchesSearch =
          query.isEmpty || name.contains(query) || phone.contains(query);

      final matchesFilter =
          _selectedFilter == "All" ||
          subs.any((s) => s['isActive'] == _selectedFilter);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubscriptions() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Subscriptions/GetPartnerSubscriptions/${widget.partnerId}",
      );
      final response = await http.get(url);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _allSubscriptions = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      case 'Vacation':
        return Colors.orange;
      case 'Cancelled':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _typeColor(String? type) =>
      type == 'Newspaper' ? Colors.blue : Colors.purple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background element
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
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        _buildHeader(),
                        const SizedBox(height: 10),

                        // --- Search bar Method ---
                        _buildSearchBar(),

                        const SizedBox(height: 12),

                        // Filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              "All",
                              "Active",
                              "Expired",
                              "Vacation",
                            ].map((f) => _filterChip(f)).toList(),
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 150.ms),

                        const SizedBox(height: 16),

                        // Content
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF9C55E),
                                  ),
                                )
                              : _filteredReaders.isEmpty
                              ? const Center(
                                  child: Text("No subscribed readers found."),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchSubscriptions,
                                  color: const Color(0xFFF9C55E),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                    itemCount: _filteredReaders.length,
                                    itemBuilder: (context, index) {
                                      final entry = _filteredReaders[index];
                                      return _buildReaderCard(entry.value)
                                          .animate()
                                          .fadeIn(
                                            duration: 400.ms,
                                            delay: Duration(
                                              milliseconds: index * 60,
                                            ),
                                          )
                                          .slideY(begin: 0.08, end: 0);
                                    },
                                  ),
                                ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
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
            "Subcribed Readers",
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

  // --- Search Bar Widget Method ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search readers...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    final color = label == "All"
        ? const Color(0xFFF9C55E)
        : _statusColor(label);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReaderCard(List<dynamic> subs) {
    final first = subs.first;
    final name = first['readerName'] ?? 'Unknown Reader';
    final phone = first['readerPhone'] ?? 'N/A';

    List<String> addressParts = [];
    if (first['houseName'] != null &&
        first['houseName'].toString().isNotEmpty) {
      addressParts.add(first['houseName']);
    }
    if (first['houseNo'] != null && first['houseNo'].toString().isNotEmpty) {
      addressParts.add("H.No: ${first['houseNo']}");
    }
    if (first['panchayatName'] != null &&
        first['panchayatName'].toString().isNotEmpty) {
      addressParts.add(first['panchayatName']);
    }
    if (first['wardNumber'] != null &&
        first['wardNumber'].toString().isNotEmpty) {
      addressParts.add("Ward: ${first['wardNumber']}");
    }

    String computedAddress = addressParts.isEmpty
        ? "Address Not Updated"
        : addressParts.join(", ");

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Phone: $phone",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            "Address: $computedAddress",
            style: TextStyle(
              fontSize: 12,
              color: computedAddress == "Address Not Updated"
                  ? Colors.red
                  : Colors.black54,
              fontWeight: FontWeight.w500,
              fontStyle: computedAddress == "Address Not Updated"
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),

          ...subs.map((s) {
            final itemName =
                s['itemName'] ?? s['subscriptionName'] ?? 'Unknown';
            final itemType = s['itemType'] ?? '';
            final status = s['isActive'] ?? 'Unknown';
            final typeColor = _typeColor(itemType);
            final statusColor = _statusColor(status);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: typeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$itemName ($itemType)",
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
