import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class DeliveryMagazineSwapScreen extends StatefulWidget {
  const DeliveryMagazineSwapScreen({super.key});

  @override
  State<DeliveryMagazineSwapScreen> createState() =>
      _DeliveryMagazineSwapScreenState();
}

class _DeliveryMagazineSwapScreenState
    extends State<DeliveryMagazineSwapScreen> {
  String selectedFilter = 'All';
  bool _isLoading = true;
  List<dynamic> _pendingSwaps = [];
  List<dynamic> _completedSwaps = [];
  String? _partnerCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _partnerCode = prefs.getString('partnerCode');

      final pendingUrl = Uri.parse('${ApiConstants.baseUrl}/SwapRequests/pending/$_partnerCode');
      final completedUrl = Uri.parse('${ApiConstants.baseUrl}/SwapRequests/completed/$_partnerCode');

      final responses = await Future.wait([
        http.get(pendingUrl),
        http.get(completedUrl),
      ]);

      if (!mounted) return;
      
      if (responses[0].statusCode == 200) {
        _pendingSwaps = json.decode(responses[0].body);
      }
      if (responses[1].statusCode == 200) {
        _completedSwaps = json.decode(responses[1].body);
      }
      
      setState(() {});
    } catch (e) {
      debugPrint("Error fetching delivery swaps: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSwap(int swapId) async {
    if (_partnerCode == null) return;
    
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/SwapRequests/complete/$swapId');
      final res = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'partnerCode': _partnerCode}),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap Completed!'), backgroundColor: Colors.green));
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to complete swap.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      debugPrint("Error completing swap: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Background Design
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                // ignore: deprecated_member_use
                color: const Color(0xFFFDEBB7).withValues(alpha: 0.5),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                _buildFilters(),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedFilter == 'All' || selectedFilter == 'Pending') ...[
                              _sectionTitle("Pending Swap Requests"),
                              if (_pendingSwaps.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: Text("No pending swaps.", style: TextStyle(color: Colors.grey))),
                                )
                              else
                                ..._pendingSwaps.map((swp) => _buildPendingCard(swp)),
                            ],
                            
                            if (selectedFilter == 'All' || selectedFilter == 'Complete') ...[
                              const SizedBox(height: 20),
                              _sectionTitle("Completed Swaps"),
                              if (_completedSwaps.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(child: Text("No completed swaps yet.", style: TextStyle(color: Colors.grey))),
                                )
                              else
                                ..._completedSwaps.map((swp) => _buildCompletedCard(swp)),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
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
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Magazine Swap",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Pending', 'Complete'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: filters.map((filter) {
          bool isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF9C55E)
                    : const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Pending Request Card ---
  Widget _buildPendingCard(dynamic swp) {
    String swapItems = "${swp['offeredMagazine']} ⇄ ${swp['requestedMagazine']}";
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _iconContainer(Icons.sync, Colors.orange.shade50, Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  swapItems,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _statusBadge("Pending", const Color(0xFFFBE1AE), Colors.orange.shade900),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserDetailRow(swp['requestorName'], swp['receiverName'], "Service fee: ₹${swp['totalServiceFee']}", isPending: true),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _completeSwap(swp['swapId']),
            child: _buildActionButton(Icons.sync, "Complete Swap"),
          )
        ],
      ),
    );
  }

  // --- Completed Request Card ---
  Widget _buildCompletedCard(dynamic swp) {
    String swapItems = "${swp['offeredMagazine']} ⇄ ${swp['requestedMagazine']}";
    
    // Format date if available
    String dateStr = "";
    if (swp['completedAt'] != null) {
      DateTime dt = DateTime.parse(swp['completedAt']);
      dateStr = "${dt.day}/${dt.month}/${dt.year}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _iconContainer(Icons.sync, Colors.blue.shade50, Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  swapItems,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              _statusBadge("+ ₹${swp['totalServiceFee']}", const Color(0xFFE8F5E9), Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserDetailRow(swp['requestorName'], swp['receiverName'], dateStr, isPending: false),
        ],
      ),
    );
  }

  Widget _buildUserDetailRow(
    String from,
    String to,
    String subInfo, {
    required bool isPending,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "From: $from",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "To: $to",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subInfo,
                  style: TextStyle(
                    color: isPending ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9C55E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFD6E2FF).withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _iconContainer(IconData icon, Color bg, Color iconCol) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: iconCol, size: 20),
    );
  }

  Widget _statusBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
