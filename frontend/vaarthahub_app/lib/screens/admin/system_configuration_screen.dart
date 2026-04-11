import 'package:flutter/material.dart';

class SystemConfigurationScreen extends StatefulWidget {
  const SystemConfigurationScreen({super.key});

  @override
  State<SystemConfigurationScreen> createState() => _SystemConfigurationScreenState();
}

class _SystemConfigurationScreenState extends State<SystemConfigurationScreen> {
  bool isMaintenanceMode = false;
  bool isOtpEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "App Version Control",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildConfigTile(
              title: "Current Version",
              value: "1.0.4",
              icon: Icons.vibration,
              onTap: () {},
            ),
            _buildConfigTile(
              title: "Force Update",
              value: "Disabled",
              icon: Icons.system_update,
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            const Text(
              "Security & Services",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            _buildSwitchTile(
              title: "OTP Verification",
              subtitle: "Enable/Disable OTP for login & registration",
              value: isOtpEnabled,
              onChanged: (val) => setState(() => isOtpEnabled = val),
            ),
            
            _buildSwitchTile(
              title: "Maintenance Mode",
              subtitle: "Show maintenance screen for all users",
              value: isMaintenanceMode,
              onChanged: (val) => setState(() => isMaintenanceMode = val),
            ),

            const SizedBox(height: 32),
            const Text(
              "External Services",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            _buildConfigTile(
              title: "Email Service (SMTP)",
              value: "Connected",
              icon: Icons.alternate_email_rounded,
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              onTap: () {},
            ),
            _buildConfigTile(
              title: "Maps & Route API",
              value: "Active",
              icon: Icons.map_outlined,
              trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
              onTap: () {},
            ),

            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Configurations Updated Successfully")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar with back button and title
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
        "System Configuration",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildConfigTile({
    required String title, 
    required String value, 
    required IconData icon, 
    Widget? trailing,
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFFF9C55E)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: trailing ?? Text(value, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title, 
    required String subtitle, 
    required bool value, 
    required Function(bool) onChanged
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        activeThumbColor: const Color(0xFFF9C55E),
        onChanged: onChanged,
      ),
    );
  }
}