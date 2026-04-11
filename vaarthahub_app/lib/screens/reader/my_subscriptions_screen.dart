// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import '../reader/browse_subscriptions_screen.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  // --- UI State Variables ---
  String selectedCategory = "All";
  bool isNewspaperTab = true;
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _subscriptions = [];
  int? _readerId;

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

  final Map<String, dynamic> newspaperCategoryIcons = {
    "Community": {"icon": Icons.people_outline, "color": Colors.green},
    "English": {"icon": Icons.language, "color": Colors.orange},
    "General": {"icon": Icons.newspaper, "color": Colors.blue},
    "Political": {"icon": Icons.gavel, "color": Colors.red},
    "Evening Dailies": {"icon": Icons.wb_twilight, "color": Colors.teal},
    "Education": {"icon": Icons.school, "color": Colors.cyan},
    "Specials": {"icon": Icons.star_border, "color": Colors.amber},
  };

  final Map<String, dynamic> magazineCategoryIcons = {
    "Children": {"icon": Icons.sentiment_satisfied_alt, "color": Colors.purple},
    "Women": {"icon": Icons.favorite_border, "color": Colors.pink},
    "Health": {"icon": Icons.favorite_border, "color": Colors.pink},
    "Weekly": {"icon": Icons.view_week, "color": Colors.brown},
    "Farming": {"icon": Icons.explore, "color": Colors.indigo},
    "Automobile": {"icon": Icons.explore, "color": Colors.indigo},
    "Travel": {"icon": Icons.explore, "color": Colors.indigo},
    "Education": {"icon": Icons.school, "color": Colors.cyan},
    "General": {"icon": Icons.book, "color": Colors.teal},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          isNewspaperTab = _tabController.index == 0;
          selectedCategory = "All";
        });
      }
    });
    _loadReaderAndSubscriptions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReaderAndSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final readerCode = prefs.getString('readerCode');
    if (readerCode != null) {
      try {
        final profileUrl = Uri.parse(
          "${ApiConstants.baseUrl}/Reader/GetReaderProfile/$readerCode",
        );
        final profileRes = await http.get(profileUrl);
        if (profileRes.statusCode == 200) {
          final profileData = json.decode(profileRes.body);
          _readerId = profileData['readerId'];
          if (_readerId != null) {
            await _fetchSubscriptions();
          }
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchSubscriptions() async {
    if (_readerId == null) return;
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Subscriptions/GetReaderSubscriptions/$_readerId",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _subscriptions = json.decode(response.body);
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching subscriptions: $e");
    }
  }

  Future<void> _toggleVacation(int subscriptionId) async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Subscriptions/ToggleVacation/$subscriptionId",
      );
      final response = await http.post(url);
      if (response.statusCode == 200) {
        await _fetchSubscriptions(); // Refresh list to get updated status
      } else {
        debugPrint("Error toggling vacation: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setVacationDates() async {
    if (_readerId == null) return;

    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomVacationDatePicker(),
    );

    if (picked != null) {
      final List<dynamic> activeSubscriptions = _subscriptions
          .where((s) => s['isActive'] == "Active")
          .toList();

      if (activeSubscriptions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active subscriptions found.')),
          );
        }
        return;
      }

      final List<int>? selectedIds = await showModalBottomSheet<List<int>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SubscriptionSelectionBottomSheet(
          subscriptions: activeSubscriptions,
          dateRange: picked,
        ),
      );

      if (selectedIds != null && selectedIds.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          final url = Uri.parse(
            "${ApiConstants.baseUrl}/Subscriptions/SetVacationDates",
          );
          final body = json.encode({
            "readerId": _readerId,
            "subscriptionIds": selectedIds,
            "startDate": picked.start.toIso8601String(),
            "endDate": picked.end.toIso8601String(),
          });
          final response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: body,
          );

          if (response.statusCode == 200) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vacation dates scheduled successfully!'),
                ),
              );
            }
            await _fetchSubscriptions();
          } else {
            debugPrint("Error setting dates: ${response.body}");
          }
        } catch (e) {
          debugPrint("Error: $e");
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildSubscriptionListForTab(String tabType) {
    // Filter subscriptions for current tab
    final List<dynamic> tabSubs = _subscriptions.where((s) {
      final type = s['itemType']?.toString().trim().toLowerCase() ?? "";
      return type.startsWith(tabType.toLowerCase());
    }).toList();

    // Apply category filtering
    List<dynamic> filteredSubs = tabSubs.where((s) {
      String itemCat =
          (s['category'] != null && s['category'].toString().isNotEmpty)
          ? s['category']
          : "General";
      return selectedCategory == "All" || itemCat == selectedCategory;
    }).toList();

    final Map<String, List<dynamic>> groupedSubs = {};
    for (final sub in filteredSubs) {
      final String itemCat =
          (sub['category'] != null && sub['category'].toString().isNotEmpty)
          ? sub['category']
          : "General";
      groupedSubs.putIfAbsent(itemCat, () => []).add(sub);
    }

    return RefreshIndicator(
      onRefresh: _fetchSubscriptions,
      color: const Color(0xFFF9C55E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildCategoryFilters(),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Active Subscriptions",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 15),
            if (filteredSubs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50),
                  child: Text("No subscriptions found"),
                ),
              )
            else
              ..._buildGroupedSubscriptionItems(
                groupedSubs: groupedSubs,
                tabType: tabType,
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildVacationBanner(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedSubscriptionItems({
    required Map<String, List<dynamic>> groupedSubs,
    required String tabType,
  }) {
    final List<Widget> sections = [];
    int totalItems = 0;

    groupedSubs.forEach((category, items) {
      sections.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildCategorySectionHeader(title: category, tabType: tabType),
        ),
      );
      sections.add(const SizedBox(height: 12));

      for (final sub in items) {
        final int index = totalItems++;
        sections.add(
          TweenAnimationBuilder<double>(
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
              child: _buildSubscriptionItem(sub),
            ),
          ),
        );
      }
    });

    return sections;
  }

  Widget _buildCategorySectionHeader({
    required String title,
    required String tabType,
  }) {
    final Map<String, dynamic> iconMap = tabType == "Newspaper"
        ? newspaperCategoryIcons
        : magazineCategoryIcons;
    final info =
        iconMap[title] ??
        {
          "icon": tabType == "Newspaper" ? Icons.newspaper : Icons.book,
          "color": tabType == "Newspaper" ? Colors.blue : Colors.teal,
        };

    return Row(
      children: [
        Icon(info["icon"] as IconData, color: info["color"] as Color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background UI Element
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
                        // Admin Section Header with Add Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildSectionHeader(),
                        ),

                        // --- Subscriptions Section ---
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF9C55E),
                                  ),
                                )
                              : TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildSubscriptionListForTab("Newspaper"),
                                    _buildSubscriptionListForTab("Magazine"),
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

  Widget _buildSubscriptionItem(dynamic s) {
    bool isActive = s['isActive'] == "Active";

    String itemCat =
        (s['category'] != null && s['category'].toString().isNotEmpty)
        ? s['category']
        : "General";

    Color color;
    final String itemType =
        s['itemType']?.toString().trim().toLowerCase() ?? "";
    if (itemType.startsWith("newspaper")) {
      final info = newspaperCategoryIcons[itemCat] ?? {"color": Colors.blue};
      color = info["color"] as Color;
    } else {
      final info = magazineCategoryIcons[itemCat] ?? {"color": Colors.teal};
      color = info["color"] as Color;
    }

    String endDateStr = "N/A";
    if (s['endDate'] != null) {
      try {
        DateTime dt = DateTime.parse(s['endDate']);
        endDateStr = "${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {}
    }

    return _buildSubscriptionCard(
      title: s['itemName'] ?? "Unnamed Item",
      subtitle: "${s['itemType']} • ${s['deliverySlot']}",
      price: "₹ ${(s['price'] ?? 0.0).toStringAsFixed(2)}",
      date: endDateStr,
      borderColor: color,
      logoLetter: s['itemName']?.isNotEmpty == true ? s['itemName'][0] : "?",
      logoColor: color.withValues(alpha: 0.1),
      isActive: isActive,
      onToggle: (val) {
        _toggleVacation(s['subscriptionId']);
      },
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
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
            "My Subscriptions",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
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
          bool isSelected = selectedCategory == filterName;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = filterName),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF9C55E)
                    // ignore: deprecated_member_use
                    : Colors.blueGrey.withOpacity(0.05),
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
            tabs: [
              Tab(text: "Newspapers"),
              Tab(text: "Magazines"),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            // Logic to add subscription
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BrowseSubscriptionsScreen(),
              ),
            );
          },
          child: const Text(
            "+ Add",
            style: TextStyle(
              color: Color(0xFFE5A000),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String subtitle,
    required String price,
    required String date,
    required Color borderColor,
    required String logoLetter,
    required Color logoColor,
    required bool isActive,
    required Function(bool) onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: logoColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  logoLetter,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isActive ? "Active" : "Paused",
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: onToggle,
                activeThumbColor: Colors.white,
                activeTrackColor: Colors.black87,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoBox(price, "Total Paid"),
              const SizedBox(width: 10),
              _buildInfoBox(date, "Expiry Date"),
            ],
          ),
          if (!isActive) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Vacation Mode Active",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBox(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9C55E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.pause_circle_filled, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Going on Vacation?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Pause your subscriptions temporarily and save on billing",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _setVacationDates,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Set Vacation Dates",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomVacationDatePicker extends StatefulWidget {
  const CustomVacationDatePicker({super.key});

  @override
  State<CustomVacationDatePicker> createState() =>
      _CustomVacationDatePickerState();
}

