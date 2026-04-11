import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../delivery/readers_management.dart';
import 'delivery_profile_screen.dart';

import '../../services/api_service.dart';


class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _selectedIndex = 0;
  String? loggedPartnerCode;
  Map<String, dynamic>? partnerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerCode();
  }

  Future<void> _loadPartnerCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedPartnerCode = prefs.getString('partnerCode') ?? "Unknown";
    });
    await fetchReaderProfile();
  }

  Future<void> fetchReaderProfile() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/DeliveryPartner/GetDeliveryPartnerProfile/$loggedPartnerCode");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          partnerData = json.decode(response.body);
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

  List<Widget> get _pages => [
    DeliveryHomeView(partnerData: partnerData),   // Index 0: Home Page
    const ReadersManagement(), // Index 1: Users Management Page
    const Center(child: Text("Scrap Management Page")), // Index 2
    const Center(child: Text("Route Management Page")), // Index 3
    DeliveryPartnerProfile(partnerCode: loggedPartnerCode?.toString() ?? "Unknown"), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    if (loggedPartnerCode == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex], 
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Bottom Navigation Bar ---
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          )
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
          _navItem(Icons.people_outline_rounded, "Users", 1),
          _navItem(Icons.recycling_rounded, "Scrap", 2),
          _navItem(Icons.location_on_outlined, "Route", 3),
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

// --- Separate Widget for Home Content ---
class DeliveryHomeView extends StatelessWidget {
  final Map<String, dynamic>? partnerData;

  const DeliveryHomeView({super.key, this.partnerData});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Background Wave (element4.png)
        Positioned(
          top: 0, left: 0, right: 0,
          child: Image.asset(
            'assets/ui_elements/element4.png', fit: BoxFit.fill, height: 200,),
        ),

        // 2. Main Content
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
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
                      "Hello, ${partnerData?['fullName'] ?? 'Partner'}!",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Cursive',
                      ),
                    ),
                  ],
                ),
              ),

              // --- Announcement Card ---
              _buildAnnouncementBox(),

              const Spacer(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
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
        child: Row(
          children: [
            const Expanded(
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
            const CircleAvatar(
              backgroundColor: Color(0xFFF9C55E),
              radius: 18,
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
            )
          ],
        ),
      ),
    );
  }
}