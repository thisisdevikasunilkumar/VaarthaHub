import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/api_service.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class VaarthaBotScreen extends StatefulWidget {
  const VaarthaBotScreen({super.key});

  @override
  State<VaarthaBotScreen> createState() => _VaarthaBotScreenState();
}

class _VaarthaBotScreenState extends State<VaarthaBotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _typingPlayer = AudioPlayer();
  final List<Message> _messages = [];
  bool _isTyping = false;
  int? _readerId;

  @override
  void initState() {
    super.initState();
    _loadReaderData();
    _preLoadTypingSound();
    _messages.add(Message(
      text: "ഹലോ! ഞാൻ വാർത്താബോട്ട്. ബില്ല്, ബാലൻസ്, സബ്സ്ക്രിപ്ഷൻ വിവരങ്ങൾ എന്നിവയെക്കുറിച്ച് എന്നോട് ചോദിക്കാം. (Hello! I'm VaarthaBot. You can ask me about bills, balance, or subscription details.)",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _preLoadTypingSound() async {
    try {
      await _typingPlayer.setSource(UrlSource('https://raw.githubusercontent.com/Ansh-Rathod/Chatter/master/app/src/main/res/raw/audio_typing.mp3'));
      await _typingPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint("Error pre-loading typing sound: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _typingPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReaderData() async {
    final prefs = await SharedPreferences.getInstance();
    final readerCode = prefs.getString('readerCode') ?? '1';
    
    try {
      final response = await http.get(Uri.parse("${ApiConstants.baseUrl}/Reader/GetReaderProfile/$readerCode"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _readerId = data['readerId'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading reader data: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _playSentSound() async {
    try {
      // General vibration
      HapticFeedback.vibrate();
      
      // Stop and reset to ensure it plays every time
      await _audioPlayer.stop();
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      
      // WhatsApp-like "Sent" sound
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    if (_readerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User data not loaded yet. Please wait.")),
      );
      return;
    }

    final userText = _controller.text.trim();
    _controller.clear();

    // Trigger sound and vibration
    _playSentSound();

    setState(() {
      _messages.add(Message(text: userText, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    // Start typing sound - Using pre-loaded source to avoid network errors
    try {
      if (_typingPlayer.source != null) {
        await _typingPlayer.resume();
      } else {
        await _typingPlayer.play(UrlSource('https://raw.githubusercontent.com/Ansh-Rathod/Chatter/master/app/src/main/res/raw/audio_typing.mp3'));
      }
    } catch (e) {
      debugPrint("Error starting typing sound: $e");
    }

    // Start fetching response from API and also start a 5-second delay
    try {
      final apiRequest = http.post(
        Uri.parse("${ApiConstants.baseUrl}/ChatBot/Query"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "readerId": _readerId,
          "query": userText,
        }),
      );

      // Wait for both the API response and at least 5 seconds of "typing" animation
      final results = await Future.wait([
        apiRequest,
        Future.delayed(const Duration(seconds: 5)),
      ]);

      // Stop typing sound
      await _typingPlayer.stop();

      final http.Response response = results[0] as http.Response;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _messages.add(Message(
              text: data['response'],
              isUser: false,
              timestamp: DateTime.now(),
            ));
            _isTyping = false;
          });
        }
      } else {
        throw Exception("Failed to get response");
      }
    } catch (e) {
      // Stop typing sound on error too
      await _typingPlayer.stop();
      
      // Still wait for a short delay even if there's an error, for design consistency
      await Future.delayed(const Duration(seconds: 1)); 

      if (mounted) {
        setState(() {
          _messages.add(Message(
            text: "ക്ഷമിക്കണം, എനിക്ക് ഇപ്പോൾ കണക്ട് ചെയ്യാൻ കഴിയില്ല. (Sorry, I can't connect right now.)",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
      }
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9C55E), // Header color from your design
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VaarthaBot',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
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
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return (msg.isUser ? _buildUserMessage(msg.text) : _buildBotMessage(msg.text))
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  // Bot Message Widget - From your 1st Design
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

  // User Message Widget - From your 1st Design
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

  // Bottom Input Field - Modified from your 1st Design to be functional
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
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'എന്നോട് ചോദിക്കൂ...', // Malayalam hint from your design
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
     return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4FF),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                _dot(1),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayInMs) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        color: Colors.black45,
        shape: BoxShape.circle,
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .scale(
      duration: 600.ms,
      delay: (delayInMs * 200).ms,
      curve: Curves.easeInOut,
      begin: const Offset(1, 1),
      end: const Offset(1.5, 1.5),
    )
    .then()
    .scale(duration: 600.ms, begin: const Offset(1.5, 1.5), end: const Offset(1, 1));
  }
}