class _CustomVacationDatePickerState extends State<CustomVacationDatePicker> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 15),
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Dates",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Tap to pick a start and end date for vacation",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                calendarFormat: CalendarFormat.month,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: const Color(
                    0xFFF9C55E,
                  ).withValues(alpha: 0.3),
                  rangeStartDecoration: const BoxDecoration(
                    color: Color(0xFFE5A000),
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Color(0xFFE5A000),
                    shape: BoxShape.circle,
                  ),
                  withinRangeTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.black),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_focusedDay, selectedDay)) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _rangeStart = selectedDay;
                      _rangeEnd = null;
                    });
                  }
                },
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: ElevatedButton(
                onPressed: (_rangeStart != null)
                    ? () {
                        Navigator.pop(
                          context,
                          DateTimeRange(
                            start: _rangeStart!,
                            end: _rangeEnd ?? _rangeStart!,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirm Schedule",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class SubscriptionSelectionBottomSheet extends StatefulWidget {
  final List<dynamic> subscriptions;
  final DateTimeRange dateRange;

  const SubscriptionSelectionBottomSheet({
    super.key,
    required this.subscriptions,
    required this.dateRange,
  });

  @override
  State<SubscriptionSelectionBottomSheet> createState() =>
      _SubscriptionSelectionBottomSheetState();
}

class _SubscriptionSelectionBottomSheetState
    extends State<SubscriptionSelectionBottomSheet> {
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Select all by default
    for (var s in widget.subscriptions) {
      _selectedIds.add(s['subscriptionId']);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedStart =
        "${widget.dateRange.start.day}/${widget.dateRange.start.month}/${widget.dateRange.start.year}";
    String formattedEnd =
        "${widget.dateRange.end.day}/${widget.dateRange.end.month}/${widget.dateRange.end.year}";

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 15),
            Center(
              child: Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Apply Vacation Mode",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Select the subscriptions to suspend between $formattedStart and $formattedEnd",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shrinkWrap: true,
                  itemCount: widget.subscriptions.length,
                  itemBuilder: (context, index) {
                    final s = widget.subscriptions[index];
                    final int subId = s['subscriptionId'];
                    bool isSelected = _selectedIds.contains(subId);

                    Color color = s['itemType'] == "Newspaper"
                        ? Colors.blue
                        : Colors.purple;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: color,
                        checkColor: Colors.white,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        title: Text(
                          s['itemName'] ?? "Unnamed Item",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          s['itemType'],
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(subId);
                            } else {
                              _selectedIds.remove(subId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
              child: ElevatedButton(
                onPressed: _selectedIds.isNotEmpty
                    ? () {
                        Navigator.pop(context, _selectedIds.toList());
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9C55E),
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Confirm Vacation",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
