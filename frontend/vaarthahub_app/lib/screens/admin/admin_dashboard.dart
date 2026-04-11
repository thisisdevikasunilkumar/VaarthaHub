import 'package:flutter/material.dart';

import 'management_screen.dart';
import 'admin_profile_screen.dart'; 

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // --- Screens List ---
  final List<Widget> _adminScreens = [
    const DashboardHomeView(), // Index 0: Hello Admin Page
    const ManagementScreen(), // Index 1: Delivery Partners/Readers Management Page
    const Center(child: Text("Ad's Management")), // Index 2: Ads Management Page (Placeholder)
    const Center(child: Text("Analytics")), // Index 3: Analytics Page (Placeholder)
    const AdminProfileScreen(), // Index 4: Profile Page (Placeholder) 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _adminScreens[_selectedIndex], 
      
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1)],
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
          _navItem(Icons.grid_view_rounded, "Dashboard", 0),
          _navItem(Icons.people_outline, "Management", 1),
          _navItem(Icons.campaign_outlined, "Ads", 2),
          _navItem(Icons.analytics_outlined, "Analytics", 3),
          _navItem(Icons.account_circle_outlined,"Profile", 4),          
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

// --- Dashboard Home View Widget ---
class DashboardHomeView extends StatelessWidget {
  const DashboardHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Image.asset('assets/ui_elements/element4.png', fit: BoxFit.fill),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                Row(
                  children: [
                    const Text("Hello, ", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF9C55E), width: 1.5),
                      ),
                      child: const Text("Admin Panel!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Expanded(
                  child: Center(
                    child: Text("Statistics & Charts go here", style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}