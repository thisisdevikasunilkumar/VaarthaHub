import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../settings screens/change_password_screen.dart';
import '../settings screens/profile_visibility_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  // bool _faceIdEnabled = true;
  bool _dataSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- SECURITY SECTION ---
            const Text(
              "SECURITY SETTINGS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.lock_outline_rounded,
              title: "Change Password",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),);
              },
            ),
            // _buildSwitchTile(
            //   icon: Icons.fingerprint_rounded,
            //   title: "Biometric / Face ID",
            //   value: _faceIdEnabled,
            //   onChanged: (val) => setState(() => _faceIdEnabled = val),
            // ),
            // _buildActionTile(
            //   icon: Icons.devices_rounded,
            //   title: "Logged-in Devices",
            //   onTap: () {},
            // ),

            const SizedBox(height: 32),

            /// --- PRIVACY SECTION ---
            const Text(
              "PRIVACY",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 16),

            _buildSwitchTile(
              icon: Icons.analytics_outlined,
              title: "Share Usage Data",
              value: _dataSharing,
              onChanged: (val) => setState(() => _dataSharing = val),
            ),
            _buildActionTile(
              icon: Icons.visibility_off_outlined,
              title: "Profile Visibility",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileVisibilityScreen()),
                );
              },
            ),
            const SizedBox(height: 32),

            /// --- DANGER ZONE ---
            const Text(
              "ACCOUNT ACTIONS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.delete_forever_outlined,
              title: "Delete Account",
              titleColor: Colors.red,
              iconColor: Colors.red,
              onTap: () => _showDeleteAccountDialog(context),
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
        "Privacy & Security",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  /// Helper for Normal Action Tiles
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        // ignore: deprecated_member_use
        decoration: BoxDecoration(color: (iconColor ?? Colors.blue).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor ?? Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  /// Helper for Switch Tiles
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        // ignore: deprecated_member_use
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.orange, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        // ignore: deprecated_member_use
        activeColor: Color(0xFFF9C55E),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This action cannot be undone. All your subscription history will be removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {},
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}