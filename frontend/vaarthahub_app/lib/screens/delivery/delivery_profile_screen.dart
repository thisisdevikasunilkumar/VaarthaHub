import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaarthahub_app/services/api_service.dart';

import '../auth/login_screen.dart';
import '../delivery/delivery_partner_personal_info.dart';
import '../delivery/partner_ratings_screen.dart';

import '../settings screens/payment_methods_screen.dart';
import '../settings screens/notification_settings_screen.dart';
import '../settings screens/privacy_security_screen.dart';
import '../settings screens/language_preference_screen.dart';
import '../settings screens/help_and_support.dart';
import '../settings screens/terms_and_conditions.dart';
import '../settings screens/privacy_policy.dart';
import '../settings screens/about_vaarthahub.dart';

class DeliveryPartnerProfile extends StatefulWidget {
  final String partnerCode;

  const DeliveryPartnerProfile({super.key, required this.partnerCode});

  @override
  State<DeliveryPartnerProfile> createState() => _DeliveryPartnerProfileState();
}

class _DeliveryPartnerProfileState extends State<DeliveryPartnerProfile> {
  bool isLoading = true;
  Map<String, dynamic>? partnerData;

  @override
  void initState() {
    super.initState();
    fetchPartnerProfile();
  }

  Future<void> fetchPartnerProfile() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/DeliveryPartner/GetDeliveryPartnerProfile/${widget.partnerCode}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          partnerData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        _showError("Data not found. Please try again.");
      }
    } catch (e) {
      _showError("Connection Error: $e");
    }
  }

  void _showError(String message) {
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))),
      );
    }

    // --- FIX: ERROR SOLVED BY DECLARING THESE VARIABLES ---
    final String displayRating = partnerData?['averageRating']?.toString() ?? '0.0';
    final String displayName = partnerData?['fullName'] ?? 'Partner Name';
    final String displayPhone = partnerData?['phoneNumber'] ?? '+91 00000 00000';
    final String displayPartnerCode = partnerData?['partnerCode'] ?? 'DP-000';
    final String displayVehicleType = partnerData?['vehicleType'] ?? 'Unknown';
    final String displayVehicleNo = partnerData?['vehicleNumber'] ?? 'Unknown';
    final String displayLicenseNo = partnerData?['licenseNumber'] ?? 'Unknown';
    final String? profileImgBase64 = partnerData?['profileImage'];

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
                  "assets/logo/vaarthaHub-resolution-logo.png",
                  height: 45,
                  fit: BoxFit.contain,
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

                    /// PARTNER INFO & AVATAR ROW
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
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.green, size: 20),
                                  const SizedBox(width: 5),
                                  Text(
                                    displayPhone,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildBadge("Delivery Partner ID: $displayPartnerCode"),
                                  const SizedBox(width: 8),
                                  // Ippo ee variable work aakum
                                  _buildBadge("★ $displayRating",
                                      color: const Color(0xFFF9C55E), textColor: Colors.black),
                                ],
                              )
                            ],
                          ),

                          /// AVATAR WITH CIRCULAR BORDER
                          Container(
                            margin: const EdgeInsets.only(top: 40),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 15,
                                  offset: Offset(0, 8),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50, 
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 46,
                                backgroundImage: (profileImgBase64 != null && profileImgBase64.isNotEmpty)
                                ? MemoryImage(base64Decode(profileImgBase64)) as ImageProvider
                                : const AssetImage("assets/images/avatar-boy.png"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// VEHICLE DETAILS CARD
                    _buildVehicleCard(displayVehicleType, displayVehicleNo, displayLicenseNo),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// --- SECTION 1: SERVICE MANAGEMENT ---
                          const Text(
                            'Service Management',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          InkWell(
                            onTap: () {},
                            child: _buildSettingCard(
                              icon: Icons.assignment_late_outlined,
                              iconBg: const Color(0xFFF5E8FF),
                              iconColor: Colors.purple.shade400,
                              title: 'Reader Complaints',
                              subtitle: 'View delivery issues',
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {},
                            child: _buildSettingCard(
                              icon: Icons.swap_horizontal_circle_outlined,
                              iconBg: const Color(0xFFE0F7F9),
                              iconColor: Colors.teal.shade600,
                              title: 'Collection Services',
                              subtitle: 'Manage magazine swaps and scrap pickups',
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PartnerRatingsScreen()));
                            },
                            child: _buildSettingCard(
                              icon: Icons.star_outline_rounded,
                                iconBg: const Color(0xFFFFF7E6),
                                iconColor: Colors.orange,
                              title: 'Performance & Ratings',
                              subtitle: 'Check your service quality and reviews',
                            ),
                          ),
                          const SizedBox(height: 32),

                          /// --- SECTION 2: ACCOUNT SETTINGS ---
                          const Text(
                            'Account Settings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DeliveryPartnerPersonalInfo())).then((_) {
                                fetchPartnerProfile(); 
                              });
                            },
                            child: _buildSettingCard(
                              icon: Icons.person_outline_rounded,
                              iconBg: const Color(0xFFE8F0FF),
                              iconColor: Colors.blue,
                              title: 'Personal Information',
                              subtitle: 'Update your profile details',
                            ),
                          ),
                          const SizedBox(height: 12),

                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentMethodsScreen())),
                              child: _buildSettingCard(
                                icon: Icons.account_balance_wallet_outlined,
                                iconBg: const Color(0xFFFEEAE8),
                                iconColor: Colors.pink.shade400,
                                title: 'Save Payment Methods',
                                subtitle: 'Manage cards & UPI IDs',
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsScreen())),
                              child: _buildSettingCard(
                                icon: Icons.notifications_active_outlined,
                                iconBg: const Color(0xFFE8EAF6),
                                iconColor: const Color(0xFF3F51B5),
                                title: 'Notification',
                                subtitle: 'Manage notification preferences',
                              ),
                            ),
                            const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySecurityScreen(),),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.verified_user_outlined,
                              iconBg: const Color(0xFFE6F9F0),
                              iconColor: Colors.green,
                              title: 'Privacy & Security',
                              subtitle: 'Password, data settings',
                            ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguagePreferenceScreen(),),);
                            },
                            child: _buildSettingCard(
                              icon: Icons.chat_bubble_outline_rounded,
                              iconBg: const Color(0xFFF2F2F2),
                              iconColor: Colors.black54,
                              title: 'Language Preference',
                              subtitle: 'Malayalam / English',
                            ),
                          ),
                          const SizedBox(height: 32),

                          /// --- SECTION 3: GENERAL SETTINGS ---
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
                                  Icon(Icons.logout_rounded,
                                      color: Color(0xFFFF4D4D), size: 20),
                                  SizedBox(width: 8),
                                  Text('LogOut',
                                      style: TextStyle(
                                          color: Color(0xFFFF4D4D),
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              "VaarthaHub Made with ❤️ in Kerala",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
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
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: textColor ?? Colors.black)),
    );
  }

  /// VEHICLE DETAILS CARD WIDGET
  Widget _buildVehicleCard(String vehicleType, String vehicleNo, String licenseNo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.delivery_dining_outlined, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vehicle Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Vehicle Type", style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(vehicleType,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Registration No",
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(vehicleNo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("License No", style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text(licenseNo,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
      {required IconData icon,
      required Color iconBg,
      required Color iconColor,
      required String title,
      required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
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