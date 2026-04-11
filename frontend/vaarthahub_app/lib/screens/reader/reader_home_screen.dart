import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../reader/reader_profile_screen.dart';
import '../reader/categories_screen.dart';
import '../reader/vaartha_bot_screen.dart';

import '../../services/api_service.dart';

class ReaderHomeScreen extends StatefulWidget {
  const ReaderHomeScreen({super.key});

  @override
  State<ReaderHomeScreen> createState() => _ReaderHomeScreenState();
}

class _ReaderHomeScreenState extends State<ReaderHomeScreen> {
  int _selectedIndex = 0;
  String? loggedReaderCode;
  Map<String, dynamic>? readerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReaderCode();
  }

  Future<void> _loadReaderCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedReaderCode = prefs.getString('readerCode') ?? '1';
    });
    await fetchReaderProfile();
  }

  Future<void> fetchReaderProfile() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Reader/GetReaderProfile/$loggedReaderCode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          readerData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Widget> get _readerScreens => [
    ReaderHomeView(readerData: readerData), // Home View
    const CategoriesScreen(), // Categories View
    const Center(child: Text("Scrap Management")), // Scrap Management View
    const Center(child: Text("Bills & Payments")), // Bills & Payments View
    ReaderProfileScreen(readerCode: loggedReaderCode?.toString() ?? '1'), // Profile View
  ];

  @override
  Widget build(BuildContext context) {
    if (loggedReaderCode == null || isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _readerScreens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF9C55E),
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          _navItem(Icons.home_filled, "Home", 0),
          _navItem(Icons.manage_search_rounded, "Category", 1),
          _navItem(Icons.recycling_rounded, "Scrap", 2),
          _navItem(Icons.receipt_long_outlined, "Bills", 3),
          _navItem(Icons.person_outline_rounded, "Profile", 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBE1AE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

// --- Reader Home View (UI Design) ---
class ReaderHomeView extends StatelessWidget {
  final Map<String, dynamic>? readerData;

  const ReaderHomeView({super.key, this.readerData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Image.asset('assets/ui_elements/element4.png', fit: BoxFit.fill),
        ),

        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildAnnouncementBox(),
                _buildTopContributorsHeader(),
                _buildContributorsList(),
                _buildStatusCards(context),
                _buildActionTiles(),
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),

        const _AIChatbotFab(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/logo/vaarthaHub-resolution-logo.png', height: 45),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_outlined, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Hello, ${readerData?['fullName'] ?? 'Reader'}!",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontFamily: 'Cursive',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE1AE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Announcement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 5),
                  Text(
                    "Your monthly newspaper bill is pending. Kindly pay on time to continue uninterrupted delivery.",
                    style: TextStyle(fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: Color(0xFFF9C55E),
              radius: 18,
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopContributorsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Top Contributors", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {},
            child: const Text("See All", style: TextStyle(color: Color(0xFFF9C55E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsList() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20),
        children: [
          _contributorAvatar("Monika", "assets/images/avatar-1.png"),
          _contributorAvatar("Vaysak", "assets/images/avatar-2.png"),
          _contributorAvatar("Ritha", "assets/images/avatar-3.png"),
          _contributorAvatar("Sreyas", "assets/images/avatar-4.png"),
        ],
      ),
    );
  }

  Widget _contributorAvatar(String name, String imgPath) {
    return Padding(
      padding: const EdgeInsets.only(left: 17, right: 5),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: AssetImage(imgPath),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildStatusCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(child: _statusCard(
            "My Rewards", "125 Points", 'assets/images/achievement-award-medal-icon.png', const Color(0xFFFBE1AE),
            
          )),
          const SizedBox(width: 15),
          Expanded(child: _statusCard(
            "Vacation Mode", "Pause delivery", 'assets/images/sun-bath-icon.png', Colors.white,
          )),
        ],
      ),
    );
  }

  Widget _statusCard(String title, String subtitle, String iconPath, Color bgColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Image.asset(iconPath, width: 35),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTiles() {
    return Column(
      children: [
        _actionTile("Scrap Pickup Request", "You have collected about 15kg of old nespapers", 'assets/images/recycle-trash-bin-paper-icon.png'),
        _actionTile("Announcement Booking", "Post announcement in newspapers", 'assets/images/Obituaries.png'),
        _actionTile("Register Complaints", "Regarding newspaper delivery issues", 'assets/images/Complaints.png'),
      ],
    );
  }

  Widget _actionTile(String title, String sub, String iconPath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Image.asset(iconPath, width: 50),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, size: 20, color: Colors.black),
        ],
      ),
    );
  }
}

class _AIChatbotFab extends StatelessWidget {
  const _AIChatbotFab();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      right: 15,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VaarthaBotScreen()),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(right: 35, bottom: 5),
              decoration: const BoxDecoration(
                color: Color(0xFFD3DEFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
              ),
              child: const Text(
                "നമസ്കാരം!\nഎന്ത് സഹായം വേണം?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1C47C9), width: 2),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/AI-Chatbot.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}