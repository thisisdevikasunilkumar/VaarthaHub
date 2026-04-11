import 'package:flutter/material.dart';

class LoggedInDevicesScreen extends StatefulWidget {
  const LoggedInDevicesScreen({super.key});

  @override
  State<LoggedInDevicesScreen> createState() => _LoggedInDevicesScreenState();
}

class _LoggedInDevicesScreenState extends State<LoggedInDevicesScreen> {
  // Dummy data for logged in devices
  final List<Map<String, String>> _devices = [
    {
      "device": "Samsung Galaxy S23 Ultra",
      "location": "Kochi, Kerala",
      "status": "Current Device",
      "lastActive": "Active Now"
    },
    {
      "device": "iPhone 15 Pro",
      "location": "Trivandrum, Kerala",
      "status": "Last Active",
      "lastActive": "2 hours ago"
    },
    {
      "device": "Windows PC - Chrome",
      "location": "Kozhikode, Kerala",
      "status": "Last Active",
      "lastActive": "Yesterday, 04:30 PM"
    },
  ];

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
              "You're currently logged in to your VaarthaHub account on these devices.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 30),

            /// --- DEVICE LIST ---
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _devices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final device = _devices[index];
                bool isCurrent = device['status'] == "Current Device";

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isCurrent 
                        // ignore: deprecated_member_use
                        ? const Color(0xFFFBD78F).withOpacity(0.15) 
                        // ignore: deprecated_member_use
                        : const Color(0xFFF2F5FE).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isCurrent ? const Color(0xFFF9C55E) : const Color(0xFFF2F5FE),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      /// Device Icon with Gold Background
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFFF9C55E) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          device['device']!.contains("PC") ? Icons.desktop_mac_rounded : Icons.smartphone_rounded,
                          color: isCurrent ? Colors.black87 : Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      /// Device Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device['device']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${device['location']} • ${device['lastActive']}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            if (isCurrent)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: const Color(0xFFF9C55E).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "THIS DEVICE",
                                  style: TextStyle(color: Color(0xFFC48E1D), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// Logout/Remove Action
                      if (!isCurrent)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                          onPressed: () {
                            // Logic to remove device
                          },
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            /// LOGOUT FROM ALL DEVICES BUTTON
            SizedBox(
              width: double.infinity,
              height: 58,
              child: OutlinedButton(
                onPressed: () {
                  // Logout all logic
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  "Logout from all other devices",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15),
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
        "Logged-in Devices",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}