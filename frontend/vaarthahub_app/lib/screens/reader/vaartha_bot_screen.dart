import 'package:flutter/material.dart';

class VaarthaBotScreen extends StatelessWidget {
  const VaarthaBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9C55E), // Header color from design
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VaarthaBot',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildBotMessage("Hello! How can I help you today?"),
                _buildUserMessage("I want to know about scrap pickup."),
                _buildBotMessage("Sure! We collect old newspapers and plastic."),
                _buildUserMessage("What is the rate per kg?"),
                _buildBotMessage("Current rate for newspaper is ₹12/kg."),
                _buildUserMessage("Okay, thank you!"),
              ],
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  // Bot Message Widget
  Widget _buildBotMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot Avatar with Blue Border
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1C47C9), width: 2),
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/images/AI-Chatbot.png'),
            ),
          ),
          const SizedBox(width: 10),
          // Bot Speech Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4FF),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  // User Message Widget
  Widget _buildUserMessage(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Speech Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFFFBE1AE),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          // User Avatar
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/images/avatar.png'),
          ),
        ],
      ),
    );
  }

  // Bottom Input Field
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // ignore: deprecated_member_use
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'എന്നോട് ചോദിക്കൂ...', // Malayalam hint from design
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.send_rounded, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}