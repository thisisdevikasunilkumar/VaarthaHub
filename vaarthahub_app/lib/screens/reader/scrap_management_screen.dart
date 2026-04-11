import 'package:flutter/material.dart';

import '../reader/pickup_date_selection_screen.dart';

class ScrapManagementScreen extends StatefulWidget {
  const ScrapManagementScreen({super.key});

  @override
  State<ScrapManagementScreen> createState() => _ScrapManagementScreenState();
}

class _ScrapManagementScreenState extends State<ScrapManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section with Image and Title
                  Stack(
                    children: [
                      Image.asset(
                        'assets/ui_elements/element5.png',
                        width: double.infinity,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          // ignore: deprecated_member_use
                          color: const Color(0xFFFDEBB7).withOpacity(0.5),
                        ),
                      ),
                      // Title and Subtitle positioned over the image
                      Positioned(
                        top: 75,
                        left: 20,
                        right: 20,
                        child:
                            _buildHeader(), // Ivide ippo oru widget mathrame ulloo
                      ),
                    ],
                  ),

                  // Content area that overlaps the image
                  Transform.translate(
                    offset: const Offset(0, -105), // Pulls the cards upward
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildCurrentStatusCard(), // Ippo card image-inte molaekk overlap aayi varum
                          const SizedBox(height: 25),
                          _buildInfoRow(),
                          const SizedBox(height: 25),
                          _buildRequestPickupCard(),
                          const SizedBox(height: 30),
                          _buildPickupHistorySection(),
                          const SizedBox(height: 30),
                          _buildTotalImpactCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Header update for better visibility over image
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Scrap Management",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          "Track, recycle, and earn from your newspaper scrap",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildCurrentStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCE6D)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.eco_sharp, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                "Current Scrap Status",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: const [
              Text(
                "1.2",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 5),
              Text("Kg", style: TextStyle(color: Colors.grey)),
            ],
          ),
          const Text(
            "Estimated Weight (AI Prediction)",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Progress",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                "60%",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 8,
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFCE6D)),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "0.8 kg more needed for pickup",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(child: _buildSmallInfoCard("Estimated Value", "₹18")),
        const SizedBox(width: 15),
        Expanded(child: _buildSmallInfoCard("Next Pickup In", "3 days")),
      ],
    );
  }

  Widget _buildSmallInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCE6D)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestPickupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCE6D)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Request Scrap Pickup",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            "Schedule a pickup when you're ready. Our delivery partner will collect and weigh your scrap.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildInputTile(
            Icons.location_on_outlined,
            "Pickup Location",
            "House No. 42, Kottayam Panchayat",
          ),
          const SizedBox(height: 12),
          _buildInputTile(
            Icons.calendar_today_outlined,
            "Preferred Date",
            "Select your convenient date",
            trailing: "Choose",
          ),
          const SizedBox(height: 12),
          _buildInputTile(
            Icons.currency_rupee_rounded,
            "Current Rate",
            "₹15 per kg (Market Rate)",
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Pickup Selection Screen-lekk pokunnu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PickupDateSelectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFCE6D),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Schedule Pickup",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTile(
    IconData icon,
    String title,
    String subtitle, {
    String? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFCE6D)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: const TextStyle(
                color: Color(0xFFFFCE6D),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPickupHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pickup History",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildHistoryCard(
          "January Collection",
          "Jan 12, 2026",
          "3.5",
          "52",
          "15",
        ),
        const SizedBox(height: 15),
        _buildHistoryCard(
          "December Collection",
          "Dec 12, 2025",
          "3.5",
          "52",
          "15",
        ),
        const SizedBox(height: 15),
        _buildHistoryCard(
          "November Collection",
          "Nov 12, 2025",
          "3.5",
          "52",
          "15",
        ),
      ],
    );
  }

  Widget _buildHistoryCard(
    String title,
    String date,
    String weight,
    String earned,
    String rate,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        border: Border.all(color: const Color(0xFFFFCE6D).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.recycling,
                      color: Color(0xFFFFCE6D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  "Completed",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildHistoryStat("$weight kg", "Weight")),
              const SizedBox(width: 10),
              Expanded(child: _buildHistoryStat("₹ $earned", "Earned")),
              const SizedBox(width: 10),
              Expanded(child: _buildHistoryStat("₹ $rate", "Rate/kg")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildTotalImpactCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFCE6D)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Total Impact",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildImpactStat(
                Icons.park_rounded,
                Colors.green,
                "3.5",
                "Trees Saved",
              ),
              _buildImpactStat(
                Icons.currency_rupee_rounded,
                Colors.green,
                "₹ 187",
                "Total Earned",
              ),
              _buildImpactStat(
                Icons.recycling_rounded,
                Colors.brown,
                "12.7 kg",
                "Total Recycled",
              ),
              _buildImpactStat(
                Icons.emoji_events_rounded,
                Colors.orange,
                "Gold",
                "Eco Badge",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(
    IconData icon,
    Color iconColor,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
