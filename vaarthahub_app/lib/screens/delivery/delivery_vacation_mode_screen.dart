import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/delivery_vacation_dashboard_data.dart';
import '../../models/delivery_vacation_reader.dart';
import '../../services/api_service.dart';

Future<DeliveryVacationDashboardData> fetchDeliveryVacationDashboard(
  String partnerCode,
) async {
  final url = Uri.parse(
    '${ApiConstants.baseUrl}/DeliveryPartner/GetVacationModeDashboard/$partnerCode',
  );
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch vacation dashboard');
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  return DeliveryVacationDashboardData.fromJson(data);
}

class DeliveryVacationModeScreen extends StatefulWidget {
  final String partnerCode;

  const DeliveryVacationModeScreen({super.key, required this.partnerCode});

  @override
  State<DeliveryVacationModeScreen> createState() =>
      _DeliveryVacationModeScreenState();
}

class _DeliveryVacationModeScreenState
    extends State<DeliveryVacationModeScreen> {
  DeliveryVacationDashboardData? _dashboard;
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboard = await fetchDeliveryVacationDashboard(
        widget.partnerCode,
      );
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load vacation mode details right now.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = _dashboard;

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
                  Container(height: 120, color: const Color(0xFFFDEBB7)),
            ),
          ),
          SafeArea(
            child:
                Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        _buildFilterButtons(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: RefreshIndicator(
                            color: const Color(0xFFF9C55E),
                            onRefresh: _loadDashboard,
                            child: _buildBody(dashboard),
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            "Vacation Mode Readers",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    List<String> filters = ["All", "Vacation", "Upcoming"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: filters.map((status) {
          final isSelected = _selectedFilter == status;

          Color filterColor;
          if (status == "Vacation") {
            filterColor = const Color(0xFFF97316);
          } else if (status == "Upcoming") {
            filterColor = const Color(0xFF2563EB);
          } else {
            filterColor = const Color(0xFFF9C55E);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = status),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? filterColor.withValues(alpha: 0.2)
                      : const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: filterColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? filterColor : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(DeliveryVacationDashboardData? dashboard) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        children: [
          _buildMessageCard(
            title: 'Could not load details',
            subtitle: _error!,
            actionLabel: 'Try Again',
            onTap: _loadDashboard,
          ),
        ],
      );
    }

    if (dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        children: [
          _buildMessageCard(
            title: 'No vacation data found',
            subtitle: 'Pull to refresh or try again in a moment.',
            actionLabel: 'Refresh',
            onTap: _loadDashboard,
          ),
        ],
      );
    }

    bool showVacation =
        _selectedFilter == "All" || _selectedFilter == "Vacation";
    bool showUpcoming =
        _selectedFilter == "All" || _selectedFilter == "Upcoming";

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        _buildSummaryCard(dashboard),
        const SizedBox(height: 20),
        if (showVacation) ...[
          _buildSectionTitle(
            'Currently on Vacation (${dashboard.currentlyOnVacationCount})',
          ),
          if (dashboard.currentlyOnVacation.isEmpty)
            _buildEmptyState('No readers are on vacation today.')
          else
            ...List.generate(
              dashboard.currentlyOnVacation.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == dashboard.currentlyOnVacation.length - 1
                      ? 0
                      : 12,
                ),
                child:
                    _VacationReaderCard(
                          reader: dashboard.currentlyOnVacation[index],
                          isUpcoming: false,
                        )
                        .animate(delay: Duration(milliseconds: 60 * index))
                        .fadeIn()
                        .slideY(begin: 0.08, end: 0),
              ),
            ),
        ],
        if (_selectedFilter == "All") const SizedBox(height: 22),
        if (showUpcoming) ...[
          _buildSectionTitle('Upcoming Vacations'),
          if (dashboard.upcomingVacations.isEmpty)
            _buildEmptyState('No upcoming vacations scheduled right now.')
          else
            ...List.generate(
              dashboard.upcomingVacations.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == dashboard.upcomingVacations.length - 1
                      ? 0
                      : 12,
                ),
                child:
                    _VacationReaderCard(
                          reader: dashboard.upcomingVacations[index],
                          isUpcoming: true,
                        )
                        .animate(delay: Duration(milliseconds: 70 * index))
                        .fadeIn()
                        .slideY(begin: 0.08, end: 0),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(DeliveryVacationDashboardData dashboard) {
    return Row(
      children: [
        Expanded(
          child: _SummaryMetric(
            title: 'Readers on vacation',
            value: '${dashboard.readersOnVacationCount}',
            subtext: dashboard.readersOnVacationCount > 0
                ? 'Currently active'
                : 'No active vacations',
            color: Colors.orange,
            backgroundColor: const Color(0xFFFFF7E6),
            icon: Icons.beach_access_rounded,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _SummaryMetric(
            title: 'Papers Saved Today',
            value: '${dashboard.papersSavedTodayCount}',
            subtext: dashboard.papersSavedTodayCount > 0
                ? 'Good savings today'
                : 'No papers saved yet',
            color: const Color(0xFF2563EB),
            backgroundColor: const Color(0xFFF1F6FF),
            icon: Icons.newspaper_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF475569),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9C55E),
              foregroundColor: Colors.black,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.subtext,
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color.withValues(alpha: 0.82),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationReaderCard extends StatelessWidget {
  final DeliveryVacationReader reader;
  final bool isUpcoming;

  const _VacationReaderCard({required this.reader, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final startDate = reader.startDate;
    final endDate = reader.endDate;
    final statusLabel = isUpcoming
        ? _upcomingLabel(startDate)
        : _daysLeftLabel(endDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUpcoming ? const Color(0xFFF4F8FF) : const Color(0xFFFFF8EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpcoming ? const Color(0xFFD6E5FF) : const Color(0xFFF7D3A4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFFE7F0FF)
                      : const Color(0xFFFFECD5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: isUpcoming
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF97316),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reader.readerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reader.houseLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (statusLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? const Color(0xFFE3EEFF)
                        : const Color(0xFFFFEBD6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isUpcoming
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFFEA580C),
                    ),
                  ),
                ),
            ],
          ),
          if (reader.publicationNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reader.publicationNames
                  .map(
                    (publication) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUpcoming
                              ? const Color(0xFFD0E0FF)
                              : const Color(0xFFF7D8B1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.newspaper_rounded,
                            size: 12,
                            color: Color(0xFF475569),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            publication,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isUpcoming
                ? Text(
                    '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Start: ${_formatShortDate(startDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'End: ${_formatShortDate(endDate)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
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

  static String _formatShortDate(DateTime? date) {
    if (date == null) return '--';
    return DateFormat('d/M/yyyy').format(date);
  }

  static String _daysLeftLabel(DateTime? endDate) {
    if (endDate == null) return '';
    final today = DateTime.now();
    final nowDate = DateTime(today.year, today.month, today.day);
    final vacationEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final daysLeft = vacationEnd.difference(nowDate).inDays + 1;
    if (daysLeft <= 0) return 'Ends today';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }

  static String _upcomingLabel(DateTime? startDate) {
    if (startDate == null) return '';
    final today = DateTime.now();
    final nowDate = DateTime(today.year, today.month, today.day);
    final vacationStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final daysLeft = vacationStart.difference(nowDate).inDays;
    if (daysLeft <= 0) return 'Starts today';
    if (daysLeft == 1) return 'Starts in 1 day';
    return 'Starts in $daysLeft days';
  }
}
