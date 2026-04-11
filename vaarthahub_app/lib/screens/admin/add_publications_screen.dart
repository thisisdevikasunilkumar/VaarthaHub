import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/newspaper.dart';

import 'package:vaarthahub_app/models/magazine.dart';

class AddPublicationsScreen extends StatefulWidget {
  final Newspaper? editNewspaper;
  final Magazine? editMagazine;
  final bool? initialIsNewspaper;

  const AddPublicationsScreen({
    super.key,
    this.editNewspaper,
    this.editMagazine,
    this.initialIsNewspaper,
  });

  @override
  State<AddPublicationsScreen> createState() => _AddPublicationsScreenState();
}

class _AddPublicationsScreenState extends State<AddPublicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isNewspaper = true;
  bool isActive = true;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Selected values for dropdowns
  String? selectedCategory;
  String? selectedSubtype;

  int? selectedNewspaperId;
  List<Newspaper> _newspapers = [];
  bool _isLoadingNewspapers = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.editNewspaper != null) {
      isNewspaper = true;
      _tabController.index = 0;
      _nameController.text = widget.editNewspaper!.name;
      selectedCategory = widget.editNewspaper!.category;
      selectedSubtype = widget.editNewspaper!.paperType;
      _priceController.text = widget.editNewspaper!.basePrice.toString();
      isActive = widget.editNewspaper!.isActive;
    } else if (widget.editMagazine != null) {
      isNewspaper = false;
      _tabController.index = 1;
      _nameController.text = widget.editMagazine!.name;
      selectedCategory = widget.editMagazine!.category;
      selectedSubtype = widget.editMagazine!.publicationCycle;
      _priceController.text = widget.editMagazine!.price.toString();
      selectedNewspaperId = widget.editMagazine!.newspaperId;
      isActive = widget.editMagazine!.isActive;
    } else if (widget.initialIsNewspaper != null) {
      isNewspaper = widget.initialIsNewspaper!;
      _tabController.index = isNewspaper ? 0 : 1;
    }
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        bool isEditing = widget.editNewspaper != null || widget.editMagazine != null;
        if (isEditing) {
          // Revert tab if editing
          _tabController.index = isNewspaper ? 0 : 1;
          return;
        }
        setState(() {
          isNewspaper = _tabController.index == 0;
          selectedCategory = null;
          selectedSubtype = null;
        });
      }
    });
    _fetchNewspapers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewspapers() async {
    setState(() => _isLoadingNewspapers = true);
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetNewspapers',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _newspapers = (jsonDecode(response.body) as List)
                .map((i) => Newspaper.fromJson(i))
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching newspapers: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNewspapers = false);
    }
  }

  // Lists for dropdowns
  final List<String> newspaperCategories = [
    "Community",
    "Education",
    "English",
    "Evening Dailies",
    "General",
    "Political",
    "Specials",
  ];
  final List<String> paperTypes = [
    "Morning Daily",
    "Evening Daily",
    "Weekly",
    "Sunday Special",
  ];

  final List<String> magazineCategories = [
    "Automobile",
    "Career",
    "Children",
    "Education",
    "English",
    "Family",
    "Farming",
    "Finance",
    "Food",
    "General Knowledge",
    "Health",
    "Lifestyle",
    "Literary",
    "Sports",
    "Travel",
    "Weekly",
    "Women",
  ];

  final List<String> publicationTypes = ["Fortnightly", "Monthly", "Weekly"];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFF9C55E)),
        borderRadius: BorderRadius.circular(10),
      ),
    );
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
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildAppBar(),
                const SizedBox(height: 20),
                _buildToggleTabs(),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: (widget.editNewspaper != null || widget.editMagazine != null)
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    children: [
                      // Newspaper Form
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: _buildForm(true),
                      ),
                      // Magazine Form
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                        child: _buildForm(false),
                      ),
                    ],
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool newspaperMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Item Type"),
        _buildItemTypeDropdown(),
        if (!newspaperMode) ...[
          _buildLabel("Parent Newspaper"),
          _buildParentNewspaperDropdown(),
        ],
        _buildLabel("Name"),
        _buildImageTextField(
          newspaperMode ? "Enter Newspaper Name" : "Enter Magazine Name",
          Icons.camera_alt_outlined,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Category"),
                  _buildCategoryDropdown(newspaperMode),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(newspaperMode ? "Paper Type" : "Publication"),
                  _buildSubtypeDropdown(newspaperMode),
                ],
              ),
            ),
          ],
        ),
        _buildLabel(newspaperMode ? "Base Price" : "Unit Price"),
        _buildPriceField("Enter Price"),
        const SizedBox(height: 20),
        _buildStatusSwitch(),
        const SizedBox(height: 30),
        _buildSubmitButton(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildItemTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: isNewspaper ? "Newspaper" : "Magazine",
          isExpanded: true,
          hint: const Text(
            "Select Item Type",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          items: ["Newspaper", "Magazine"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged:
              (widget.editNewspaper != null || widget.editMagazine != null)
              ? null
              : (val) {
                  setState(() {
                    bool newVal = (val == "Newspaper");
                    if (newVal != isNewspaper) {
                      isNewspaper = newVal;
                      _tabController.animateTo(isNewspaper ? 0 : 1);
                      selectedCategory = null;
                      selectedSubtype = null;
                    }
                  });
                },
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Row(
      children: [
        const Text(
          "IsActive",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 10),
        Switch(
          value: isActive,
          activeThumbColor: const Color(0xFFFFC154),
          onChanged: (value) => setState(() => isActive = value),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Add Publications",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTabs() {
    bool isEditing =
        widget.editNewspaper != null || widget.editMagazine != null;
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEABF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: AbsorbPointer(
        absorbing: isEditing,
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color(0xFFF9C55E),
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Newspapers"),
            Tab(text: "Magazines"),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }


  Widget _buildCategoryDropdown(bool isNewspaperMode) {
    List<String> currentList = isNewspaperMode
        ? newspaperCategories
        : magazineCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentList.contains(selectedCategory)) ? selectedCategory : null,
          isExpanded: true,
          hint: const Text(
            "Select Category",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          items: currentList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedCategory = val),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildSubtypeDropdown(bool isNewspaperMode) {
    List<String> currentList = isNewspaperMode ? paperTypes : publicationTypes;
    String hintText = isNewspaperMode ? "Select Paper Type" : "Select Publication";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (currentList.contains(selectedSubtype)) ? selectedSubtype : null,
          isExpanded: true,
          hint: Text(
            hintText,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          items: currentList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedSubtype = val),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildParentNewspaperDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: (_newspapers.any((n) => n.newspaperId == selectedNewspaperId))
              ? selectedNewspaperId
              : null,
          isExpanded: true,
          hint: _isLoadingNewspapers
              ? const Text(
                  "Loading newspapers...",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              : const Text(
                  "Select Newspaper",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
          items: _newspapers.map<DropdownMenuItem<int>>((Newspaper newspaper) {
            return DropdownMenuItem<int>(
              value: newspaper.newspaperId,
              child: Text(
                newspaper.name,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => selectedNewspaperId = val),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildImageTextField(String hint, IconData icon) {
    bool hasExistingLogo =
        (widget.editNewspaper?.logoUrl != null &&
            widget.editNewspaper!.logoUrl!.isNotEmpty) ||
        (widget.editMagazine?.logoUrl != null &&
            widget.editMagazine!.logoUrl!.isNotEmpty);
    String existingBase64 =
        widget.editNewspaper?.logoUrl ?? widget.editMagazine?.logoUrl ?? '';

    Widget? suffixWidget;
    if (_selectedImage != null) {
      suffixWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.file(
            _selectedImage!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (hasExistingLogo) {
      suffixWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.memory(
            base64Decode(existingBase64),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: _inputDecoration(
            hint,
            prefixIcon: GestureDetector(
              onTap: _pickImage,
              child: _buildPrefixIcon(icon),
            ),
            suffixIcon: suffixWidget,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFF4A69FF)),
            const SizedBox(width: 5),
            Text(
              "Tap on the camera icon to upload image",
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceField(String hint) {
    return TextField(
      controller: _priceController,
      decoration: _inputDecoration(
        hint,
        prefixIcon: _buildPrefixIcon(Icons.currency_rupee),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPrefixIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: const Color(0xFFD1E1FF).withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(icon, color: const Color(0xFF4A69FF), size: 20),
    );
  }

  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_nameController.text.isEmpty) {
      _showSnackbar("Please enter a name");
      return;
    }
    if (selectedCategory == null) {
      _showSnackbar("Please select a category");
      return;
    }
    if (selectedSubtype == null) {
      _showSnackbar("Please select subtype");
      return;
    }
    if (_priceController.text.isEmpty) {
      _showSnackbar("Please enter a price");
      return;
    }
    if (!isNewspaper && selectedNewspaperId == null) {
      _showSnackbar("Please select a parent newspaper");
      return;
    }

    setState(() => _isSubmitting = true);

    bool isEditing =
        widget.editNewspaper != null || widget.editMagazine != null;
    String? base64Image =
        widget.editNewspaper?.logoUrl ?? widget.editMagazine?.logoUrl;

    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    try {
      if (isNewspaper) {
        final url = Uri.parse(
          isEditing
              ? '${ApiConstants.baseUrl}/Publications/UpdateNewspaper/${widget.editNewspaper!.newspaperId}'
              : '${ApiConstants.baseUrl}/Publications/AddNewspaper',
        );

        final requestBody = jsonEncode({
          if (isEditing) "newspaperId": widget.editNewspaper!.newspaperId,
          "name": _nameController.text,
          "category": selectedCategory,
          "paperType": selectedSubtype,
          "basePrice": double.tryParse(_priceController.text) ?? 0.0,
          "logoBase64": base64Image,
          "isActive": isActive,
        });

        final response = isEditing
            ? await http.put(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              )
            : await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              );

        _handleResponse(response, isEditing);
      } else {
        final url = Uri.parse(
          isEditing
              ? '${ApiConstants.baseUrl}/Publications/UpdateMagazine/${widget.editMagazine!.magazineId}'
              : '${ApiConstants.baseUrl}/Publications/AddMagazine',
        );

        final requestBody = jsonEncode({
          if (isEditing) "magazineId": widget.editMagazine!.magazineId,
          "newspaperId": selectedNewspaperId,
          "name": _nameController.text,
          "category": selectedCategory,
          "publicationCycle": selectedSubtype,
          "price": double.tryParse(_priceController.text) ?? 0.0,
          "logoBase64": base64Image,
          "isActive": isActive,
        });

        final response = isEditing
            ? await http.put(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              )
            : await http.post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: requestBody,
              );

        _handleResponse(response, isEditing);
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleResponse(http.Response response, bool isEditing) {
    if (response.statusCode == 200) {
      _showSnackbar(
        isEditing
            ? "Successfully updated publication!"
            : "Successfully added publication!",
        color: Colors.green,
      );
      
      // Navigate back after success
      Navigator.pop(context);
    } else {
      _showSnackbar("Failed to add publication. Please try again.");
    }
  }

  void _showSnackbar(String msg, {Color color = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC154),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                isNewspaper
                    ? (widget.editNewspaper != null
                          ? "Update Newspaper"
                          : "Add Newspaper")
                    : (widget.editMagazine != null
                          ? "Update Magazine"
                          : "Add Magazine"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
