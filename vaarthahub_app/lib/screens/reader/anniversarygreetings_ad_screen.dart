import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class AnniversaryGreetingsAdScreen extends StatefulWidget {
  const AnniversaryGreetingsAdScreen({super.key});

  @override
  State<AnniversaryGreetingsAdScreen> createState() =>
      _AnniversaryGreetingsAdScreenState();
}

class _AnniversaryGreetingsAdScreenState
    extends State<AnniversaryGreetingsAdScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<String> cardType = [];
  List<Map<String, dynamic>> designFrames = [];
  bool isLoading = true; // For fetching card types
  // ignore: prefer_final_fields, unused_field
  bool _isLoading = false; // For submission loading

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _selectedStyle;
  String? _selectedNewspaper;
  int _selectedDesignIndex = 0;

  // Drag and drop state for image mask
  double _maskX = 0.1;
  double _maskY = 0.28;
  double _maskSize = 0.3;

  final List<String> _newspapers = [
    'Malayala Manorama',
    'Mathrubhumi',
    'Deshabhimani',
  ];

  @override
  void initState() {
    super.initState();
    fetchCardTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Fetch Card Types using the ByCategory endpoint
  Future<void> fetchCardTypes() async {
    try {
      const String category = 'Anniversary Greetings';
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/DesignFrames/ByCategory/$category',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          designFrames = data
              .cast<Map<String, dynamic>>()
              .where((f) => f['isActive'] == true)
              .toList();

          if (designFrames.isNotEmpty) {
            cardType = designFrames
                .map((f) => f['cardType'].toString())
                .toSet()
                .toList();
            if (_selectedStyle == null && cardType.isNotEmpty) {
              _selectedStyle = cardType[0];
            }
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showFeedback("Error fetching frames: $e", Colors.redAccent);
      setState(() => isLoading = false);
    }
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Container(height: 120, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 35),
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewArea(),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Name',
                                'Enter name',
                                _nameController,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildDateField(
                                'Publication Date',
                                'DD-MM-YYYY',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPhotoUploadField()),
                            const SizedBox(width: 15),
                            Expanded(
                              child: isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _buildDropdownField(
                                      'Style',
                                      'Select Card Type',
                                      _selectedStyle,
                                      cardType,
                                      (val) {
                                        setState(() {
                                          _selectedStyle = val;
                                          int index = designFrames.indexWhere(
                                            (f) => f['cardType'] == val,
                                          );
                                          if (index != -1) {
                                            _selectedDesignIndex = index;
                                          }
                                        });
                                      },
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        _buildMessageField(),
                        const SizedBox(height: 20),

                        _buildDesignSection(),
                        const SizedBox(height: 25),

                        _buildDropdownField(
                          'Select Newspaper',
                          'Malayala Manorama',
                          _selectedNewspaper,
                          _newspapers,
                          (val) {
                            setState(() => _selectedNewspaper = val);
                          },
                        ),
                        const SizedBox(height: 30),

                        _buildNextButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 5),
          const Text(
            "Anniversary Greetings Ad",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 1),
          ),
          child: Center(
            // Check if designs are available or still loading
            child: designFrames.isEmpty && !isLoading
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "No designs available",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : _buildAdCardPreview(showText: false, isInteractive: true),
          ),
        ),
        if (_selectedImage != null && designFrames.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tip: Drag the photo above to align it in the frame.",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "Photo Size:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _maskSize,
                        min: 0.1,
                        max: 0.8,
                        onChanged: (val) {
                          setState(() {
                            _maskSize = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAdCardPreview({
    required bool showText,
    bool isInteractive = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child:
              designFrames.isNotEmpty &&
                  _selectedDesignIndex < designFrames.length
              ? Image.network(
                  ApiConstants.baseUrl.replaceAll('/api', '') +
                      designFrames[_selectedDesignIndex]['imagePath'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        ),

        if (_selectedImage != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      left: constraints.maxWidth * _maskX,
                      top: constraints.maxHeight * _maskY,
                      width: constraints.maxWidth * _maskSize,
                      height: constraints.maxWidth * _maskSize * 1.3,
                      child: ClipOval(
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (showText)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      left: constraints.maxWidth * 0.42,
                      top: constraints.maxHeight * 0.15,
                      right: constraints.maxWidth * 0.05,
                      bottom: constraints.maxHeight * 0.15,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _nameController.text.isNotEmpty
                                ? "Happy Anniversary\n${_nameController.text}"
                                : "Happy Anniversary\n[Name]",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: 'serif',
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _dateController.text.isNotEmpty
                                ? _dateController.text
                                : "DD-MM-YYYY",
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _messageController.text.isNotEmpty
                                    ? _messageController.text
                                    : "Wishing you a lifetime of love and happiness together.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        if (isInteractive && _selectedImage != null)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      _maskX += details.delta.dx / constraints.maxWidth;
                      _maskY += details.delta.dy / constraints.maxHeight;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _dateController,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            suffixIcon: const Icon(
              Icons.calendar_month,
              color: Color(0xFF4A65FF),
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
            );
            if (image != null) {
              setState(() {
                _selectedImage = File(image.path);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFB4C2FF), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFF4A65FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedImage != null
                        ? _selectedImage!.path.split('/').last
                        : 'Upload photo',
                    style: TextStyle(
                      color: _selectedImage != null
                          ? Colors.black
                          : Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '* Portrait image recommended',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String hint,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'e.g., Wishing you a lifetime of love and happiness...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFB4C2FF), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Design',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.arrow_back_ios, size: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: designFrames.isNotEmpty
                      ? designFrames.asMap().entries.map((entry) {
                          int index = entry.key;
                          var frame = entry.value;
                          String imgUrl =
                              ApiConstants.baseUrl.replaceAll('/api', '') +
                              frame['imagePath'];
                          return _buildDesignOption(
                            index,
                            frame['cardType'] ?? 'Design',
                            imgUrl,
                            isNetwork: true,
                          );
                        }).toList()
                      : isLoading
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ]
                      : [
                          const Text(
                            "No designs available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ],
    );
  }

  Widget _buildDesignOption(
    int index,
    String label,
    String imgPath, {
    bool isNetwork = false,
  }) {
    bool isSelected = _selectedDesignIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDesignIndex = index;
          _selectedStyle = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 90,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF3C05C)
                      : const Color(0xFFB4C2FF),
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(5),
              child: isNetwork
                  ? Image.network(
                      imgPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Colors.grey),
                    )
                  : Image.asset(imgPath, fit: BoxFit.contain),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3C05C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () {
          _showPreviewDialog();
        },
        child: const Text(
          'Next',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Ad Preview (${_selectedNewspaper ?? "Newspaper"})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                  color: Colors.white,
                ),
                child: _buildAdCardPreview(
                  showText: true,
                  isInteractive: false,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3C05C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    try {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final String timestamp = DateTime.now()
                          .millisecondsSinceEpoch
                          .toString();
                      final File file = File(
                        '${directory.path}/Anniversary_Ad_$timestamp.doc',
                      );

                      String content =
                          '<html><body><h2>Anniversary Ad</h2><p><b>Name:</b> ${_nameController.text}</p></body></html>';
                      await file.writeAsString(content);

                      if (context.mounted) {
                        Navigator.pop(context);
                        _showFeedback("Saved: ${file.path}", Colors.green);
                      }
                    } catch (e) {
                      _showFeedback("Failed to save: $e", Colors.redAccent);
                    }
                  },
                  child: const Text(
                    'Confirm & Proceed',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
