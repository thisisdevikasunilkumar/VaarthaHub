import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DeliveryRoutePreview extends StatelessWidget {
  final Map<String, dynamic>? partnerData;
  final int readerCount;
  final int vacationReaderCount;

  const DeliveryRoutePreview({
    super.key,
    this.partnerData,
    this.readerCount = 0,
    this.vacationReaderCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final activeStops = readerCount - vacationReaderCount;
    final panchayat = (partnerData?['panchayatName'] ?? 'Assigned Panchayat')
        .toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 160, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Route Management",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$panchayat delivery loop for today",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF172033),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "AI Route Optimization",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Shortest and most efficient route suggested for the morning schedule.",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        const RouteProgressLine(),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _routeOverviewTile(
                                "Active Stops",
                                "$activeStops",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _routeOverviewTile(
                                "Vacation",
                                "$vacationReaderCount",
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _routeOverviewTile(
                                "Distance",
                                activeStops > 0 ? "4.8 km" : "0 km",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...[
                    _routeStop("Depot Start", "05:45 AM", true),
                    _routeStop("Central lane drops", "06:05 AM", false),
                    _routeStop("School road readers", "06:25 AM", false),
                    _routeStop("Market side finish", "06:45 AM", true),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _routeOverviewTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeStop(String title, String time, bool highlight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFFF4D8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F4F7)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: highlight ? Colors.white : const Color(0xFFF5F7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              highlight ? Icons.flag_outlined : Icons.location_on_outlined,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Expected checkpoint",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class RouteProgressLine extends StatelessWidget {
  const RouteProgressLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _routeNode(true),
        _routeBar(),
        _routeNode(false),
        _routeBar(),
        _routeNode(false),
        _routeBar(),
        _routeNode(true),
      ],
    );
  }

  Widget _routeNode(bool filled) {
    return Container(
      height: 16,
      width: 16,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFF9C55E) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? const Color(0xFFF9C55E) : Colors.white70,
          width: 2,
        ),
      ),
    );
  }

  Widget _routeBar() {
    return Expanded(
      child: Container(
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9C55E),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
