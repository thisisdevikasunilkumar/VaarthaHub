import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/other_product.dart';
import 'reader_other_product_booking_history_screen.dart';

class BrowseOtherProductsScreen extends StatefulWidget {
  const BrowseOtherProductsScreen({super.key});

  @override
  State<BrowseOtherProductsScreen> createState() =>
      _BrowseOtherProductsScreenState();
}

class _BrowseOtherProductsScreenState extends State<BrowseOtherProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isCalendarTab = true;
  bool _isLoading = true;
  List<OtherProduct> _products = [];
  int? _readerId;
  String? _readerCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          isCalendarTab = _tabController.index == 0;
        });
      }
    });
    _loadReaderData().then((_) => _fetchProducts());
  }

  Future<void> _loadReaderData() async {
    final prefs = await SharedPreferences.getInstance();
    _readerCode = prefs.getString('readerCode');
    if (_readerCode != null) {
      try {
        final url = Uri.parse(
          "${ApiConstants.baseUrl}/Reader/GetReaderProfile/$_readerCode",
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _readerId = data['readerId'];
          });
        }
      } catch (e) {
        debugPrint("Error loading reader profile: $e");
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/OtherProducts');
      final res = await http.get(url);
      if (res.statusCode == 200) {
        setState(() {
          _products = (jsonDecode(res.body) as List)
              .map((i) => OtherProduct.fromJson(i))
              .where((p) => p.isActive)
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<OtherProduct> displayedItems = _products.where((p) {
      return isCalendarTab ? p.itemId == 3 : p.itemId == 4;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                _buildAppBar()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1, end: 0),
                const SizedBox(height: 10),
                _buildTabs().animate().fadeIn(duration: 500.ms, delay: 100.ms),
                const SizedBox(height: 15),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF9C55E),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchProducts,
                            color: const Color(0xFFF9C55E),
                            child: displayedItems.isEmpty
                                ? _buildEmptyState()
                                : GridView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 15,
                                          mainAxisSpacing: 15,
                                          childAspectRatio: 0.65,
                                        ),
                                    itemCount: displayedItems.length,
                                    itemBuilder: (context, index) =>
                                        _buildGridItem(displayedItems[index]),
                                  ),
                          ),
                  ),
                ),
              ],
            ),
          ),
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
          "Calendars & Diaries",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.history, color: Colors.black),
          onPressed: () {
            if (_readerId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderOtherProductBookingHistoryScreen(
                    readerId: _readerId!,
                    readerCode: _readerCode!,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Loading reader data...")),
              );
            }
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 48,
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
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Calendars"),
            Tab(text: "Diaries"),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCalendarTab ? Icons.calendar_today : Icons.book,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          Text(
            "No ${isCalendarTab ? 'Calendars' : 'Diaries'} available.",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(OtherProduct item) {
    final color = isCalendarTab ? Colors.green : Colors.orange;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
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
                  height: 35,
                  width: 35,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.name[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  "₹${item.unitPrice}",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!.startsWith('http')
                        ? item.imageUrl!
                        : '${ApiConstants.baseUrl.replaceAll('/api', '')}${item.imageUrl!}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Year: ${item.year}",
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showBookingDialog(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color.withValues(alpha: 0.1),
                    foregroundColor: color,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Book Now",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(OtherProduct item) {
    int quantity = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Book ${item.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Price: ₹${item.unitPrice}"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: quantity > 1
                        ? () => setDialogState(() => quantity--)
                        : null,
                  ),
                  Text(
                    "$quantity",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setDialogState(() => quantity++),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Total: ₹${(item.unitPrice * quantity).toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processBooking(item, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C55E),
              ),
              child: const Text(
                "Confirm Booking",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processBooking(OtherProduct item, int quantity) async {
    if (_readerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Profile not loaded")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/OtherProductBookings/AddBooking",
      );
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "readerId": _readerId,
          "productId": item.productId,
          "quantity": quantity,
          "totalAmount": item.unitPrice * quantity,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Booking failed: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Booking Successful!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your request has been sent to the delivery partner and admin.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9C55E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("OK", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
