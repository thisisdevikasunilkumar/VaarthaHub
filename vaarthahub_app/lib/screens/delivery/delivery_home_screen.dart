// ignore_for_file: avoid_unnecessary_containers

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../delivery/add_readers.dart';
import '../delivery/delievry_scrap_collection_screen.dart';
import '../delivery/delivery_profile_screen.dart';
import '../delivery/delivery_route_preview.dart';
import '../delivery/delivery_magazine_swap_screen.dart';
import '../delivery/delivery_vacation_mode_screen.dart';
import '../delivery/readers_management.dart';
import '../delivery/delivery_manage_bookings_screen.dart';
import '../settings screens/notifications_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _selectedIndex = 0;
  String? loggedPartnerCode;
  Map<String, dynamic>? partnerData;
  bool isLoading = true;
  bool hasReaders = true;
  int readerCount = 0;
  int vacationReaderCount = 0;
  int papersSavedTodayCount = 0;
  int magazineSwapCount = 0;
  int unreadNotifications = 0;
  int deliveryCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadPartnerCode();
  }

  Future<void> _loadPartnerCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedPartnerCode = prefs.getString('partnerCode') ?? "Unknown";
    });
    await fetchReaderProfile();
    await fetchReaders();
    await _fetchVacationDashboardSummary();
    await _fetchMagazineSwapCount();
    await _fetchDeliveryCount();
    _fetchUnreadCount();
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (loggedPartnerCode != null) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    if (loggedPartnerCode == null || loggedPartnerCode == "Unknown") return;
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Notifications/unread-count/$loggedPartnerCode",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            unreadNotifications = data['count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  Future<void> _fetchMagazineSwapCount() async {
    if (loggedPartnerCode == null || loggedPartnerCode == "Unknown") return;
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/SwapRequests/pending/$loggedPartnerCode",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            magazineSwapCount = data.length;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching swap count: $e");
    }
  }

  Future<void> _fetchDeliveryCount() async {
    if (loggedPartnerCode == null || loggedPartnerCode == "Unknown") return;
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/OtherProductBookings/GetPartnerBookings/$loggedPartnerCode",
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            deliveryCount = data.where((b) {
              final itemType = b['itemType']?.toString().toLowerCase() ?? '';
              return itemType.contains('calendar') ||
                  itemType.contains('diary');
            }).length;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching delivery count: $e");
    }
  }

  Future<void> fetchReaders() async {
    try {
      final url = Uri.parse(
        '${ApiConstants.baseUrl}/DeliveryPartner/GetMyReaders/$loggedPartnerCode',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;

        if (mounted) {
          setState(() {
            readerCount = data.length;
            hasReaders = data.isNotEmpty;
          });
        }
      }
    } catch (e) {
      debugPrint("Reader fetch error: $e");
    }
  }

  Future<void> _fetchVacationDashboardSummary() async {
    if (loggedPartnerCode == null || loggedPartnerCode == "Unknown") return;

    try {
      final dashboard = await fetchDeliveryVacationDashboard(
        loggedPartnerCode!,
      );

      if (!mounted) return;
      setState(() {
        vacationReaderCount = dashboard.readersOnVacationCount;
        papersSavedTodayCount = dashboard.papersSavedTodayCount;
      });
    } catch (e) {
      debugPrint("Vacation dashboard fetch error: $e");
    }
  }

  Future<void> fetchReaderProfile() async {
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/DeliveryPartner/GetDeliveryPartnerProfile/$loggedPartnerCode",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          partnerData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Widget> get _pages => [
    DeliveryHomeView(
      partnerData: partnerData,
      hasReaders: hasReaders,
      unreadCount: unreadNotifications,
      readerCount: readerCount,
      vacationReaderCount: vacationReaderCount,
      papersSavedTodayCount: papersSavedTodayCount,
      magazineSwapCount: magazineSwapCount,
      deliveryCount: deliveryCount,
      partnerCode: loggedPartnerCode ?? "Unknown",
      onRefreshNotifications: _fetchUnreadCount,
      onRefreshHome: () async {
        await Future.wait([
          fetchReaderProfile(),
          fetchReaders(),
          _fetchVacationDashboardSummary(),
          _fetchMagazineSwapCount(),
          _fetchDeliveryCount(),
          _fetchUnreadCount(),
        ]);
      },
    ),
    const ReadersManagement(),
    const DeliveryPartnerScrapManagementScreen(),
    DeliveryRoutePreview(
      partnerData: partnerData,
      readerCount: readerCount,
      vacationReaderCount: vacationReaderCount,
    ),
    DeliveryPartnerProfile(
      partnerCode: loggedPartnerCode?.toString() ?? "Unknown",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (loggedPartnerCode == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFF9C55E),
        unselectedItemColor: Colors.black,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          _navItem(Icons.home_filled, "Home", 0),
          _navItem(Icons.people_outline_rounded, "Users", 1),
          _navItem(Icons.recycling_rounded, "Scrap", 2),
          _navItem(Icons.location_on_outlined, "Route", 3),
          _navItem(Icons.person_outline_rounded, "Profile", 4),
        ],
      ),
    );
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBE1AE) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}

