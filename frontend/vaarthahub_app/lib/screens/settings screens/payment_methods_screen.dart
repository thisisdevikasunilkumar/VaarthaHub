import 'package:flutter/material.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
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
            /// --- CARDS SECTION ---
            const Text(
              "CREDIT / DEBIT / ATM CARDS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 15),
            _buildCardItem(
              bankName: "HDFC Bank",
              cardNumber: "**** 4242",
              type: "Visa",
              color: const Color(0xFF1A237E), // Dark Blue
            ),
            const SizedBox(height: 12),
            _buildAddButton("Add New Card", Icons.add_card_rounded),

            const SizedBox(height: 35),

            /// --- UPI APPS SECTION ---
            const Text(
              "UPI APPS",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 15),
            _buildUPIAppTile("Google Pay", "user@okaxis", Icons.account_balance_wallet), // Logo path pinneed add cheyyaam
            _buildUPIAppTile("PhonePe", "user@ybl", Icons.account_balance_wallet),
            _buildUPIAppTile("Paytm", "9876543210@paytm", Icons.account_balance_wallet),
            const SizedBox(height: 12),
            _buildAddButton("Link New UPI ID", Icons.add_link_rounded),

            const SizedBox(height: 35),

            /// --- NET BANKING & OTHERS ---
            const Text(
              "NET BANKING",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
            ),
            const SizedBox(height: 15),
            _buildSimpleTile("State Bank of India", Icons.account_balance_rounded),
            _buildSimpleTile("Federal Bank", Icons.account_balance_rounded),
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
        "Payment Methods",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }


  // --- Card UI Item ---
  Widget _buildCardItem({required String bankName, required String cardNumber, required String type, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bankName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(cardNumber, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          const SizedBox(width: 10),
          const Icon(Icons.more_vert_rounded, color: Colors.white),
        ],
      ),
    );
  }

  // --- UPI App Tile with Logo Space ---
  Widget _buildUPIAppTile(String name, String upiId, IconData placeholderIcon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFF2F5FE).withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F5FE)),
      ),
      child: Row(
        children: [
          // Ivide Image.asset upayogichu logo vekkaam
          Container(
            padding: const EdgeInsets.all(8),
            // ignore: deprecated_member_use
            decoration: BoxDecoration(color: const Color(0xFFF9C55E).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(placeholderIcon, color: const Color(0xFFF9C55E), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(upiId, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  // --- Simple Banking Tile ---
  Widget _buildSimpleTile(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // --- Add New Style Button ---
  Widget _buildAddButton(String text, IconData icon) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF9C55E), width: 1.2),
          borderRadius: BorderRadius.circular(20),
          // ignore: deprecated_member_use
          color: const Color(0xFFF9C55E).withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFF9C55E), size: 20),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(color: Color(0xFFF9C55E), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}