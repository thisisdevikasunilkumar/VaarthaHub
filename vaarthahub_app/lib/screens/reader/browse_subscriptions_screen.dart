import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/newspaper.dart';
import 'package:vaarthahub_app/models/magazine.dart';
import 'my_subscriptions_screen.dart';

class BrowseSubscriptionsScreen extends StatefulWidget {
  const BrowseSubscriptionsScreen({super.key});

  @override
  State<BrowseSubscriptionsScreen> createState() =>
      _BrowseSubscriptionsScreenState();
}

class _BrowseSubscriptionsScreenState extends State<BrowseSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = "All";
  bool isNewspaperTab = true;
  bool _isLoading = true;
  List<Newspaper> _newspapers = [];
  List<Magazine> _magazines = [];
  int? _readerId;
  String? _readerCode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          isNewspaperTab = _tabController.index == 0;
          selectedFilter = "All";
        });
      }
    });
    _loadReaderData().then((_) => _fetchPublications());
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- API CALL IMPLEMENTATION ---
  Future<void> _fetchPublications() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // Fetch Newspapers
      final newsUrl = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetNewspapers',
      );
      final newsRes = await http.get(newsUrl);
      if (newsRes.statusCode == 200) {
        _newspapers = (jsonDecode(newsRes.body) as List)
            .map((i) => Newspaper.fromJson(i))
            .where((n) => n.isActive) // Only show active items to readers
            .toList();
        // Sort alphabetically by name
        _newspapers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }

      // Fetch Magazines
      final magUrl = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetMagazines',
      );
      final magRes = await http.get(magUrl);
      if (magRes.statusCode == 200) {
        _magazines = (jsonDecode(magRes.body) as List)
            .map((i) => Magazine.fromJson(i))
            .where((m) => m.isActive) // Only show active items to readers
            .toList();
        // Sort alphabetically by name
        _magazines.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }
    } catch (e) {
      debugPrint("Error fetching publications: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> newspaperCategories = [
    "All",
    "Community",
    "English",
    "General",
    "Political",
    "Evening Dailies",
    "Education",
    "Specials",
  ];

  final List<String> magazineCategories = [
    "All",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Element
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
                    .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 10),
                // Toggle Buttons (Newspaper / Magazine)
                Padding(
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
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: "Newspapers"),
                            Tab(text: "Magazines"),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 15),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isLoading
                        ? const Center(
                            key: ValueKey('loading'),
                            child: CircularProgressIndicator(
                              color: Color(0xFFF9C55E),
                            ),
                          )
                        : TabBarView(
                            key: const ValueKey('content'),
                            controller: _tabController,
                            children: [
                              // Newspaper Tab
                              RefreshIndicator(
                                onRefresh: _fetchPublications,
                                color: const Color(0xFFF9C55E),
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child:
                                      Column(
                                            children: [
                                              _buildCategoryFilters(),
                                              if (_newspapers.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 50,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "No newspapers found",
                                                    ),
                                                  ),
                                                )
                                              else
                                                const SizedBox(height: 20),
                                              ..._buildFilteredNewspapers(),
                                              const SizedBox(height: 100),
                                            ],
                                          )
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(
                                            begin: 0.08,
                                            end: 0,
                                            curve: Curves.easeOut,
                                          ),
                                ),
                              ),
                              // Magazine Tab
                              RefreshIndicator(
                                onRefresh: _fetchPublications,
                                color: const Color(0xFFF9C55E),
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child:
                                      Column(
                                            children: [
                                              _buildCategoryFilters(),
                                              if (_magazines.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.only(
                                                    top: 50,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "No magazines found",
                                                    ),
                                                  ),
                                                )
                                              else
                                                const SizedBox(height: 20),
                                              ..._buildFilteredMagazines(),
                                              const SizedBox(height: 100),
                                            ],
                                          )
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(
                                            begin: 0.08,
                                            end: 0,
                                            curve: Curves.easeOut,
                                          ),
                                ),
                              ),
                            ],
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
          "Browse Subscriptions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final List<String> currentFilters = isNewspaperTab
        ? newspaperCategories
        : magazineCategories;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: currentFilters.map((filterName) {
          bool isSelected = selectedFilter == filterName;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filterName),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF9C55E)
                    // ignore: deprecated_member_use
                    : Colors.blueGrey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filterName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- FILTER LOGIC FOR NEWSPAPERS ---
  List<Widget> _buildFilteredNewspapers() {
    List<Widget> sections = [];

    // Group by category
    Map<String, List<Newspaper>> grouped = {};
    for (var n in _newspapers) {
      String cat = n.category.isNotEmpty ? n.category : "General";
      if (selectedFilter == "All" || selectedFilter == cat) {
        grouped.putIfAbsent(cat, () => []).add(n);
      }
    }

    final categoryIcons = {
      "Community": {"icon": Icons.people_outline, "color": Colors.green},
      "English": {"icon": Icons.language, "color": Colors.orange},
      "General": {"icon": Icons.newspaper, "color": Colors.blue},
      "Political": {"icon": Icons.gavel, "color": Colors.red},
      "Evening Dailies": {"icon": Icons.wb_twilight, "color": Colors.teal},
      "Education": {"icon": Icons.school, "color": Colors.cyan},
      "Specials": {"icon": Icons.star_border, "color": Colors.amber},
    };

    grouped.forEach((category, items) {
      final info =
          categoryIcons[category] ??
          {"icon": Icons.newspaper, "color": Colors.blue};
      final color = info["color"] as MaterialColor;

      sections.add(
        _buildSection(
          title: category,
          icon: info["icon"] as IconData,
          iconColor: color,
          items: items.map((item) {
            String name = item.name;
            return _buildSubscriptionGridItem(
              title: name,
              subtitle: "$category • ${item.paperType}",
              price: "₹ ${(item.basePrice).toStringAsFixed(2)}",
              logoBase64: item.logoUrl,
              logoLetter: name.isNotEmpty ? name[0].toUpperCase() : "N",
              color: color.shade50,
              borderColor: color,
              onTap: () => _subscribe(
                itemId: item.itemId,
                publicationId: item.newspaperId,
                itemType: "Newspaper",
                category: item.category,
                price: item.basePrice.toDouble(),
                name: item.name,
                deliverySlot: item.paperType,
              ),
            );
          }).toList(),
        ),
      );
    });

    return sections
        .expand((widget) => [widget, const SizedBox(height: 20)])
        .toList();
  }

  // --- FILTER LOGIC FOR MAGAZINES ---
  List<Widget> _buildFilteredMagazines() {
    List<Widget> sections = [];

    // Group by category
    Map<String, List<Magazine>> grouped = {};
    for (var m in _magazines) {
      String cat = m.category.isNotEmpty ? m.category : "General";
      if (selectedFilter == "All" || selectedFilter == cat) {
        grouped.putIfAbsent(cat, () => []).add(m);
      }
    }

    final categoryIcons = {
      "Children": {
        "icon": Icons.sentiment_satisfied_alt,
        "color": Colors.purple,
      },
      "Women": {"icon": Icons.favorite_border, "color": Colors.pink},
      "Health": {"icon": Icons.favorite_border, "color": Colors.pink},
      "Weekly": {"icon": Icons.view_week, "color": Colors.brown},
      "Farming": {"icon": Icons.explore, "color": Colors.indigo},
      "Automobile": {"icon": Icons.explore, "color": Colors.indigo},
      "Travel": {"icon": Icons.explore, "color": Colors.indigo},
      "Education": {"icon": Icons.school, "color": Colors.cyan},
    };

    grouped.forEach((category, items) {
      final info =
          categoryIcons[category] ?? {"icon": Icons.book, "color": Colors.teal};
      final color = info["color"] as MaterialColor;

      sections.add(
        _buildSection(
          title: category,
          icon: info["icon"] as IconData,
          iconColor: color,
          items: items.map((item) {
            String name = item.name;
            return _buildSubscriptionGridItem(
              title: name,
              subtitle: "$category • ${item.publicationCycle}",
              price: "₹ ${(item.price).toStringAsFixed(2)}",
              logoBase64: item.logoUrl,
              logoLetter: name.isNotEmpty ? name[0].toUpperCase() : "M",
              color: color.shade50,
              borderColor: color,
              onTap: () => _subscribe(
                itemId: item.itemId,
                publicationId: item.magazineId,
                itemType: "Magazine",
                category: item.category,
                price: item.price.toDouble(),
                name: item.name,
                deliverySlot: item.publicationCycle,
              ),
            );
          }).toList(),
        ),
      );
    });

    return sections
        .expand((widget) => [widget, const SizedBox(height: 20)])
        .toList();
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children: items
              .map(
                (item) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 55) / 2,
                  height: 180,
                  child: item,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubscriptionGridItem({
    required String title,
    required String subtitle,
    required String price,
    String? logoBase64,
    required String logoLetter,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: borderColor.withValues(alpha: 0.3), width: 1.5),
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
                  child: (logoBase64 != null && logoBase64.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(logoBase64),
                            fit: BoxFit.cover,
                            width: 40,
                            height: 40,
                          ),
                        )
                      : Text(
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
                    // ignore: deprecated_member_use
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
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                // ignore: deprecated_member_use
                backgroundColor: borderColor.withValues(alpha: 0.1),
                foregroundColor: borderColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 0),
                minimumSize: const Size(double.infinity, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Subscribe",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe({
    required int itemId,
    required int publicationId,
    required String itemType,
    required String category,
    required double price,
    required String name,
    required String deliverySlot,
  }) async {
    if (_readerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Reader profile not loaded.")),
      );
      return;
    }

    int? selectedDuration;
    DateTime startDate = DateTime.now();

    // Calculate correct total based on type
    double calcTotal(int months) {
      if (itemType == "Newspaper") {
        // basePrice is per day → multiply by 30 days per month
        return price * 30 * months;
      } else {
        // Magazine price is per issue → determine issues per month from PublicationCycle
        String cycle = deliverySlot.toLowerCase();
        int issuesPerMonth = 1;
        if (cycle.contains('week')) {
          issuesPerMonth = 4;
        } else if (cycle.contains('fortnight') || cycle.contains('bi-')) {
          issuesPerMonth = 2;
        } else {
          issuesPerMonth = 1; // Monthly or default
        }
        return price * issuesPerMonth * months;
      }
    }

    // Show duration selection dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Subscription Duration"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 3, 6, 12].map((months) {
            return ListTile(
              title: Text("$months Month${months > 1 ? 's' : ''}"),
              subtitle: Text("Total: ₹ ${calcTotal(months).toStringAsFixed(2)}"),
              onTap: () {
                selectedDuration = months;
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );

    if (selectedDuration == null) return;

    if (!mounted) return; // guard context after showDialog async gap

    // Show date picker to select delivery start date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Select Delivery Start Date",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF9C55E),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return; // user cancelled date picker

    startDate = pickedDate;

    DateTime endDate = DateTime(
      startDate.year,
      startDate.month + selectedDuration!,
      startDate.day,
    );
    double totalAmount = calcTotal(selectedDuration!);

    if (!mounted) return;

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Subscriptions/AddSubscription");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "readerId": _readerId,
          "itemId": itemId,
          "publicationId": publicationId,
          "itemType": itemType,
          "subscriptionName": name,
          "category": category,
          "durationMonths": selectedDuration,
          "totalAmount": totalAmount,
          "startDate": startDate.toIso8601String(),
          "endDate": endDate.toIso8601String(),
          "deliverySlot": deliverySlot,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subscribed successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MySubscriptionsScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to subscribe: ${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
