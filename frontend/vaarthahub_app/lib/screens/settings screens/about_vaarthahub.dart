// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AboutVaarthaHub extends StatelessWidget {
  const AboutVaarthaHub({super.key});

  final Color primaryYellow = const Color(0xFFF9C55E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // App Logo Section
              Column(
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/logo/vaarthaHub-resolution-logo.png',
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.hub_rounded, size: 80, color: primaryYellow);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Version 1.0.4",
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: primaryYellow,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Info Sections with icons
              _buildInfoSection(
                title: "Our Mission",
                description: "To bridge the gap between local distributors and readers through a smart, transparent, and efficient digital ecosystem.",
                icon: Icons.auto_awesome,
              ),

              _buildInfoSection(
                title: "Smart Features",
                description: "VaarthaHub isn't just a news app. We integrate predictive analytics for demand forecasting and route optimization to ensure timely delivery.",
                icon: Icons.psychology,
              ),

              _buildInfoSection(
                title: "Sustainability",
                description: "Our 'Smart Scrap & Recycle' module helps the community manage newspaper waste responsibly, promoting a greener tomorrow.",
                icon: Icons.recycling,
              ),

              const SizedBox(height: 20),
              const Divider(height: 40),
              const SizedBox(height: 10),

              // Contact Section with a card design
              _buildContactCard(),
              
              const SizedBox(height: 40),
              const Text(
                "Made with ❤️ in Kerala",
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
        "About VaarthaHub",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String description, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: primaryYellow.withOpacity(0.15), // Light yellow background
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: primaryYellow, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryYellow, // Full Yellow card
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: primaryYellow.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Have questions?",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "We'd love to hear from you.",
            style: TextStyle(color: Colors.black87, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.email_outlined, color: Colors.black),
            label: const Text(
              "vaarthahub@gmail.com",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }
}