import 'package:flutter/material.dart';

import '../auth/login_screen.dart'; 

import '../settings screens/help_and_support.dart';
import '../settings screens/terms_and_conditions.dart';
import '../settings screens/privacy_policy.dart';
import '../settings screens/about_vaarthahub.dart';

import '../admin/system_configuration_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 1. LOGO SECTION
            Padding(
              padding: const EdgeInsets.only(top: 50.0, left: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                    "assets/logo/vaarthaHub-resolution-logo.png", height: 45, fit: BoxFit.contain
                  ),
              ),
            ),

            /// 2. MAIN CONTENT STACK
            Stack(
              children: [
                /// THE CLOUD BACKGROUND
                Image.asset(
                  "assets/ui_elements/element6.png", 
                  width: double.infinity, 
                  fit: BoxFit.fitWidth,
                ),

                /// ALL CONTENT
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    /// ADMIN INFO & AVATAR ROW
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 80),
                              const Text(
                                'System Admin', 
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.verified_user, color: Colors.green, size: 20),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'vaarthahub@gmail.com',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildBadge("Super Admin Access", color: const Color(0xFFF9C55E), textColor: Colors.black),
                            ],
                          ),
                          
                          /// ADMIN AVATAR
                          Container(
                            margin: const EdgeInsets.only(top: 40),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Color(0xFFF2F2F2),
                              child: Icon(Icons.admin_panel_settings, size: 50, color: Color(0xFFF9C55E)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// ADMIN QUICK STATS 
                    _buildAdminStatsCard(),

                    const SizedBox(height: 30),

                    /// 3. MANAGEMENT SETTINGS SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Management Tools',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          
                          InkWell(
                            onTap: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemConfigurationScreen()),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.people_alt_outlined,
                              iconBg: const Color(0xFFE8F0FF),
                              iconColor: Colors.blue,
                              title: 'User Management',
                              subtitle: 'Manage Readers and Delivery Partners',
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemConfigurationScreen()),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.analytics_outlined,
                              iconBg: const Color(0xFFE6F9F0),
                              iconColor: Colors.green,
                              title: 'Revenue & Analytics',
                              subtitle: 'Track subscriptions and scrap revenue',
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemConfigurationScreen()),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.campaign_outlined,
                              iconBg: const Color(0xFFFFF7E6),
                              iconColor: Colors.orange,
                              title: 'Smart Classifieds Admin',
                              subtitle: 'Approve announcements and greetings',
                           ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemConfigurationScreen()),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.settings_suggest_outlined,
                              iconBg: const Color(0xFFF5E8FF),
                              iconColor: Colors.purple.shade400,
                              title: 'System Configuration',
                              subtitle: 'Manage app versions and core settings',
                            ),
                          ),
                          const SizedBox(height: 32),

                          const Text(
                            'General Settings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          _buildMenuTile(context, 'Help & Support', const HelpAndSupport()),
                          _buildMenuTile(context, 'Terms & Conditions', const TermsAndConditions()),
                          _buildMenuTile(context, 'Privacy Policy', const PrivacyPolicy()),
                          _buildMenuTile(context, 'About VaarthaHub', const AboutVaarthaHub()),

                          const SizedBox(height: 32),

                          /// LOGOUT BUTTON
                          InkWell(
                            onTap: () => _showLogoutDialog(context),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFB4B4)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout_rounded, color: Color(0xFFFF4D4D), size: 20),
                                  SizedBox(width: 8),
                                  Text('LogOut', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Center(child: Text("VaarthaHub Admin Panel v1.0", style: TextStyle(fontSize: 12, color: Colors.grey))),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// BADGE WIDGET
  Widget _buildBadge(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor ?? Colors.black)),
    );
  }

  /// ADMIN STATS CARD WIDGET
  Widget _buildAdminStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Total Users", "1.2k+"),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem("Active Routes", "45"),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem("Revenue", "₹45k"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFF9C55E))),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Exit from Admin Panel?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({required IconData icon, required Color iconBg, required Color iconColor, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, Widget targetPage) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}