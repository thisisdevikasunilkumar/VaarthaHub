import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../reader/address_update_options_screen.dart';

import '../reader/browse_subscriptions_screen.dart';
import '../reader/reader_other_product_booking_history_screen.dart';
import '../reader/delivery_partner_rating_screen.dart';
import '../reader/reader_feedback_history_screen.dart';

import '../reader/reader_personal_info.dart';
import '../settings screens/payment_methods_screen.dart';
import '../settings screens/notification_settings_screen.dart';
import '../settings screens/privacy_security_screen.dart';
import '../settings screens/language_preference_screen.dart';

import '../settings screens/help_and_support.dart';
import '../settings screens/terms_and_conditions.dart';
import '../settings screens/privacy_policy.dart';
import '../settings screens/about_vaarthahub.dart';

import '../auth/login_screen.dart';

import 'package:vaarthahub_app/services/api_service.dart';

class ReaderProfileScreen extends StatefulWidget {
  final String readerCode;

  const ReaderProfileScreen({super.key, required this.readerCode});

  @override
  State<ReaderProfileScreen> createState() => _ReaderProfileScreenState();
}

class _ReaderProfileScreenState extends State<ReaderProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? readerData;

  @override
  void initState() {
    super.initState();
    fetchReaderProfile();
  }

  Future<void> fetchReaderProfile() async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Reader/GetReaderProfile/${widget.readerCode}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          readerData = json.decode(response.body);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
        ),
      );
    }

    final String displayName = readerData?['fullName'] ?? 'User Name';
    final String displayPhone = readerData?['phoneNumber'] ?? '+91 00000 00000';
    final String? profileImgBase64 = readerData?['profileImage'];

    // --- Detailed Address Logic ---
    final String? hName = readerData?['houseName'];
    final String? hNo = readerData?['houseNo'];
    final String? lMark = readerData?['landmark'];
    final String? panchayat = readerData?['panchayatName'];
    final String? ward = readerData?['wardNumber']?.toString();
    final String? pincode = readerData?['pincode'];

    List<String> parts = [];
    if (hName != null && hName.isNotEmpty) parts.add(hName);
    if (hNo != null && hNo.isNotEmpty) parts.add("H.No: $hNo");
    if (lMark != null && lMark.isNotEmpty) parts.add(lMark);

    String mainAddress = parts.isNotEmpty
        ? parts.join(", ")
        : "Address Not Updated";

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: fetchReaderProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
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

              Stack(
                children: [
                  Image.asset(
                    "assets/ui_elements/element6.png",
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
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
                                    const Icon(
                                      Icons.phone,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      displayPhone,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildBadge("Premium Reader"),
                                    const SizedBox(width: 8),
                                    _buildBadge(
                                      "Gold Badge",
                                      color: const Color(0xFFF9C55E),
                                      textColor: Colors.black,
                                    ),
                                  ],
                                ),
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
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Color(0xFFF2F2F2),
                                  backgroundImage:
                                      (profileImgBase64 != null &&
                                          profileImgBase64.isNotEmpty)
                                      ? MemoryImage(
                                              // ignore: unnecessary_non_null_assertion
                                              base64Decode(profileImgBase64!),
                                            )
                                            as ImageProvider
                                      : null,
                                  // Only provide a child if the image is actually missing
                                  child:
                                      (profileImgBase64 == null ||
                                          profileImgBase64.isEmpty)
                                      ? const Icon(
                                          Icons.person_rounded,
                                          size: 50,
                                          color: Color(0xFFF9C55E),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      _buildAddressCard(mainAddress, panchayat, ward, pincode),
                      const SizedBox(height: 30),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Services',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BrowseSubscriptionsScreen(),
                                  ),
                                );
                              },
                              child: _buildSettingCard(
                                icon: Icons.receipt_long_outlined,
                                iconBg: const Color(0xFFF5E8FF),
                                iconColor: Colors.purple.shade400,
                                title: 'Subscriptions',
                                subtitle: 'Newspapers / Magazines',
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: () {
                                // Logic to add subscription
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => const BrowseSubscriptionsScreen(),
                                //   ),
                                // );
                              },
                              child: _buildSettingCard(
                                icon: Icons.ad_units_outlined,
                                iconBg: const Color(0xFFE0F7F9),
                                iconColor: Colors.teal.shade600,
                                title: 'Publications',
                                subtitle:
                                    'Track status of Obituaries, Greetings and Articles',
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: () {
                                final rId = readerData?['readerId'];
                                if (rId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReaderOtherProductBookingHistoryScreen(
                                            readerId: rId,
                                            readerCode: widget.readerCode,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: _buildSettingCard(
                                icon: Icons.shopping_bag_outlined,
                                iconBg: const Color(0xFFFFF0F0),
                                iconColor: Colors.redAccent,
                                title: 'My Product Bookings',
                                subtitle: 'History of Calendars & Diaries',
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: () {
                                final partnerCode =
                                    readerData?['addedByPartnerCode'] ?? '';
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DeliveryRatingScreen(
                                      partnerCode: partnerCode,
                                    ),
                                  ),
                                );
                              },
                              child: _buildSettingCard(
                                icon: Icons.star_outline_rounded,
                                iconBg: const Color(0xFFFFF7E6),
                                iconColor: Colors.orange,
                                title: 'Delivery Ratings',
                                subtitle:
                                    'Rate your delivery partner & service',
                              ),
                            ),
                            const SizedBox(height: 12),

                            InkWell(
                              onTap: () {
                                final rCode =
                                    readerData?['readerCode'] ??
                                    widget.readerCode;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReaderFeedbackHistoryScreen(
                                          readerCode: rCode,
                                        ),
                                  ),
                                );
                              },
                              child: _buildSettingCard(
                                icon: Icons.history_rounded,
                                iconBg: const Color(0xFFE3F2FD),
                                iconColor: Colors.blue.shade700,
                                title: 'My Feedback History',
                                subtitle: 'View your past ratings & complaints',
                              ),
                            ),
                            const SizedBox(height: 32),

                            const Text(
                              'Account Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReaderPersonalInformation(),
                                ),
                              ),
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PaymentMethodsScreen(),
                                ),
                              ),
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationSettingsScreen(),
                                ),
                              ),
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacySecurityScreen(),
                                ),
                              ),
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
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LanguagePreferenceScreen(),
                                ),
                              ),
                              child: _buildSettingCard(
                                icon: Icons.chat_bubble_outline_rounded,
                                iconBg: const Color(0xFFF2F2F2),
                                iconColor: Colors.black54,
                                title: 'Language Preference',
                                subtitle: 'Malayalam / English',
                              ),
                            ),
                            const SizedBox(height: 32),

                            const Text(
                              'General Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildMenuTile(
                              context,
                              'Help & Support',
                              const HelpAndSupport(),
                            ),
                            _buildMenuTile(
                              context,
                              'Terms & Conditions',
                              const TermsAndConditions(),
                            ),
                            _buildMenuTile(
                              context,
                              'Privacy Policy',
                              const PrivacyPolicy(),
                            ),
                            _buildMenuTile(
                              context,
                              'About VaarthaHub',
                              const AboutVaarthaHub(),
                            ),

                            const SizedBox(height: 32),

                            InkWell(
                              onTap: () => _showLogoutDialog(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFB4B4),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Color(0xFFFF4D4D),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'LogOut',
                                      style: TextStyle(
                                        color: Color(0xFFFF4D4D),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: Text(
                                "VaarthaHub Made with ❤️ in Kerala",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
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
      ),
    );
  }

  Widget _buildBadge(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black,
        ),
      ),
    );
  }

  Widget _buildAddressCard(
    String mainAddress,
    String? panchayat,
    String? ward,
    String? pincode,
  ) {
    bool isNotUpdated = mainAddress == "Address Not Updated";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isNotUpdated ? Colors.grey.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.place_outlined,
              color: isNotUpdated ? Colors.grey : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final rCode =
                            readerData?['readerCode'] ?? widget.readerCode;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddressUpdateOptionsScreen(readerCode: rCode),
                          ),
                        );
                        if (result == true) fetchReaderProfile();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          // ignore: deprecated_member_use
                          color: Colors.red.shade50.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_location_alt_outlined,
                              size: 14,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Edit",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  mainAddress,
                  style: TextStyle(
                    color: isNotUpdated ? Colors.grey : Colors.black87,
                    fontSize: 13,
                    fontWeight: isNotUpdated
                        ? FontWeight.normal
                        : FontWeight.w500,
                  ),
                ),
                if (!isNotUpdated) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${panchayat ?? ''}${ward != null && ward.isNotEmpty ? ' (Ward: $ward)' : ''}${pincode != null && pincode.isNotEmpty ? ' - $pincode' : ''}",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(BuildContext context, String title, Widget targetPage) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage),
      ),
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
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Clear all saved data on logout

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
