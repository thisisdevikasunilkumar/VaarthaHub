import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/other_product.dart';

import '../admin/add_other_product_screen.dart';

class ManageCalendarDairyScreen extends StatefulWidget {
  const ManageCalendarDairyScreen({super.key});

  @override
  State<ManageCalendarDairyScreen> createState() =>
      _ManageCalendarDairyScreenState();
}

class _ManageCalendarDairyScreenState extends State<ManageCalendarDairyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isCalendarTab = true;
  bool _isLoading = true;
  List<OtherProduct> _products = [];
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          isCalendarTab = _tabController.index == 0;
          selectedFilter = "All";
        });
      }
    });
    _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/OtherProducts');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _products = (jsonDecode(res.body) as List)
            .map((i) => OtherProduct.fromJson(i))
            .toList();
      }
    } catch (e) {
      debugPrint("Error fetching other products: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/OtherProducts/$productId');
      final res = await http.delete(url);
      if (res.statusCode == 200 || res.statusCode == 204) {
        _fetchProducts();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete item.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<OtherProduct> displayedItems = _products.where((p) {
      bool correctTab = true;
      if (isCalendarTab && p.itemId != 3) correctTab = false;
      if (!isCalendarTab && p.itemId != 4) correctTab = false;

      bool filterMatch = true;
      if (selectedFilter != "All" && p.year != selectedFilter) {
        filterMatch = false;
      }
      return correctTab && filterMatch;
    }).toList();

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
                  Container(height: 150, color: const Color(0xFFF9C55E)),
            ),
          ),
          SafeArea(
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),
                        _buildAppBar(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildSectionHeader(),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildProductList(displayedItems, Colors.green),
                              _buildProductList(displayedItems, Colors.orange),
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

  Widget _buildProductList(
    List<OtherProduct> displayedItems,
    MaterialColor color,
  ) {
    return RefreshIndicator(
      onRefresh: _fetchProducts,
      color: const Color(0xFFF9C55E),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
            )
          : displayedItems.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.65,
              ),
              itemCount: displayedItems.length,
              itemBuilder: (context, index) {
                final item = displayedItems[index];

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _buildGridItem(
                    item: item,
                    color: color.shade50,
                    borderColor: color,
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddOtherProductScreen(editProduct: item),
                        ),
                      );
                      _fetchProducts();
                    },
                    onDelete: () => _deleteProduct(item.productId),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCalendarTab ? Icons.calendar_month : Icons.menu_book,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "No ${isCalendarTab ? 'Calendars' : 'Diaries'} found",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required OtherProduct item,
    required Color color,
    required Color borderColor,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final title = item.name;
    final subtitle = item.year.isNotEmpty ? "Year: ${item.year}" : "";
    final pType = item.productType ?? "";
    final pSize = item.size ?? "";
    final price = "₹ ${(item.unitPrice).toStringAsFixed(2)}";
    final logoLetter = title.isNotEmpty
        ? title[0].toUpperCase()
        : (isCalendarTab ? "C" : "D");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    // മുകളിൽ ഇടതുവശത്ത് അക്ഷരം മാത്രം കാണിക്കുന്നു
                    logoLetter,
                    style: TextStyle(
                      color: borderColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: borderColor.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                if (pType.isNotEmpty)
                  Text(
                    "Type: $pType",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                if (!isCalendarTab && pSize.isNotEmpty)
                  Text(
                    "Size: $pSize",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            ),
          ),
          // ഇമേജ് ഇവിടെ കാണിക്കുന്നു: വർഷത്തിന് താഴെയും എഡിറ്റ്/ഡിലീറ്റ് ബട്ടണുകൾക്ക് മുകളിലും
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.imageUrl!.startsWith('http')
                        ? item.imageUrl!
                        : '${ApiConstants.baseUrl.replaceAll('/api', '')}${item.imageUrl!}',
                    fit: BoxFit.cover, // ഇമേജ് പൂർണ്ണമായി കാണിക്കാൻ
                    width: double
                        .infinity, // ലഭ്യമായ മുഴുവൻ വീതിയും ഉപയോഗിക്കുന്നു
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      size: 40,
                    ), // വലിയ പിശക് ഐക്കൺ
                  ),
                ),
              ),
            )
          else
            const Spacer(), // ഇമേജ് ഇല്ലെങ്കിൽ ബട്ടണുകൾ താഴേക്ക് തള്ളാൻ Spacer ഉപയോഗിക്കുന്നു
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor.withValues(alpha: 0.1),
                      foregroundColor: borderColor,
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.edit_note_rounded, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.delete_outline, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const Text(
          "Calendar & Diary",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 48,
          width: 250,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEABF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFFF9C55E),
              borderRadius: BorderRadius.circular(10),
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
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddOtherProductScreen(initialIsCalendar: isCalendarTab),
              ),
            );
            _fetchProducts(); // Reload active entries after pop
          },
          child: const Text(
            "+ Add",
            style: TextStyle(
              color: Color(0xFFF9C55E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
