import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/other_product.dart';
import 'package:vaarthahub_app/models/newspaper.dart';

class AddOtherProductScreen extends StatefulWidget {
  final OtherProduct? editProduct;
  final bool initialIsCalendar;

  const AddOtherProductScreen({
    super.key,
    this.editProduct,
    this.initialIsCalendar = true,
  });

  @override
  State<AddOtherProductScreen> createState() => _AddOtherProductScreenState();
}

class _AddOtherProductScreenState extends State<AddOtherProductScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isCalendarTab = true;
  bool _isSubmitting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  late TextEditingController _productTypeController;
  late TextEditingController _sizeController;

  String? selectedItemType;
  int? selectedNewspaperId;
  String? selectedYear;
  bool isActive = true;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<Newspaper> _newspapers = [];
  bool _isLoadingNewspapers = false;

  final List<String> calendarItemTypes = ["Calendar"];
  final List<String> diaryItemTypes = ["Diary"];

  final List<String> availableYears = ["2024", "2025", "2026", "2027", "2028"];

  @override
  void initState() {
    super.initState();
    isCalendarTab = widget.editProduct != null
        ? widget.editProduct!.itemId == 3
        : widget.initialIsCalendar;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: isCalendarTab ? 0 : 1,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        bool isEditing = widget.editProduct != null;
        if (isEditing) {
          // Revert tab if editing
          _tabController.index = isCalendarTab ? 0 : 1;
          return;
        }
        setState(() {
          isCalendarTab = _tabController.index == 0;
          selectedItemType = null;
        });
      }
    });

    _fetchNewspapers();

    if (widget.editProduct != null) {
      final p = widget.editProduct!;
      _nameController.text = p.name;
      _priceController.text = p.unitPrice.toString();
      selectedItemType = p.itemType;
      selectedNewspaperId = p.newspaperId;
      selectedYear = p.year;
      isActive = p.isActive;
      _productTypeController = TextEditingController(text: p.productType ?? '');
      _sizeController = TextEditingController(text: p.size ?? '');
    } else {
      _productTypeController = TextEditingController();
      _sizeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _productTypeController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _fetchNewspapers() async {
    setState(() => _isLoadingNewspapers = true);
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetNewspapers',
      );
      final res = await http.get(url);
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _newspapers = (jsonDecode(res.body) as List)
                .map((i) => Newspaper.fromJson(i))
                .toList();

            if (selectedNewspaperId != null &&
                !_newspapers.any((n) => n.newspaperId == selectedNewspaperId)) {
              selectedNewspaperId = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching newspapers: $e");
    } finally {
      if (mounted) setState(() => _isLoadingNewspapers = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
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

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty) {
      _showSnackbar('Please enter a name');
      return;
    }
    if (selectedItemType == null) {
      _showSnackbar('Please select an Item Type');
      return;
    }
    if (selectedNewspaperId == null) {
      _showSnackbar('Please select a Parent Newspaper');
      return;
    }
    if (selectedYear == null) {
      _showSnackbar('Please select a Year');
      return;
    }
    if (isCalendarTab && _productTypeController.text.isEmpty) {
      _showSnackbar('Please enter Calendar Type');
      return;
    }
    if (!isCalendarTab) {
      if (_productTypeController.text.isEmpty) {
        _showSnackbar('Please enter Diary Type');
        return;
      }
      if (_sizeController.text.isEmpty) {
        _showSnackbar('Please enter Size');
        return;
      }
    }
    if (_priceController.text.isEmpty) {
      _showSnackbar('Please enter a price');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = widget.editProduct == null
          ? Uri.parse('${ApiConstants.baseUrl}/OtherProducts')
          : Uri.parse(
              '${ApiConstants.baseUrl}/OtherProducts/${widget.editProduct!.productId}',
            );

      var request = http.MultipartRequest(
        widget.editProduct == null ? 'POST' : 'PUT',
        uri,
      );

      request.fields['ItemId'] = isCalendarTab ? '3' : '4';
      request.fields['ItemType'] = selectedItemType!;
      request.fields['NewspaperId'] = selectedNewspaperId!.toString();
      request.fields['Name'] = _nameController.text;
      request.fields['Year'] = selectedYear!;
      request.fields['UnitPrice'] = _priceController.text;
      request.fields['ProductType'] = _productTypeController.text;
      request.fields['Size'] = isCalendarTab ? '' : _sizeController.text;
      request.fields['IsActive'] = isActive.toString();

      if (widget.editProduct != null) {
        request.fields['ProductId'] = widget.editProduct!.productId.toString();
      }

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imageFile', _imageFile!.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        _showSnackbar(
          "${isCalendarTab ? 'Calendar' : 'Diary'} saved successfully",
          color: Colors.green,
        );
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackbar("Failed to save item. Please try again.");
      }
    } catch (e) {
      _showSnackbar("An error occurred: $e");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
            child:
                Column(
                      children: [
                        const SizedBox(height: 30),
                        _buildAppBar(),
                        const SizedBox(height: 20),
                        _buildToggleTabs(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            physics: widget.editProduct != null
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            children: [
                              // Calendar Form
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                  vertical: 10,
                                ),
                                child: _buildForm(true),
                              ),
                              // Diary Form
                              SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 25,
                                  vertical: 10,
                                ),
                                child: _buildForm(false),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
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
            "Add Other Products",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTabs() {
    bool isEditing = widget.editProduct != null;
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
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Calendar"),
            Tab(text: "Diary"),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool calendarMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel("Item Type"),
        _buildDropdown(
          hint: "Select Item Type",
          value: selectedItemType,
          items: calendarMode ? calendarItemTypes : diaryItemTypes,
          onChanged: (val) => setState(() => selectedItemType = val as String?),
        ),
        _buildLabel("Parent Newspaper"),
        _buildDropdown(
          hint: _isLoadingNewspapers
              ? "Loading newspapers..."
              : "Select Newspaper",
          value: selectedNewspaperId,
          items: _newspapers.map((n) => n.newspaperId).toList(),
          itemLabels: _newspapers.map((n) => n.name).toList(),
          onChanged: (val) => setState(() => selectedNewspaperId = val as int?),
        ),
        _buildLabel("Name"),
        _buildImageTextField(
          calendarMode ? "Enter Calendar Name" : "Enter Diary Name",
          Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 20),
        if (calendarMode) ...[
          _buildLabel("Calendar Type"),
          _buildTextField("Enter Calendar Type", _productTypeController),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Diary Type"),
                    _buildTextField("Enter Diary Type", _productTypeController),
                  ],
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Size"),
                    _buildTextField("Enter Size", _sizeController),
                  ],
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Year"),
                  _buildDropdown(
                    hint: "Select Category",
                    value: selectedYear,
                    items: availableYears,
                    onChanged: (val) =>
                        setState(() => selectedYear = val as String?),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Unit Price"),
                  _buildPriceField("Enter Price"),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStatusSwitch(),
        const SizedBox(height: 30),
        _buildSubmitButton(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required dynamic value,
    required List<dynamic> items,
    List<String>? itemLabels,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1E1FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          items: List.generate(items.length, (index) {
            return DropdownMenuItem<dynamic>(
              value: items[index],
              child: Text(
                itemLabels != null
                    ? itemLabels[index]
                    : items[index].toString(),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            );
          }),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),
    );
  }

  Widget _buildImageTextField(String hint, IconData icon) {
    bool hasExistingLogo =
        widget.editProduct?.imageUrl != null &&
        widget.editProduct!.imageUrl!.isNotEmpty;

    Widget? suffixWidget;
    if (_imageFile != null) {
      suffixWidget = Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.file(
            _imageFile!,
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
          child: Image.network(
            '${ApiConstants.baseUrl.replaceAll('/api', '')}${widget.editProduct!.imageUrl}',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
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

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildPriceField(String hint) {
    return TextField(
      controller: _priceController,
      decoration: _inputDecoration(
        hint,
        prefixIcon: _buildPrefixIcon(Icons.currency_rupee),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
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
                widget.editProduct == null
                    ? (isCalendarTab ? "Add Calendar" : "Add Diary")
                    : (isCalendarTab ? "Update Calendar" : "Update Diary"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
