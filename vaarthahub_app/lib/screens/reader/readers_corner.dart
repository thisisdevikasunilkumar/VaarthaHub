import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

class ReadersCornerScreen extends StatefulWidget {
  const ReadersCornerScreen({super.key});

  @override
  State<ReadersCornerScreen> createState() => _ReadersCornerScreenState();
}

class _ReadersCornerScreenState extends State<ReadersCornerScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _magazineScrollController = ScrollController();

  int selectedMagazineIndex = 0;
  File? _selectedImageFile;
  String? _selectedDocumentName;

  final List<Map<String, String>> magazines = [
    {'name': 'Vanitha', 'image': 'assets/categories/Vanitha logo.png'},
    {
      'name': 'Grihalakshmi',
      'image': 'assets/categories/Grihalakshmi logo.jpg',
    },
    {'name': 'Balarama', 'image': 'assets/categories/Balarama logo.png'},
    {'name': 'Balabhumi', 'image': 'assets/categories/Balabhumi logo.jpg'},
  ];

  @override
  void dispose() {
    _magazineScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImageFile = File(pickedImage.path);
      });
    } catch (_) {
      _showSnackBar('Unable to upload image right now.');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.isEmpty || !mounted) {
        return;
      }

      setState(() {
        _selectedDocumentName = result.files.single.name;
      });
    } catch (_) {
      _showSnackBar('Unable to upload document right now.');
    }
  }

  void _changeMagazine(int step) {
    if (magazines.isEmpty) {
      return;
    }

    final int nextIndex =
        (selectedMagazineIndex + step + magazines.length) % magazines.length;

    setState(() {
      selectedMagazineIndex = nextIndex;
    });

    const double itemExtent = 94;
    _magazineScrollController.animateTo(
      nextIndex * itemExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25),
                        _buildHeader(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Title'),
                                _buildTextField('Title (e.g., My New Poem)'),
                                const SizedBox(height: 18),
                                _buildLabel('Write your content here'),
                                _buildTextField(
                                  'Start writing...',
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Attach Media'),
                                Row(
                                  children: [
                                    _buildUploadBox(
                                      icon: Icons.camera_alt_outlined,
                                      text: 'Upload Image',
                                      onTap: _pickImage,
                                      preview: _selectedImageFile == null
                                          ? null
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                _selectedImageFile!,
                                                height: 34,
                                                width: 34,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                      fileName: _selectedImageFile?.path
                                          .split('\\')
                                          .last,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildUploadBox(
                                      icon: Icons.insert_drive_file_outlined,
                                      text: 'Upload Documents\n(PDF/Word)',
                                      onTap: _pickDocument,
                                      preview: const Icon(
                                        Icons.description_outlined,
                                        size: 28,
                                        color: Colors.black87,
                                      ),
                                      fileName: _selectedDocumentName,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildLabel('Select Magazine'),
                                const SizedBox(height: 8),
                                _buildMagazineSelector(),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF6C65B),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 20, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 5),
          const Text(
            "Reader's Corner",
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB8B8B8),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFC9D9FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF9AB8FF), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildUploadBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Widget? preview,
    String? fileName,
  }) {
    final bool hasSelection = fileName != null && fileName.isNotEmpty;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFEFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1DBFF)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              hasSelection
                  ? (preview ??
                        Icon(icon, size: 28, color: const Color(0xFF444444)))
                  : Icon(icon, size: 28, color: Colors.black87),
              const SizedBox(height: 6),
              Text(
                hasSelection ? fileName : text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: hasSelection ? 10.5 : 11.5,
                  height: 1.15,
                  color: hasSelection
                      ? const Color(0xFF5B5B5B)
                      : const Color(0xFF8B8B8B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagazineSelector() {
    return SizedBox(
      height: 108,
      child: Row(
        children: [
          InkWell(
            onTap: () => _changeMagazine(-1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.arrow_back_ios, size: 16, color: Colors.black),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _magazineScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: magazines.length,
              itemBuilder: (context, index) {
                final bool isSelected = selectedMagazineIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedMagazineIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 70,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF6C65B)
                            : const Color(0xFFE7E7E7),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Image.asset(
                            magazines[index]['image']!,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.menu_book,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          magazines[index]['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          InkWell(
            onTap: () => _changeMagazine(1),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
