import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final bool isRole; // Reader/Partner thirichariyaan
  const NotificationSettingsScreen({super.key, this.isRole = false});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification states
  bool _pushNotifications = true;
  bool _taskUpdates = true;
  bool _announcements = false;
  bool _offersAndPromos = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Manage how you receive alerts and updates from VaarthaHub.",
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 30),

              /// --- MASTER SWITCH CARD ---
              _buildNotificationCard(
                title: "Push Notifications",
                subtitle: "Receive instant alerts on your device for all activities.",
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
                icon: Icons.notifications_active_rounded,
              ),

              const SizedBox(height: 35),
              const Text(
                "NOTIFICATION CATEGORIES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
              ),
              const SizedBox(height: 15),

              /// --- DETAILED CONTROLS ---
              Opacity(
                opacity: _pushNotifications ? 1.0 : 0.5,
                child: AbsorbPointer(
                  absorbing: !_pushNotifications,
                  child: Column(
                    children: [
                      // Reader-num Partner-num labels maarum
                      _buildCustomSwitchTile(
                        title: widget.isRole ? "Delivery Task Alerts" : "Delivery & Order Updates",
                        subtitle: widget.isRole 
                            ? "Get notified when a new delivery task is assigned." 
                            : "Get notified when your newspaper is delivered.",
                        value: _taskUpdates,
                        onChanged: (val) => setState(() => _taskUpdates = val),
                      ),
                      const Divider(height: 35, thickness: 0.5),
                      
                      _buildCustomSwitchTile(
                        title: "Community Announcements",
                        subtitle: "Birthday wishes and local digital classifieds.",
                        value: _announcements,
                        onChanged: (val) => setState(() => _announcements = val),
                      ),
                      const Divider(height: 35, thickness: 0.5),

                      _buildCustomSwitchTile(
                        title: "Offers & Promos",
                        subtitle: "Discounts on subscriptions and new services.",
                        value: _offersAndPromos,
                        onChanged: (val) => setState(() => _offersAndPromos = val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
      ),
    );
  }

  // AppBar Helper
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Notifications",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  // --- Main Premium Card with FBD78F & F9C55E ---
  Widget _buildNotificationCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFFBD78F).withOpacity(0.15), // Light Gold
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        border: Border.all(color: const Color(0xFFFBD78F).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9C55E), // Main Gold
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.black87, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                // ignore: deprecated_member_use
                activeColor: const Color(0xFFF9C55E),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // --- Switch Tile with Gold Theme ---
  Widget _buildCustomSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          // ignore: deprecated_member_use
          activeColor: const Color(0xFFF9C55E), // Main Gold
          activeTrackColor: const Color(0xFFFBD78F), // Light Gold for track
        ),
      ],
    );
  }
}