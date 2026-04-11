import 'package:flutter/material.dart';

class LanguagePreferenceScreen extends StatefulWidget {
  const LanguagePreferenceScreen({super.key});

  @override
  State<LanguagePreferenceScreen> createState() => _LanguagePreferenceScreenState();
}

class _LanguagePreferenceScreenState extends State<LanguagePreferenceScreen> {
  // Default aayi Malayalam select cheythu vekkaam
  String _selectedLanguage = "Malayalam";

  final List<Map<String, String>> _languages = [
    {"name": "Malayalam", "sub": "മലയാളം"},
    {"name": "English", "sub": "English"},
    {"name": "Hindi", "sub": "हिन्दी"},
    {"name": "Tamil", "sub": "தமிழ்"},
    {"name": "Kannada", "sub": "ಕನ್ನಡ"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                bool isSelected = _selectedLanguage == lang['name'];

                return GestureDetector(
                  onTap: () => setState(() => _selectedLanguage = lang['name']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: isSelected ? const Color(0xFFF9C55E).withOpacity(0.05) : const Color(0xFFF2F5FE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFF9C55E) : const Color(0xFFF2F5FE),
                        width: isSelected ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang['name']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lang['sub']!,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFFF9C55E), size: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          /// SAVE BUTTON
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: () {
                  // Save Language Logic
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text(
                  "Save Preference",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
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
        "Language Preference",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
    );
  }
}