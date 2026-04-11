import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../admin/add_publications_screen.dart';
import 'package:vaarthahub_app/services/api_service.dart';
import 'package:vaarthahub_app/models/newspaper.dart';
import 'package:vaarthahub_app/models/magazine.dart';

class ManagePublicationsScreen extends StatefulWidget {
  const ManagePublicationsScreen({super.key});

  @override
  State<ManagePublicationsScreen> createState() =>
      _ManagePublicationsScreenState();
}

class _ManagePublicationsScreenState extends State<ManagePublicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = "All";
  bool isNewspaperTab = true;
  bool _isLoading = true;
  List<Newspaper> _newspapers = [];
  List<Magazine> _magazines = [];

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
    _fetchPublications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPublications() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final newsUrl = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetNewspapers',
      );
      final newsRes = await http.get(newsUrl);
      if (newsRes.statusCode == 200) {
        _newspapers = (jsonDecode(newsRes.body) as List)
            .map((i) => Newspaper.fromJson(i))
            .toList();
        // Sort alphabetically by name
        _newspapers.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      }

      final magUrl = Uri.parse(
        '${ApiConstants.baseUrl}/Publications/GetMagazines',
      );
      final magRes = await http.get(magUrl);
      if (magRes.statusCode == 200) {
        _magazines = (jsonDecode(magRes.body) as List)
            .map((i) => Magazine.fromJson(i))
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
                _buildAppBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionHeader(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Newspaper Tab
                      RefreshIndicator(
                        onRefresh: _fetchPublications,
                        color: const Color(0xFFF9C55E),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildCategoryFilters(),
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 50),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF9C55E),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                              ..._buildFilteredNewspapers(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      // Magazine Tab
                      RefreshIndicator(
                        onRefresh: _fetchPublications,
                        color: const Color(0xFFF9C55E),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildCategoryFilters(),
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 50),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFF9C55E),
                                  ),
                                )
                              else
                                const SizedBox(height: 20),
                              ..._buildFilteredMagazines(),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
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
      "Education": {"icon": Icons.school, "color": Colors.purple},
      "English": {"icon": Icons.language, "color": Colors.orange},
      "Evening Dailies": {
        "icon": Icons.wb_twilight,
        "color": Colors.amberAccent,
      },
      "General": {"icon": Icons.newspaper, "color": Colors.blue},
      "Political": {"icon": Icons.account_balance, "color": Colors.redAccent},
      "Specials": {"icon": Icons.star_border, "color": Colors.teal},
    };

    int totalItems = 0;
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
            final int index = totalItems++;
            String name = item.name;
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
              child: _buildSubscriptionGridItem(
                title: name,
                subtitle: "$category • ${item.paperType}",
                price: "₹ ${(item.basePrice).toStringAsFixed(2)}",
                logoBase64: item.logoUrl,
                logoLetter: name.isNotEmpty ? name[0].toUpperCase() : "N",
                color: color.shade50,
                borderColor: color,
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddPublicationsScreen(editNewspaper: item),
                    ),
                  );
                  _fetchPublications();
                },
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
      "Automobile": {"icon": Icons.directions_car, "color": Colors.indigo},
      "Career": {"icon": Icons.work_outline, "color": Colors.blueGrey},
      "Children": {
        "icon": Icons.sentiment_satisfied_alt,
        "color": Colors.purple,
      },
      "Education": {"icon": Icons.school, "color": Colors.cyan},
      "English": {"icon": Icons.language, "color": Colors.orange},
      "Family": {"icon": Icons.family_restroom, "color": Colors.teal},
      "Farming": {"icon": Icons.agriculture, "color": Colors.green},
      "Finance": {"icon": Icons.payments_outlined, "color": Colors.blue},
      "Food": {"icon": Icons.restaurant, "color": Colors.amber[900]},
      "General Knowledge": {
        "icon": Icons.lightbulb_outline,
        "color": Colors.brown[400],
      },
      "Health": {"icon": Icons.favorite_border, "color": Colors.pink},
      "Lifestyle": {"icon": Icons.style, "color": Colors.deepPurple},
      "Literary": {"icon": Icons.menu_book, "color": Colors.lime[900]},
      "Sports": {"icon": Icons.sports_basketball, "color": Colors.redAccent},
      "Travel": {"icon": Icons.map, "color": Colors.deepOrange},
      "Weekly": {"icon": Icons.view_week, "color": Colors.lightGreen},
      "Women": {"icon": Icons.woman, "color": Colors.pinkAccent},
    };

    int totalItems = 0;
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
            final int index = totalItems++;
            String name = item.name;
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
              child: _buildSubscriptionGridItem(
                title: name,
                subtitle: "$category • ${item.publicationCycle}",
                price: "₹ ${(item.price).toStringAsFixed(2)}",
                logoBase64: item.logoUrl,
                logoLetter: name.isNotEmpty ? name[0].toUpperCase() : "M",
                color: color.shade50,
                borderColor: color,
                onEdit: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddPublicationsScreen(editMagazine: item),
                    ),
                  );
                  _fetchPublications();
                },
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
          "Manage Subscriptions",
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
              Tab(text: "Newspapers"),
              Tab(text: "Magazines"),
            ],
          ),
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddPublicationsScreen(initialIsNewspaper: isNewspaperTab),
              ),
            );
            _fetchPublications(); // Reload active entries after pop
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
    required VoidCallback onEdit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        // ignore: deprecated_member_use
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1.5),
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
                    color: borderColor.withOpacity(0.8),
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
              onPressed: onEdit,
              style: ElevatedButton.styleFrom(
                // ignore: deprecated_member_use
                backgroundColor: borderColor.withOpacity(0.1),
                foregroundColor: borderColor,
                elevation: 0,
                minimumSize: const Size(double.infinity, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    // ignore: deprecated_member_use
                    color: borderColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Edit Details",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      // ignore: deprecated_member_use
                      color: borderColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
