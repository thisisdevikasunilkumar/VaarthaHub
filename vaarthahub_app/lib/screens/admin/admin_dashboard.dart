import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaarthahub_app/services/api_service.dart';

import '../settings screens/notifications_screen.dart';
import 'add_delivery_partner.dart';
import 'add_design_frames_screen.dart';
import 'add_other_product_screen.dart';
import 'add_publications_screen.dart';
import 'admin_profile_screen.dart';
import 'announcement_approvals_screen.dart';
import 'package:vaarthahub_app/screens/admin/manage_bookings_screen.dart';
import 'package:vaarthahub_app/screens/admin/manage_calendar_dairy_screen.dart';
import 'package:vaarthahub_app/screens/admin/manage_subscriptions_screen.dart';
import 'readers_vacation_mode_screen.dart';
import 'management_screen.dart';
import 'system_configuration_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  int unreadNotifications = 0;
  Timer? _notificationTimer;
  String? adminCode;
  bool _isLoadingDashboard = true;
  AdminDashboardStats _stats = const AdminDashboardStats();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (adminCode != null) {
        _fetchUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    adminCode = prefs.getString('adminCode') ?? 'Admin';
    if (mounted) {
      setState(() {});
    }
    await Future.wait([_fetchUnreadCount(), _loadDashboardStats()]);
  }

  Future<void> _fetchUnreadCount() async {
    if (adminCode == null) return;
    try {
      final url = Uri.parse(
        "${ApiConstants.baseUrl}/Notifications/unread-count/$adminCode",
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

  Future<void> _loadDashboardStats() async {
    if (mounted) {
      setState(() => _isLoadingDashboard = true);
    }

    try {
      final results = await Future.wait<dynamic>([
        _getList('/Admin/GetDeliveryPartners'),
        _getList('/Admin/GetReaders'),
        _getList('/Publications/GetNewspapers'),
        _getList('/Publications/GetMagazines'),
        _getList('/OtherProducts'),
        _getList('/DesignFrames'),
        _getList('/Complaints/GetAllComplaints'),
        _getVacationCount(),
      ]);

      final partners = results[0] as List<dynamic>;
      final readers = results[1] as List<dynamic>;
      final newspapers = results[2] as List<dynamic>;
      final magazines = results[3] as List<dynamic>;
      final otherProducts = results[4] as List<dynamic>;
      final designFrames = results[5] as List<dynamic>;
      final complaints = results[6] as List<dynamic>;
      final vacationReadersCount = results[7] as int;

      final activePartners = partners.where((partner) {
        final status = (partner['status'] ?? '').toString().toLowerCase();
        return status == 'delivering' || status == 'active';
      }).length;

      final activeReaders = readers.where((reader) {
        final status = (reader['status'] ?? '').toString().toLowerCase();
        return status == 'active';
      }).length;

      final vacationReaders = vacationReadersCount;

      final calendars = otherProducts.where(
        (item) =>
            item['itemId'] == 3 ||
            (item['itemType'] ?? '').toString().toLowerCase().contains(
              'calendar',
            ),
      );

      final diaries = otherProducts.where(
        (item) =>
            item['itemId'] == 4 ||
            (item['itemType'] ?? '').toString().toLowerCase().contains('diary'),
      );

      final highPriorityComplaints = complaints.where((complaint) {
        final type = (complaint['complaintType'] ?? '')
            .toString()
            .toLowerCase();
        return type.contains('missing') ||
            type.contains('late') ||
            type.contains('damage');
      }).length;

      final today = DateTime.now();
      final recentReaders = readers.where((reader) {
        final createdAt = reader['createdAt'];
        if (createdAt == null) return false;
        final parsedDate = DateTime.tryParse(createdAt.toString());
        if (parsedDate == null) return false;
        return today.difference(parsedDate).inDays <= 7;
      }).length;

      final monthlyPayout = partners.fold<double>(0, (sum, partner) {
        final monthly = (partner['totalMonthlyEarnings'] as num?)?.toDouble();
        final basic = (partner['basicSalary'] as num?)?.toDouble() ?? 0;
        return sum + (monthly != null && monthly > 0 ? monthly : basic);
      });

      final topPartners =
          List<Map<String, dynamic>>.from(
            partners.map((item) => Map<String, dynamic>.from(item as Map)),
          )..sort((a, b) {
            final ratingA = (a['averageRating'] as num?)?.toDouble() ?? 0;
            final ratingB = (b['averageRating'] as num?)?.toDouble() ?? 0;
            return ratingB.compareTo(ratingA);
          });

      final recentComplaints =
          List<Map<String, dynamic>>.from(
            complaints.map((item) => Map<String, dynamic>.from(item as Map)),
          )..sort((a, b) {
            final dateA = DateTime.tryParse((a['createdAt'] ?? '').toString());
            final dateB = DateTime.tryParse((b['createdAt'] ?? '').toString());
            return (dateB ?? DateTime(2000)).compareTo(dateA ?? DateTime(2000));
          });

      if (mounted) {
        setState(() {
          _stats = AdminDashboardStats(
            totalPartners: partners.length,
            activePartners: activePartners,
            totalReaders: readers.length,
            activeReaders: activeReaders,
            vacationReaders: vacationReaders,
            newspaperCount: newspapers.length,
            magazineCount: magazines.length,
            calendarCount: calendars.length,
            diaryCount: diaries.length,
            designFrameCount: designFrames.length,
            complaintCount: complaints.length,
            highPriorityComplaintCount: highPriorityComplaints,
            recentReadersCount: recentReaders,
            monthlyPayout: monthlyPayout,
            dailyPayout: monthlyPayout / 30,
            topPartners: topPartners.take(3).toList(),
            recentComplaints: recentComplaints.take(3).toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Dashboard stats load error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDashboard = false);
      }
    }
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}$path'));
    if (response.statusCode != 200) {
      return [];
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<int> _getVacationCount() async {
    try {
      final endpoint =
          "${ApiConstants.baseUrl}/Subscriptions/GetVacationModeData";
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentVacations =
            (data['currentVacations'] ?? data['currentlyOnVacation']) as List?;
        if (currentVacations != null) {
          // Identify unique readers currently on vacation
          final readerIds = <dynamic>{};
          for (final item in currentVacations) {
            final rid = item['readerId'];
            if (rid != null && rid != 0) {
              readerIds.add(rid);
            } else {
              // Fallback to name if ID is missing (less accurate but better than 0)
              final name = item['readerName'] ?? item['fullName'];
              if (name != null) readerIds.add(name);
            }
          }
          return readerIds.length;
        }
      }
    } catch (e) {
      debugPrint("Error fetching vacation count: $e");
    }
    return 0;
  }

  List<Widget> get _adminScreens => [
    DashboardHomeView(
      unreadCount: unreadNotifications,
      adminCode: adminCode,
      isLoading: _isLoadingDashboard,
      stats: _stats,
      onRefreshNotifications: _fetchUnreadCount,
      onRefreshDashboard: _loadDashboardStats,
      onNavigateToTab: (index) => setState(() => _selectedIndex = index),
    ),
    const ManagementScreen(),
    const AnnouncementApprovalsScreen(),
    const Center(child: Text("Analytics")),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(index: _selectedIndex, children: _adminScreens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
        ],
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
          _navItem(Icons.grid_view_rounded, "Dashboard", 0),
          _navItem(Icons.people_outline, "Management", 1),
          _navItem(Icons.campaign_outlined, "Ads", 2),
          _navItem(Icons.analytics_outlined, "Analytics", 3),
          _navItem(Icons.account_circle_outlined, "Profile", 4),
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

class DashboardHomeView extends StatelessWidget {
  final int unreadCount;
  final String? adminCode;
  final bool isLoading;
  final AdminDashboardStats stats;
  final VoidCallback onRefreshNotifications;
  final Future<void> Function() onRefreshDashboard;
  final ValueChanged<int> onNavigateToTab;

  const DashboardHomeView({
    super.key,
    required this.unreadCount,
    required this.adminCode,
    required this.isLoading,
    required this.stats,
    required this.onRefreshNotifications,
    required this.onRefreshDashboard,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFF9C55E),
      onRefresh: () async {
        onRefreshNotifications();
        await onRefreshDashboard();
      },
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
                  const SizedBox(height: 8),
                  _buildOverviewHero(),
                  const SizedBox(height: 20),
                  _buildActivityPanels(),
                  const SizedBox(height: 20),
                  _buildAttentionSection(context),
                  const SizedBox(height: 20),
                  _buildPrimaryMetrics(),
                  const SizedBox(height: 20),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),
                  _buildOperationsStrip(),
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
      padding: EdgeInsets.fromLTRB(20, topInset + 28, 20, 18),
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
                            userCode: adminCode ?? 'Admin',
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
          const SizedBox(height: 26),
          const Text(
            "Hello, Admin!",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewHero() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4D6), Color(0xFFFCE2C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  "Operations Health",
                  "${stats.activePartners}/${stats.totalPartners}",
                  "partners active now",
                  const Color(0xFF0E9F6E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroStat(
                  "Reader Pulse",
                  "${stats.activeReaders}",
                  "${stats.vacationReaders} currently on vacation",
                  const Color(0xFFB7791F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniInfoChip(
                  Icons.notification_important_outlined,
                  "$unreadCount unread notifications",
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfoChip(
                  Icons.report_gmailerrorred_outlined,
                  "${stats.highPriorityComplaintCount} priority complaints",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(
    String title,
    String value,
    String subtitle,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5D9A6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _miniInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF9C55E), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryMetrics() {
    final cards = [
      _MetricCardData(
        title: "Readers",
        value: "${stats.totalReaders}",
        subtitle: "${stats.recentReadersCount} new this week",
        icon: Icons.groups_2_outlined,
        color: const Color(0xFFE9F2FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _MetricCardData(
        title: "Partners",
        value: "${stats.totalPartners}",
        subtitle: "${stats.activePartners} active now",
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFFEAFBF1),
        iconColor: const Color(0xFF0E9F6E),
      ),
      _MetricCardData(
        title: "Vacation",
        value: "${stats.vacationReaders}",
        subtitle: "paused deliveries",
        icon: Icons.beach_access_outlined,
        color: const Color(0xFFFFF1F2),
        iconColor: const Color(0xFFE11D48),
      ),
      _MetricCardData(
        title: "Routes",
        value: "${stats.activePartners}",
        subtitle: "running today",
        icon: Icons.route_outlined,
        color: const Color(0xFFF5EEFF),
        iconColor: const Color(0xFF7C3AED),
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
          mainAxisExtent: 178,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          final cardWidget = Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: card.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(card.icon, color: card.iconColor, size: 20),
                    ),
                    const Spacer(),
                    Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: card.iconColor.withValues(alpha: 0.28),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      height: 8,
                      width: 8,
                      decoration: BoxDecoration(
                        color: card.iconColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  card.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: card.iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );

          // Make Vacation card clickable
          if (card.title == "Vacation") {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadersVacationModeScreen(),
                  ),
                );
              },
              child: cardWidget,
            );
          }

          return cardWidget;
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _DashboardAction(
        title: "Subscriptions",
        subtitle: "Newspapers and magazines",
        icon: Icons.newspaper_outlined,
        color: const Color(0xFFE9F2FF),
        onTap: () => _openPage(context, const ManageSubscriptionsScreen()),
      ),
      _DashboardAction(
        title: "Approvals",
        subtitle: "Ads and article queue",
        icon: Icons.campaign_outlined,
        color: const Color(0xFFFFF4D8),
        onTap: () => onNavigateToTab(2),
      ),
      _DashboardAction(
        title: "Manage Bookings",
        subtitle: "Calendar and diary orders",
        icon: Icons.book_online_outlined,
        color: const Color(0xFFEAFBF1),
        onTap: () => _openPage(context, const ManageBookingsScreen()),
      ),
      _DashboardAction(
        title: "Scrap Management",
        subtitle: "Track and manage returns",
        icon: Icons.recycling_outlined,
        color: const Color(0xFFFFF1F2),
        onTap: () => _openPage(context, const ManageCalendarDairyScreen()),
      ),
      _DashboardAction(
        title: "Frames",
        subtitle: "Template catalog",
        icon: Icons.dashboard_customize_outlined,
        color: const Color(0xFFF5EEFF),
        onTap: () => _openPage(context, const AddDesignFramesScreen()),
      ),
      _DashboardAction(
        title: "System",
        subtitle: "App configuration",
        icon: Icons.settings_suggest_outlined,
        color: const Color(0xFFE8FBFC),
        onTap: () => _openPage(context, const SystemConfigurationScreen()),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: action.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: action.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(action.icon, size: 24, color: Colors.black87),
                      const Spacer(),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsStrip() {
    final items = [
      _OpsItem("News", stats.newspaperCount, Icons.feed_outlined),
      _OpsItem("Magazine", stats.magazineCount, Icons.menu_book_outlined),
      _OpsItem("Calendar", stats.calendarCount, Icons.calendar_month_outlined),
      _OpsItem("Diary", stats.diaryCount, Icons.bookmarks_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((item) {
            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: const Color(0xFFB7791F)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${item.value}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivityPanels() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _panelCard(
            title: "Top Delivery Partners",
            subtitle: "Best rated team members right now",
            child: isLoading
                ? const _InlineLoader()
                : stats.topPartners.isEmpty
                ? const _EmptyPanel(message: "No partner data available")
                : Column(
                    children: stats.topPartners.map((partner) {
                      final rating =
                          (partner['averageRating'] as num?)?.toDouble() ?? 0;
                      final status = (partner['status'] ?? 'Unknown')
                          .toString();
                      return _listTileRow(
                        icon: Icons.local_shipping_outlined,
                        title: (partner['fullName'] ?? 'Partner').toString(),
                        subtitle:
                            "${partner['panchayatName'] ?? 'No area'} • $status",
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4D8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _panelCard(
            title: "Complaint Watch",
            subtitle: "Latest issue stream from the field",
            child: isLoading
                ? const _InlineLoader()
                : stats.recentComplaints.isEmpty
                ? const _EmptyPanel(message: "No complaints reported")
                : Column(
                    children: stats.recentComplaints.map((complaint) {
                      final createdAt = DateTime.tryParse(
                        (complaint['createdAt'] ?? '').toString(),
                      );
                      return _listTileRow(
                        icon: Icons.report_problem_outlined,
                        iconColor: Colors.red,
                        title: (complaint['complaintType'] ?? 'Complaint')
                            .toString(),
                        subtitle:
                            "${complaint['readerName'] ?? 'Reader'} against ${complaint['partnerName'] ?? 'partner'}",
                        trailing: Text(
                          _formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF5DE), Color(0xFFFCE2D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Action Center",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              unreadCount > 0
                  ? "You have $unreadCount unread notifications and ${stats.highPriorityComplaintCount} priority issues to review."
                  : "Everything looks stable. Review approvals and keep the catalog updated.",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _pillButton(
                  label: "Add Partners",
                  onTap: () => _openPage(context, const AddDeliveryPartner()),
                ),
                _pillButton(
                  label: "Add Publication",
                  onTap: () =>
                      _openPage(context, const AddPublicationsScreen()),
                ),
                _pillButton(
                  label: "Add Product",
                  onTap: () =>
                      _openPage(context, const AddOtherProductScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _listTileRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color iconColor = const Color(0xFF111827),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailing,
        ],
      ),
    );
  }

  Widget _pillButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _openPage(BuildContext context, Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    await onRefreshDashboard();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class AdminDashboardStats {
  final int totalPartners;
  final int activePartners;
  final int totalReaders;
  final int activeReaders;
  final int vacationReaders;
  final int newspaperCount;
  final int magazineCount;
  final int calendarCount;
  final int diaryCount;
  final int designFrameCount;
  final int complaintCount;
  final int highPriorityComplaintCount;
  final int recentReadersCount;
  final double monthlyPayout;
  final double dailyPayout;
  final List<Map<String, dynamic>> topPartners;
  final List<Map<String, dynamic>> recentComplaints;

  const AdminDashboardStats({
    this.totalPartners = 0,
    this.activePartners = 0,
    this.totalReaders = 0,
    this.activeReaders = 0,
    this.vacationReaders = 0,
    this.newspaperCount = 0,
    this.magazineCount = 0,
    this.calendarCount = 0,
    this.diaryCount = 0,
    this.designFrameCount = 0,
    this.complaintCount = 0,
    this.highPriorityComplaintCount = 0,
    this.recentReadersCount = 0,
    this.monthlyPayout = 0,
    this.dailyPayout = 0,
    this.topPartners = const [],
    this.recentComplaints = const [],
  });
}

class _MetricCardData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;

  _MetricCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}

class _DashboardAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _DashboardAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _OpsItem {
  final String label;
  final int value;
  final IconData icon;

  _OpsItem(this.label, this.value, this.icon);
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E))),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;

  const _EmptyPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.black54, fontSize: 13),
      ),
    );
  }
}
