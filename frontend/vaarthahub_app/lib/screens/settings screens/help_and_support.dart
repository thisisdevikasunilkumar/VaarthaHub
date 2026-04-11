import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// import '../reader/vaartha_bot_screen.dart'; 

class HelpAndSupport extends StatefulWidget {
  const HelpAndSupport({super.key});

  @override
  State<HelpAndSupport> createState() => _HelpAndSupportState();
}

class _HelpAndSupportState extends State<HelpAndSupport> {
  final Color primaryYellow = const Color(0xFFF9C55E);

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'vaarthahub@gmail.com',
      queryParameters: {
        'subject': 'Help & Support Request',
        'body': 'Hi Team,',
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Email app")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSupportHeader(),
          const SizedBox(height: 30),
          
          _sectionTitle("Quick Contact"),
          const SizedBox(height: 12),
          
          Row(
            children: [
              _contactButton(
                Icons.mail_outline_rounded, 
                "Email Us", 
                Colors.blue.shade400, 
                () => _sendEmail(),
              ),
              const SizedBox(width: 15),
              _contactButton(
                Icons.chat_bubble_outline_rounded, 
                "VaarthaBot",
                Colors.green.shade400, 
                () {
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const VaarthaBotScreen()));
                },
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          _sectionTitle("Frequently Asked Questions"),
          const SizedBox(height: 12),
          _buildFaqItem(
            "How to book a smart classified?",
            "Navigate to the 'Smart Classifieds' section, choose a template (like Birthday or Anniversary), upload a photo, and make the payment digitally."
          ),
          _buildFaqItem(
            "What is Smart Scrap & Recycle?",
            "It's a module where you can request a pickup for your old newspapers. We ensure they are recycled responsibly, promoting sustainability."
          ),
          
          const SizedBox(height: 40),
          const Center(
            child: Text("App Version 1.0.4", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
        "Help & Support",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSupportHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: primaryYellow.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.support_agent_rounded, size: 50, color: primaryYellow),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("How can we help you?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Our team and VaarthaBot are here to assist you.", style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));

  Widget _contactButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade100),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              // ignore: deprecated_member_use
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        title: Text(question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        iconColor: primaryYellow,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.black54, height: 1.5)),
          ),
        ],
      ),
    );
  }
}