class DeliveryHomeView extends StatelessWidget {
  final Map<String, dynamic>? partnerData;
  final bool hasReaders;
  final int unreadCount;
  final int readerCount;
  final int vacationReaderCount;
  final int papersSavedTodayCount;
  final int magazineSwapCount;
  final int deliveryCount;
  final String partnerCode;
  final VoidCallback onRefreshNotifications;
  final Future<void> Function() onRefreshHome;

  const DeliveryHomeView({
    super.key,
    this.partnerData,
    this.hasReaders = true,
    this.unreadCount = 0,
    this.readerCount = 0,
    this.vacationReaderCount = 0,
    this.papersSavedTodayCount = 0,
    this.magazineSwapCount = 0,
    this.deliveryCount = 0,
    required this.partnerCode,
    required this.onRefreshNotifications,
    required this.onRefreshHome,
  });

  @override
  Widget build(BuildContext context) {
    final activeReaders = readerCount - vacationReaderCount;

    return RefreshIndicator(
      color: const Color(0xFFF9C55E),
      onRefresh: onRefreshHome,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/ui_elements/element4.png',
                  width: double.infinity,
                  fit: BoxFit.fill,
                ),
                _buildHeader(context),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                children: [
                  _buildHeroBoard(context, activeReaders),
                  const SizedBox(height: 18),
                  _buildQuickActions(context),
                  const SizedBox(height: 18),
                  _buildTodayRouteCard(),
                  const SizedBox(height: 18),
                  _buildOverviewGrid(context, activeReaders, deliveryCount),
                  const SizedBox(height: 18),
                  _buildTaskBoard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topInset + 26, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/logo/vaarthaHub-resolution-logo.png',
                height: 45,
              ),
              Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(
                            userCode:
                                partnerData?['partnerCode']?.toString() ?? '1',
                          ),
                        ),
                      ).then((_) => onRefreshNotifications());
                    },
                    icon: const Icon(
                      Icons.notifications_none_outlined,
                      size: 30,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            "Hello, ${partnerData?['fullName'] ?? 'Partner'}!",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              fontFamily: 'Cursive',
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBoard(BuildContext context, int activeReaders) {
    final panchayat = (partnerData?['panchayatName'] ?? 'Assigned Panchayat')
        .toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF9C55E), Color(0xFFFBE1AE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF9C55E).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            size: 14,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "Today's Dispatch",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Your morning route\nis ready for delivery!",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$panchayat • $activeReaders active drops",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _heroStatCard(
                        "Readers",
                        "$readerCount",
                        "assigned",
                        const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _heroStatCard(
                        "Alerts",
                        "$unreadCount",
                        "pending",
                        const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: -15,
            top: -15,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0),
    );
  }

  Widget _heroStatCard(String title, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context, int activeReaders, int deliveryCount) {
    final cards = [
      _DeliveryMetricCard(
        title: "Active Readers",
        value: "$activeReaders",
        subtitle: "Today's newspaper delivery",
        icon: Icons.groups_2_outlined,
        iconColor: const Color(0xFF2563EB),
        background: const Color(0xFFEAF2FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReadersManagement()),
          );
        },
      ),
      _DeliveryMetricCard(
        title: "Vacation Mode",
        value: "$vacationReaderCount",
        subtitle: "$papersSavedTodayCount papers saved today",
        icon: Icons.beach_access_rounded,
        iconColor: const Color(0xFFF97316),
        background: const Color(0xFFFFF7ED),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DeliveryVacationModeScreen(partnerCode: partnerCode),
            ),
          );
        },
      ),
      _DeliveryMetricCard(
        title: "Scrap Leads",
        value: hasReaders ? "06" : "00",
        subtitle: "Pickup opportunities",
        icon: Icons.recycling_outlined,
        iconColor: const Color(0xFF0E9F6E),
        background: const Color(0xFFEAFBF1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const DeliveryPartnerScrapManagementScreen(),
            ),
          );
        },
      ),
      _DeliveryMetricCard(
        title: "Today's Route",
        value: hasReaders ? "4.8 km" : "0 km",
        subtitle: "Optimized street loop",
        icon: Icons.alt_route_rounded,
        iconColor: const Color(0xFF7C3AED),
        background: const Color(0xFFF5EEFF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryRoutePreview(
                partnerData: partnerData,
                readerCount: readerCount,
                vacationReaderCount: vacationReaderCount,
              ),
            ),
          );
        },
      ),
      _DeliveryMetricCard(
        title: "Pending Alerts",
        value: "$unreadCount",
        subtitle: "Notifications to review",
        icon: Icons.notifications_active_outlined,
        iconColor: const Color(0xFFE11D48),
        background: const Color(0xFFFFEFF3),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(userCode: partnerCode),
            ),
          ).then((_) => onRefreshNotifications());
        },
      ),
      _DeliveryMetricCard(
        title: "My Deliveries",
        value: "$deliveryCount",
        subtitle: "Assigned items",
        icon: Icons.calendar_today_rounded,
        iconColor: const Color(0xFF0D9488),
        background: const Color(0xFFF0FDFA),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DeliveryManageBookingsScreen(partnerCode: partnerCode),
            ),
          );
        },
      ),
      _DeliveryMetricCard(
        title: "Magazine Swaps",
        value: "$magazineSwapCount",
        subtitle: "Pending requests",
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF6366F1),
        background: const Color(0xFFF0F9FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DeliveryMagazineSwapScreen(),
            ),
          ).then((_) => onRefreshHome());
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 168,
        ),
        itemBuilder: (context, index) {
          final item = cards[index];
          return Container(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF2F4F7)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: item.background,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  item.icon,
                                  color: item.iconColor,
                                  size: 20,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: item.iconColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .animate(delay: Duration(milliseconds: 60 * index))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.12, end: 0);
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _DeliveryQuickAction(
        title: "Add Reader",
        subtitle: "expand your route list",
        icon: Icons.person_add_alt_1_outlined,
        color: const Color(0xFFEAF2FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddReaders()),
          );
        },
      ),
      _DeliveryQuickAction(
        title: "My Readers",
        subtitle: "check subscriptions",
        icon: Icons.people_outline_rounded,
        color: const Color(0xFFEAFBF1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReadersManagement()),
          );
        },
      ),
      _DeliveryQuickAction(
        title: "Scrap Pickup",
        subtitle: "manage collection requests",
        icon: Icons.delete_sweep_outlined,
        color: const Color(0xFFFFF4D8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const DeliveryPartnerScrapManagementScreen(),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(actions.length, (index) {
              final action = actions[index];
              return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == actions.length - 1 ? 0 : 12,
                    ),
                    child: InkWell(
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 18,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: action.color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(action.icon),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    action.subtitle,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 90 * index))
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: 0.08, end: 0);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayRouteCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4D7), Color(0xFFFFE7BF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.route_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Route Suggestion",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Shortest and smoothest path for the morning delivery.",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const RouteProgressLine(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _routeFact(
                    "Start",
                    partnerData?['panchayatName']?.toString() ?? "Panchayat",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _routeFact("ETA", "06:15 AM")),
                const SizedBox(width: 12),
                Expanded(child: _routeFact("Stops", "$readerCount drops")),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms, delay: 120.ms).slideY(begin: 0.08, end: 0),
    );
  }

  Widget _routeFact(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBoard(BuildContext context) {
    final items = <_DeliveryTaskItem>[
      if (!hasReaders)
        _DeliveryTaskItem(
          title: "Add your first readers",
          subtitle: "Build the allotted panchayat delivery list.",
          color: const Color(0xFFEAF2FF),
          icon: Icons.person_add_alt_rounded,
          actionLabel: "Add Reader",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddReaders()),
            );
          },
        ),
      _DeliveryTaskItem(
        title: "Check unread notifications",
        subtitle: unreadCount > 0
            ? "$unreadCount alerts need your attention."
            : "No pending alerts right now.",
        color: const Color(0xFFFFF4D8),
        icon: Icons.notifications_active_outlined,
        actionLabel: "Open Alerts",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationsScreen(
                userCode: partnerData?['partnerCode']?.toString() ?? '1',
              ),
            ),
          ).then((_) => onRefreshNotifications());
        },
      ),
      _DeliveryTaskItem(
        title: "Scrap extra income",
        subtitle: "Keep collection requests moving for bonus earnings.",
        color: const Color(0xFFEAFBF1),
        icon: Icons.currency_rupee_rounded,
        actionLabel: "View Scrap",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const DeliveryPartnerScrapManagementScreen(),
            ),
          );
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Daily Board",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Container(
                    margin: EdgeInsets.only(
                      bottom: index == items.length - 1 ? 0 : 12,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(item.icon),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: item.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            item.actionLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 100 * index))
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.08, end: 0);
            }),
          ),
        ],
      ),
    );
  }
}

class RouteProgressLine extends StatelessWidget {
  const RouteProgressLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _node(true),
        _bar(),
        _node(false),
        _bar(),
        _node(false),
        _bar(),
        _node(true),
      ],
    );
  }

  Widget _node(bool active) => Container(
    height: 10,
    width: 10,
    decoration: BoxDecoration(
      color: active ? const Color(0xFFF9C55E) : Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFF9C55E), width: 2),
    ),
  );

  Widget _bar() => Expanded(
    child: Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9C55E).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _DeliveryMetricCard {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final VoidCallback? onTap;

  _DeliveryMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.background,
    this.onTap,
  });
}

class _DeliveryQuickAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _DeliveryQuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _DeliveryTaskItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  _DeliveryTaskItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });
}
