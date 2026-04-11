import 'package:flutter/material.dart';

import '../reader/remembrance_ad_screen.dart';
import '../reader/anniversarygreetings_ad_screen.dart';
import '../reader/birthdaywishes _ad_screen.dart';

import '../reader/readers_corner.dart';
import '../reader/magazine_swap_screen.dart';
import '../reader/browse_other_products_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _filterSearch(String query) {}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Curved Background Element
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/ui_elements/element5.png',
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  Container(height: 160, color: const Color(0xFFFDEBB7)),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),

                        // Newspaper Section
                        _buildSectionHeader('Newspaper Subscription'),
                        const SizedBox(height: 15),
                        _buildLogoRow([
                          {
                            'name': 'Manorama',
                            'img': 'assets/categories/Manorama logo.jpg',
                          },
                          {
                            'name': 'Mathrubhumi',
                            'img': 'assets/categories/Mathrubhumi logo.png',
                          },
                          {
                            'name': 'Deshabhimani',
                            'img': 'assets/categories/Deshabhimani logo.png',
                          },
                          {
                            'name': 'Deepika',
                            'img': 'assets/categories/Deepika logo.png',
                          },
                        ]),
                        _buildViewAll(),

                        // Magazine Section
                        _buildSectionHeader('Magazine Subscription'),
                        const SizedBox(height: 15),
                        _buildLogoRow([
                          {
                            'name': 'Vanitha',
                            'img': 'assets/categories/Vanitha logo.png',
                          },
                          {
                            'name': 'Grihalakshmi',
                            'img': 'assets/categories/Grihalakshmi logo.jpg',
                          },
                          {
                            'name': 'Balarama',
                            'img': 'assets/categories/Balarama logo.png',
                          },
                          {
                            'name': 'Balabhumi',
                            'img': 'assets/categories/Balabhumi logo.jpg',
                          },
                        ]),
                        _buildViewAll(),

                        // --- ANNOUNCEMENT SECTION ---
                        _buildSectionHeader('Announcement'),
                        const SizedBox(height: 15),
                        _buildAnnouncementRow(),
                        _buildCreateCustomAds(),

                        // Community Section
                        const SizedBox(height: 30),
                        _buildSectionHeader('Community'),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25.0),
                          child: _buildCommunityGrid(),
                        ),
                        const SizedBox(height: 50),
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

  // --- Header Section ---
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(25, 20, 20, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categories",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch,
        decoration: InputDecoration(
          hintText: "Search by ",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F1F1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }

  Widget _buildLogoRow(List<Map<String, String>> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: items.map((item) {
          return Container(
            margin: const EdgeInsets.only(right: 15, bottom: 10, top: 5),
            width: 95,
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(40),
                bottomLeft: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(item['img']!, height: 50, fit: BoxFit.contain),
                const SizedBox(height: 8),
                Text(
                  item['name']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildViewAll() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text(
          'View All >',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCustomAds() {
    return Center(
      child: TextButton(
        onPressed: () {},
        child: const Text(
          '+ Create Custom Ad\'s >',
          style: TextStyle(
            color: Color(0xFF4A4A4A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildAnnounceCard(
            'Remembrance',
            'assets/categories/Obituaries.png',
            const Color(0xFFFFB5B5),
            const Color(0xFFFEEAE8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RemembranceAdScreen(),
                ),
              );
            },
          ),
          _buildAnnounceCard(
            'Anniversary Greetings',
            'assets/categories/Anniversary Greetings.png',
            const Color(0xFFFFD98E),
            const Color(0xFFFFF9E7),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnniversaryGreetingsAdScreen(),
                ),
              );
            },
          ),
          _buildAnnounceCard(
            'Birthday Wishes',
            'assets/categories/Birthday Wishes.png',
            const Color(0xFFADCFFF),
            const Color(0xFFF2F5FE),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BirthdayWishesAdScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnounceCard(
    String title,
    String img,
    Color curveColor,
    Color cardBg, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        height: 200,
        margin: const EdgeInsets.only(right: 15, bottom: 25),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: curveColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 10,
              right: 10,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
            Positioned(
              top: 55,
              child: SizedBox(
                height: 130,
                width: 130,
                child: Image.asset(img, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              bottom: -22,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: title == 'Remembrance'
                        ? const Color(0xFFFEEAE8)
                        : title == 'Anniversary Greetings'
                        ? const Color(0xFFFFF9E7)
                        : const Color(0xFFF2F5FE),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.78,
      crossAxisSpacing: 15,
      mainAxisSpacing: 50,
      children: [
        _buildCommTile(
          "Reader's Corner",
          "Add Articles",
          const Color(0xFFFFF9E7),
          const Color(0xFFFFD98E),
          'assets/categories/Reader\'s Corner.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReadersCornerScreen(),
              ),
            );
          },
        ),
        _buildCommTile(
          "Kids Profiles",
          "Add Now",
          const Color(0xFFFAE3FF),
          const Color(0xFFB267C2),
          'assets/categories/Kids Profiles.png',
          // onTap: () {
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => const MagazineSwapScreen(),
          //     ),
          //   );
          // },
        ),
        _buildCommTile(
          "Magazine Swap",
          "Swap Now",
          const Color(0xFFC8F5C8),
          const Color(0xFF64B345),
          'assets/categories/Magazine Swap.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MagazineSwapScreen(),
              ),
            );
          },
        ),
        _buildCommTile(
          "Calendar/Diary",
          "Book Now",
          const Color(0xFFF2F5FE),
          const Color(0xFFADCFFF),
          'assets/categories/Calendar Dairy.png',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BrowseOtherProductsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommTile(
    String title,
    String btnText,
    Color bg,
    Color curveColor,
    String img, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: curveColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(55),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(child: Image.asset(img, fit: BoxFit.contain)),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: title == "Reader's Corner"
                      ? const Color(0xFFFFF9E7)
                      : title == "Kids Profiles"
                      ? const Color(0xFFFAE3FF)
                      : title == "Magazine Swap"
                      ? const Color(0xFFC8F5C8)
                      : const Color(0xFFF2F5FE),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  btnText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
