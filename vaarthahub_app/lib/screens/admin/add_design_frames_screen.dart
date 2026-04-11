import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/design_frame_model.dart'; 

class AddDesignFramesScreen extends StatefulWidget {
  const AddDesignFramesScreen({super.key});

  @override
  State<AddDesignFramesScreen> createState() => _AddDesignFramesScreenState();
}

class _AddDesignFramesScreenState extends State<AddDesignFramesScreen> {
  final TextEditingController _frameNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool isActive = true;
  bool _isSaving = false;
  bool _isLoadingTable = true;
  
  String? selectedCategory; 
  String? selectedCardType;
  File? _selectedImage;
  String? _existingImageUrl;
  int? _editingFrameId; 
  List<DesignFrameItem> _designFrames = [];

  String get _apiHost => ApiConstants.baseUrl.replaceFirst(RegExp(r'/api$'), '');

  @override
  void initState() {
    super.initState();
    _fetchDesignFrames();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _fetchDesignFrames() async {
    setState(() => _isLoadingTable = true);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/DesignFrames');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (!mounted) return;
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _designFrames = data
              .map((item) => DesignFrameItem.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      } else {
        _showFeedback('Unable to load design frames.', Colors.redAccent);
      }
    } catch (_) {
      _showFeedback('Connection error while loading frames.', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isLoadingTable = false);
      }
    }
  }

  Future<void> _deleteFrame(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Frame"),
        content: const Text("Are you sure you want to delete this frame?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/DesignFrames/$id'));
        if (response.statusCode == 200 || response.statusCode == 204) {
          _showFeedback("Frame deleted!", Colors.green);
          _fetchDesignFrames();
        } else {
          _showFeedback("Error deleting frame.", Colors.redAccent);
        }
      } catch (e) {
        _showFeedback("Connection error.", Colors.redAccent);
      }
    }
  }

  void _editFrame(DesignFrameItem frame) {
    setState(() {
      _editingFrameId = frame.frameId; 
      _frameNameController.text = frame.frameName;
      _priceController.text = frame.price.toString();
      selectedCategory = frame.category;
      selectedCardType = frame.cardType;
      isActive = frame.isActive;
      _selectedImage = null; 
      _existingImageUrl = frame.imagePath.startsWith('http') 
          ? frame.imagePath 
          : '$_apiHost${frame.imagePath}';
    });
    _showFeedback("Editing: ${frame.frameName}", Colors.blue);
  }

  Future<void> _toggleFrameStatus(DesignFrameItem frame, bool val) async {
    try {
      setState(() {
        frame.isActive = val;
      });
      final url = Uri.parse('${ApiConstants.baseUrl}/DesignFrames/toggle/${frame.frameId}');
      await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(val),
      );
      _showFeedback("Status updated", Colors.green);
    } catch (e) {
      _showFeedback("Failed to update status", Colors.redAccent);
    }
  }

  Future<void> _saveDesignFrame() async {
    if (_frameNameController.text.trim().isEmpty ||
        selectedCategory == null ||
        selectedCardType == null ||
        _priceController.text.trim().isEmpty) {
      _showFeedback('Please fill all fields.', Colors.orange);
      return;
    }

    if (_editingFrameId == null && _selectedImage == null) {
      _showFeedback('Please choose an image.', Colors.orange);
      return;
    }

    final double? parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null) {
      _showFeedback('Please enter a valid price.', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isUpdating = _editingFrameId != null;
      final url = isUpdating 
          ? Uri.parse('${ApiConstants.baseUrl}/DesignFrames/$_editingFrameId')
          : Uri.parse('${ApiConstants.baseUrl}/DesignFrames');

      final request = http.MultipartRequest(isUpdating ? 'PUT' : 'POST', url);

      request.fields['Category'] = selectedCategory!;
      request.fields['FrameName'] = _frameNameController.text.trim();
      request.fields['CardType'] = selectedCardType!;
      request.fields['Price'] = parsedPrice.toStringAsFixed(2);
      request.fields['IsActive'] = isActive.toString();
      
      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('Image', _selectedImage!.path),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        _showFeedback(isUpdating ? 'Updated successfully!' : 'Saved successfully!', Colors.green);
        _clearForm();
        await _fetchDesignFrames();
      } else {
        _showFeedback('Failed to save changes.', Colors.redAccent);
      }
    } catch (_) {
      if (!mounted) return;
      _showFeedback('Connection error while saving.', Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearForm() {
    setState(() {
      _editingFrameId = null;
      _frameNameController.clear();
      _priceController.clear();
      selectedCategory = null;
      selectedCardType = null;
      _selectedImage = null;
      _existingImageUrl = null;
      isActive = true;
    });
  }

  void _showFeedback(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  void dispose() {
    _frameNameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Category"),
                        _buildDropdown1(),                        
                        _buildLabel("Frame"),
                        _buildTextField("Enter frame name", controller: _frameNameController),
                        _buildLabel("CardType"),
                        _buildDropdown2(),
                        _buildLabel("Upload Frame Image"),
                        _buildImageUpload(),
                        _buildLabel("Price"),
                        _buildTextField(
                          "Enter Price",
                          controller: _priceController,
                          isNumber: true,
                        ),
                        if (_editingFrameId == null) ...[
                          const SizedBox(height: 15),
                          _buildActiveToggle(),
                        ],
                        const SizedBox(height: 25),
                        _buildSaveButton(),
                        const SizedBox(height: 30),
                        _buildDataTable(),
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Add Design Frames",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 15),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }

  Widget _buildTextField(String hint, {required TextEditingController controller, bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1E1FF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFF9C55E), width: 2)),
      ),
    );
  }

  Widget _buildDropdown1() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD1E1FF))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCategory,
          hint: const Text("Select Category", style: TextStyle(fontSize: 13, color: Colors.grey)),
          isExpanded: true,
          items: ["Remembrance", "Anniversary Greetings", "Birthday Wishes"].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (val) => setState(() => selectedCategory = val),
        ),
      ),
    );
  }

  Widget _buildDropdown2() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD1E1FF))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCardType,
          hint: const Text("Select CardType", style: TextStyle(fontSize: 13, color: Colors.grey)),
          isExpanded: true,
          items: ["Simple", "Medium", "Premium"].map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (val) => setState(() => selectedCardType = val),
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD1E1FF))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 40, height: 40,
                color: Colors.grey[200],
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.cover)
                    : (_existingImageUrl != null
                        ? Image.network(_existingImageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, size: 20))
                        : const Icon(Icons.add_a_photo, color: Colors.blue, size: 20)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                _selectedImage == null 
                    ? (_existingImageUrl != null ? "Change current image" : "Browse image file") 
                    : _selectedImage!.path.split(Platform.pathSeparator).last, 
                style: const TextStyle(color: Colors.grey, fontSize: 13), 
                overflow: TextOverflow.ellipsis
              )
            ),
            if (_selectedImage != null || _existingImageUrl != null) const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveToggle() {
    return Row(
      children: [
        const Text("IsActive", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Switch(
          value: isActive,
          onChanged: (val) => setState(() => isActive = val),
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFFF9C55E),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveDesignFrame,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF9C55E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
        child: _isSaving
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            : Text(_editingFrameId == null ? "Save Changes" : "Update Changes", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildDataTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saved Design Frames', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            width: 600,
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: const Color(0xFFE0E0E0))
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F4F9), 
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 1, child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 3, child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("Image", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 2, child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                      Expanded(flex: 3, child: Center(child: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
                    ],
                  ),
                ),
                
                _isLoadingTable
                ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
                : _designFrames.isEmpty
                ? const Padding(padding: EdgeInsets.all(24), child: Text("No Data Available", style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _designFrames.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final frame = _designFrames[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(flex: 1, child: Text(frame.frameId.toString(), style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text(frame.category, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 3, child: Text(frame.frameName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                            Expanded(flex: 2, child: Text(frame.cardType, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: _buildImageCell(frame.imagePath)),
                            Expanded(flex: 2, child: Text(frame.priceLabel, style: const TextStyle(fontSize: 11))),
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Transform.scale(
                                    scale: 0.6, 
                                    child: Switch(
                                      value: frame.isActive,
                                      activeTrackColor: const Color(0xFFF9C55E),
                                      onChanged: (val) => _toggleFrameStatus(frame, val),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert, size: 18),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editFrame(frame);
                                      } else if (value == 'delete') {
                                        _deleteFrame(frame.frameId);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: ListTile(
                                          leading: Icon(Icons.edit_outlined, size: 18),
                                          title: Text("Edit", style: TextStyle(fontSize: 12)),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          leading: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                          title: Text("Delete", style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageCell(String imagePath) {
    final String imageUrl = imagePath.startsWith('http') ? imagePath : '$_apiHost$imagePath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40, height: 40,
        color: const Color(0xFFF5F5F5),
        child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 15)),
      ),
    );
  }
}