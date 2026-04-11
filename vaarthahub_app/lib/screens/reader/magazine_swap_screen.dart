import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

import '../reader/add_magazine_swap_screen.dart';

class MagazineSwapScreen extends StatefulWidget {
  const MagazineSwapScreen({super.key});

  @override
  State<MagazineSwapScreen> createState() => _MagazineSwapScreenState();
}

class _MagazineSwapScreenState extends State<MagazineSwapScreen> {
  int? _readerId;
  bool _isLoading = true;
  List<dynamic> _availableRequests = [];
  List<dynamic> _myRequests = [];
  List<dynamic> _activeSwaps = [];

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
      final readerCode = prefs.getString('readerCode');
      if (readerCode != null) {
        final profileUrl = Uri.parse(
          '${ApiConstants.baseUrl}/Reader/GetReaderProfile/$readerCode',
        );
        final profileRes = await http.get(profileUrl);
        if (!mounted) return;
        if (profileRes.statusCode == 200) {
          final profile = json.decode(profileRes.body);
          setState(() {
            _readerId = profile['readerId'];
          });
        }
      }

      if (_readerId != null) {
        await Future.wait([_fetchAvailableRequests(), _fetchMyHistory()]);
      }
    } catch (e) {
      debugPrint("Error loading swap data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableRequests() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/SwapRequests/available-requests/$_readerId',
    );
    final res = await http.get(url);
    if (res.statusCode == 200 && mounted) {
      setState(() {
        _availableRequests = json.decode(res.body);
      });
    }
  }

  Future<void> _fetchMyHistory() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/SwapRequests/reader/$_readerId',
    );
    final res = await http.get(url);
    if (res.statusCode == 200 && mounted) {
      final data = json.decode(res.body) as List<dynamic>;
      setState(() {
        _myRequests = data
            .where(
              (r) => r['isInitiator'] == true && r['status'] == 'Requested',
            )
            .toList();
        _activeSwaps = data.where((r) => r['status'] != 'Requested').toList();
      });
    }
  }

  Future<void> _proposeSwap(int swapId, String offeredMag) async {
    // Show a dialog to enter the price of the magazine being offered in return
    double price = 0.0;
    bool? proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final txtCtrl = TextEditingController();
        return AlertDialog(
          title: Text('Propose Swap for $offeredMag'),
          content: TextField(
            controller: txtCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter value of your magazine',
              prefixText: '₹ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                price = double.tryParse(txtCtrl.text) ?? 50.0;
                Navigator.pop(context, true);
              },
              child: const Text('Propose'),
            ),
          ],
        );
      },
    );

    if (proceed != true) return;

    if (!mounted) return;
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/SwapRequests/propose/$swapId',
      );
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'receiverReaderId': _readerId,
          'requestedMagazinePrice': price,
        }),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Swap Proposal Sent!'), backgroundColor: Colors.green));
        await _loadData();
      } else {
        final error = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? 'Error sending proposal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Propose swap error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewProposals(dynamic req) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => _ProposalsList(
          swapId: req['swapId'] ?? 0,
          magName: req['offeredMagazine'] ?? "Magazine",
          controller: controller,
          onAccepted: () {
            Navigator.pop(context);
            _loadData();
          },
        ),
      ),
    );
  }

  Future<void> _removeListing(int swapId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Remove Listing?"),
        content: const Text(
          "Are you sure you want to remove this swap listing?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/SwapRequests/$swapId');
      final res = await http.delete(url);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing removed successfully.')),
        );
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove listing.')),
        );
      }
    } catch (e) {
      debugPrint("Remove listing error: $e");
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
          // Top Curved Background Element
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 120, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildHeader(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeader("My Listings", showAdd: true),
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (_myRequests.isEmpty)
                                  const Text(
                                    "No active listings",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ..._myRequests.map(
                                    (req) => _buildMyListingCard(req),
                                  ),

                                const SizedBox(height: 24),

                                _sectionHeader(
                                  "Available for Swap (${_availableRequests.length})",
                                ),
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (_availableRequests.isEmpty)
                                  const Text(
                                    "No available requests currently",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ..._availableRequests.map(
                                    (req) => _buildAvailableSwapCard(req),
                                  ),

                                const SizedBox(height: 24),

                                _sectionHeader("Active Swaps"),
                                if (_isLoading)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                else if (_activeSwaps.isEmpty)
                                  const Text(
                                    "No active swaps",
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ..._activeSwaps.map(
                                    (swp) => _buildActiveSwapCard(swp),
                                  ),

                                const SizedBox(height: 24),

                                _buildHowItWorksCard(),
                                const SizedBox(height: 40),
                              ],
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

  // --- Header Section ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 5),
          const Text(
            "Magazine Swap",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- Section Title Helper ---
  Widget _sectionHeader(String title, {bool showAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (showAdd)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMagazineSwapScreen(),
                  ),
                ).then((_) => _loadData());
              },
              child: const Text(
                "+ Add",
                style: TextStyle(
                  color: Color(0xFFFDC055),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 1. My Listing Card ---
  Widget _buildMyListingCard(dynamic req) {
    String magName = req['offeredMagazine'] ?? "Unknown";
    String initial = magName.isNotEmpty ? magName[0].toUpperCase() : "M";
    bool hasProposals = (req['proposalCount'] ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _buildLogoPlaceholder(initial, Colors.green[50]!),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      req['issueEdition'] ?? "Any Edition",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "Looking for: ${req['requestedMagazine']}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      req['status'],
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasProposals) ...[
                    const SizedBox(height: 6),
                    Text(
                      "${req['proposalCount']} Requests",
                      style: const TextStyle(
                        color: Color(0xFF4A69FF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasProposals) ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _viewProposals(req),
                    child: _buildButton(
                      "View Requests",
                      const Color(0xFFFDEBB7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddMagazineSwapScreen(editData: req),
                        ),
                      ).then((_) => _loadData());
                    },
                    child: _buildButton(
                      "Edit",
                      const Color(0xFFF1F4F8),
                      textColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddMagazineSwapScreen(editData: req),
                        ),
                      ).then((_) => _loadData());
                    },
                    child: _buildButton("Edit", const Color(0xFFFDEBB7)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _removeListing(req['swapId']),
                    child: _buildButton(
                      "Remove",
                      const Color(0xFFF1F4F8),
                      textColor: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- 2. Available for Swap Card ---
  Widget _buildAvailableSwapCard(dynamic req) {
    String magName = req['offeredMagazine'] ?? "Unknown";
    String initial = magName.isNotEmpty ? magName[0].toUpperCase() : "M";
    String requestorName = req['requestorName'] ?? "Reader";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _buildLogoPlaceholder(initial, Colors.blue[50]!),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      magName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      req['issueEdition'] ?? "Any Edition",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserDetailRow(
            requestorName,
            "Wants: ${req['requestedMagazine']}",
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _proposeSwap(req['swapId'], magName),
            child: _buildActionButton(Icons.sync, "Propose Swap"),
          ),
        ],
      ),
    );
  }

  // --- 3. Active Swap Card ---
  Widget _buildActiveSwapCard(dynamic swp) {
    String swapTitle =
        "${swp['offeredMagazine']} ⇄ ${swp['requestedMagazine']}";
    String otherParty = swp['otherPartyName'] ?? "Unknown";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sync, color: Colors.brown, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  swapTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserDetailRow(
            otherParty,
            "Status: ${swp['status']}",
            subTextColor: swp['status'] == 'Completed'
                ? Colors.green
                : Colors.orange,
          ),
        ],
      ),
    );
  }

  // --- 4. How it Works (Bottom Section) ---
  Widget _buildHowItWorksCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFFDEBB7).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How Magazine Swap Works",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildStep(1, "List your read magazines for exchange"),
          _buildStep(2, "Browse and request swaps from nearby readers"),
          _buildStep(3, "Our delivery partner facilitates the exchange"),
          _buildStep(
            4,
            "50% of the magazine price will be charged as a service fee",
          ),
          _buildStep(5, "Enjoy new reading at a minimal cost!"),
        ],
      ),
    );
  }

  // --- UI Reusable Components ---
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade100),
    );
  }

  Widget _buildLogoPlaceholder(String text, Color color) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color color, {
    Color textColor = Colors.brown,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildUserDetailRow(
    String name,
    String sub, {
    Color subTextColor = Colors.grey,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      // ignore: deprecated_member_use
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(sub, style: TextStyle(color: subTextColor, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFFDC055),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.brown),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.brown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFFFDC055),
            child: Text(
              number.toString(),
              style: const TextStyle(fontSize: 10, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalsList extends StatefulWidget {
  final int swapId;
  final String magName;
  final ScrollController controller;
  final VoidCallback onAccepted;

  const _ProposalsList({
    required this.swapId,
    required this.magName,
    required this.controller,
    required this.onAccepted,
  });

  @override
  _ProposalsListState createState() => _ProposalsListState();
}

class _ProposalsListState extends State<_ProposalsList> {
  List<dynamic> _proposals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProposals();
  }

  Future<void> _fetchProposals() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/SwapRequests/${widget.swapId}/proposals',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _proposals = json.decode(res.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptThisProposal(int proposalId) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/SwapRequests/accept-proposal/$proposalId',
      );
      final res = await http.put(url);
      if (res.statusCode == 200) {
        widget.onAccepted();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error accepting proposal.')),
        );
      }
    } catch (e) {
      debugPrint("Accept error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Requests for '${widget.magName}'",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _proposals.isEmpty
                ? const Center(child: Text("No proposals found."))
                : ListView.builder(
                    controller: widget.controller,
                    itemCount: _proposals.length,
                    itemBuilder: (context, index) {
                      final p = _proposals[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFBE1AE),
                              child: Icon(Icons.person, color: Colors.brown),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['receiverName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Offers: ${p['offeredMagazine']}",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  _acceptThisProposal(p['proposalId']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFDC055),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              child: const Text(
                                "Accept",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
