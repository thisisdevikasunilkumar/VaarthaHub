import 'package:flutter/material.dart';

class ProfileVisibilityScreen extends StatefulWidget {
  const ProfileVisibilityScreen({super.key});

  @override
  State<ProfileVisibilityScreen> createState() => _ProfileVisibilityScreenState();
}

class _ProfileVisibilityScreenState extends State<ProfileVisibilityScreen> {
  bool _isPublic = true;
  bool _showReadingHistory = false;
  bool _showAnnouncements = true;

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
              "Control who can see your activity and profile information within VaarthaHub community.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 30),

            /// MAIN VISIBILITY SWITCH
            _buildVisibilityCard(
              title: "Public Profile",
              subtitle: "Allow other users to find you and see your basic info in classifieds & community posts.",
              value: _isPublic,
              onChanged: (val) => setState(() => _isPublic = val),
              icon: Icons.language_rounded,
              activeColor: const Color(0xFFF9C55E),
            ),

            const SizedBox(height: 25),
            const Text(
              "DETAILED CONTROLS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 15),

            /// SUB CONTROLS (Only enabled if Profile is Public)
            Opacity(
              opacity: _isPublic ? 1.0 : 0.5,
              child: AbsorbPointer(
                absorbing: !_isPublic,
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: "Show My Announcements",
                      subtitle: "Display your birthday wishes or ads to others.",
                      value: _showAnnouncements,
                      onChanged: (val) => setState(() => _showAnnouncements = val),
                    ),
                    const Divider(height: 30, thickness: 0.5),
                    _buildSwitchTile(
                      title: "Show Reading History",
                      subtitle: "Let others see which newspapers you subscribe to.",
                      value: _showReadingHistory,
                      onChanged: (val) => setState(() => _showReadingHistory = val),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        "Profile Visibility",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  // --- Main Card Style for Visibility ---
  Widget _buildVisibilityCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFF2F5FE).withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F5FE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: activeColor, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                // ignore: deprecated_member_use
                activeColor: activeColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // --- Simple Switch Tile ---
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          // ignore: deprecated_member_use
          activeColor: const Color(0xFFF9C55E),
        ),
      ],
    );
  }
}