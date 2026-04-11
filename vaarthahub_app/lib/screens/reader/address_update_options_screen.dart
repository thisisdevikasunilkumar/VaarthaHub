import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../reader/map_picker_screen.dart';
import '../reader/manual_address_form_screen.dart';

class AddressUpdateOptionsScreen extends StatelessWidget {
  // 1. Define readerCode variable
  final String readerCode;

  // 2. Add it to the constructor
  const AddressUpdateOptionsScreen({super.key, required this.readerCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Update Address", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choose how you want to update your address:", 
              style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),

            // Option 1: Map
            _buildOptionCard(
              context,
              title: "Locate on Map",
              subtitle: "Pin your exact location for better delivery",
              icon: Icons.map_rounded,
              color: Colors.blue.shade50,
              iconColor: Colors.blue,
              // Map picker-ilum readerCode venamenkil avideyum pass cheyyam
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen())),
            ),

            const SizedBox(height: 16),

            // Option 2: Manual Form
            _buildOptionCard(
              context,
              title: "Enter Manually",
              subtitle: "Type in your house name, ward, and details",
              icon: Icons.edit_note_rounded,
              color: Colors.orange.shade50,
              iconColor: Colors.orange,
              onTap: () => Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => ManualAddressFormScreen(readerCode: readerCode),
                ),
              ).then((value) {
                // ignore: use_build_context_synchronously
                if (value == true) Navigator.pop(context, true); // Success message with pop
              }),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }

  Widget _buildOptionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          // ignore: deprecated_member_use
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}