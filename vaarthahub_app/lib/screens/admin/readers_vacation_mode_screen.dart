import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vaarthahub_app/services/api_service.dart';

class ReadersVacationModeScreen extends StatefulWidget {
  const ReadersVacationModeScreen({super.key});

  @override
  State<ReadersVacationModeScreen> createState() =>
      _ReadersVacationModeScreenState();
}

class _ReadersVacationModeScreenState extends State<ReadersVacationModeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _error;
  _AdminVacationOverview? _overview;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVacationData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _loadVacationData(showLoader: false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVacationData({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final data = await _fetchVacationPayload();
      final overview = _AdminVacationOverview.fromJson(data);

      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading admin vacation data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load vacation mode details right now.';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchVacationPayload() async {
    final endpoints = [
      '${ApiConstants.baseUrl}/Subscriptions/GetVacationModeData',
      '${ApiConstants.baseUrl}/Admin/GetVacationModeData',
    ];

    for (final endpoint in endpoints) {
      try {
        final response = await http.get(Uri.parse(endpoint));
        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          if (decoded is Map) {
            return Map<String, dynamic>.from(decoded);
          }
        }
      } catch (_) {
        // Try the next known endpoint before failing.
      }
    }

    throw Exception('No vacation mode endpoint returned usable data');
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          // Orange decorative curve at the top
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
                const SizedBox(height: 28),
                _buildHeader(),
                const SizedBox(height: 18),
                _buildTabs(),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFF9C55E),
                    onRefresh: _loadVacationData,
                    child: _buildBody(overview),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Vacation Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
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
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: const Color(0xFFF9C55E),
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_AdminVacationOverview? overview) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF9C55E)),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
        children: [
          _buildMessageCard(
            title: 'Could not load vacation details',
            subtitle: _error!,
            icon: Icons.cloud_off_rounded,
            actionLabel: 'Try Again',
            onTap: _loadVacationData,
          ),
        ],
      );
    }

    if (overview == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
        children: [
          _buildMessageCard(
            title: 'No vacation data found',
            subtitle: 'Pull to refresh or try again in a moment.',
            icon: Icons.beach_access_rounded,
            actionLabel: 'Refresh',
            onTap: _loadVacationData,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildOverviewStrip(overview),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPartnerList(
                groups: overview.currentGroups,
                emptyTitle: 'No readers currently on vacation',
                emptySubtitle:
                    'Active vacations will appear here once any reader pauses delivery.',
                isUpcoming: false,
              ),
              _buildPartnerList(
                groups: overview.upcomingGroups,
                emptyTitle: 'No upcoming vacations scheduled',
                emptySubtitle: 'Scheduled vacation requests will show up here.',
                isUpcoming: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStrip(_AdminVacationOverview overview) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              title: 'Current',
              value: '${overview.currentReaderCount}',
              subtitle: 'readers on vacation',
              color: const Color(0xFFF97316),
              backgroundColor: const Color(0xFFFFF4E7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryChip(
              title: 'Upcoming',
              value: '${overview.upcomingReaderCount}',
              subtitle: 'scheduled readers',
              color: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFF1F6FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerList({
    required List<_AdminVacationPartnerGroup> groups,
    required String emptyTitle,
    required String emptySubtitle,
    required bool isUpcoming,
  }) {
    if (groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
        children: [
          _buildMessageCard(
            title: emptyTitle,
            subtitle: emptySubtitle,
            icon: isUpcoming ? Icons.schedule_rounded : Icons.beach_access,
            actionLabel: 'Refresh',
            onTap: _loadVacationData,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final group = groups[index];
        return _PartnerVacationSection(group: group, isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required Future<void> Function() onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF5D8AA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1DC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFF97316)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onTap(),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFF9C55E),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Color backgroundColor;

  const _SummaryChip({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerVacationSection extends StatelessWidget {
  final _AdminVacationPartnerGroup group;
  final bool isUpcoming;

  const _PartnerVacationSection({
    required this.group,
    required this.isUpcoming,
  });

  @override
  Widget build(BuildContext context) {
    final badgeText = isUpcoming
        ? '${group.readerCount} upcoming'
        : '${group.readerCount} reader${group.readerCount == 1 ? '' : 's'} on vacation';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 18,
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
              Expanded(
                child: Text(
                  group.partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? const Color(0xFFE9F1FF)
                      : const Color(0xFFFFF0DF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isUpcoming
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
          if (group.panchayatName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              group.panchayatName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...List.generate(group.readers.length, (index) {
            final reader = group.readers[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == group.readers.length - 1 ? 0 : 12,
              ),
              child: _VacationReaderCard(
                reader: reader,
                isUpcoming: isUpcoming,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _VacationReaderCard extends StatelessWidget {
  final _AdminVacationReader reader;
  final bool isUpcoming;

  const _VacationReaderCard({required this.reader, required this.isUpcoming});

  @override
  Widget build(BuildContext context) {
    final statusText = isUpcoming
        ? _upcomingLabel(reader.startDate)
        : _daysLeftLabel(reader.endDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUpcoming ? const Color(0xFFF4F8FF) : const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUpcoming ? const Color(0xFFD9E7FF) : const Color(0xFFF7D7AB),
        ),
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
                      : const Color(0xFFFFEED8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 17,
                  color: isUpcoming
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF97316),
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
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                            reader.locationLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (statusText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? const Color(0xFFE4EEFF)
                        : const Color(0xFFFFE8D3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    statusText,
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
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUpcoming
                              ? const Color(0xFFD5E3FF)
                              : const Color(0xFFF2D1A2),
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
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Start: ${_formatShortDate(reader.startDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'End: ${_formatShortDate(reader.endDate)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                if (reader.summaryText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    reader.summaryText!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static final DateFormat _dateFormat = DateFormat('d/M/yyyy');

  static String _formatShortDate(DateTime? date) {
    if (date == null) return '--';
    return _dateFormat.format(date);
  }

  static String _daysLeftLabel(DateTime? endDate) {
    if (endDate == null) return '';
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final daysLeft = end.difference(current).inDays + 1;

    if (daysLeft <= 0) return 'Ends today';
    if (daysLeft == 1) return '1 day left';
    return '$daysLeft days left';
  }

  static String _upcomingLabel(DateTime? startDate) {
    if (startDate == null) return '';
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final daysUntil = start.difference(current).inDays;

    if (daysUntil <= 0) return 'Starts today';
    if (daysUntil == 1) return 'Starts in 1 day';
    return 'Starts in $daysUntil days';
  }
}

class _AdminVacationOverview {
  final List<_AdminVacationPartnerGroup> currentGroups;
  final List<_AdminVacationPartnerGroup> upcomingGroups;

  const _AdminVacationOverview({
    required this.currentGroups,
    required this.upcomingGroups,
  });

  int get currentReaderCount =>
      currentGroups.fold(0, (sum, group) => sum + group.readerCount);

  int get upcomingReaderCount =>
      upcomingGroups.fold(0, (sum, group) => sum + group.readerCount);

  factory _AdminVacationOverview.fromJson(Map<String, dynamic> json) {
    final partnerDirectory = _buildPartnerDirectory(json['deliveryPartners']);

    return _AdminVacationOverview(
      currentGroups: _buildGroups(
        rawItems: json['currentVacations'] ?? json['currentlyOnVacation'],
        partnerDirectory: partnerDirectory,
      ),
      upcomingGroups: _buildGroups(
        rawItems: json['upcomingVacations'],
        partnerDirectory: partnerDirectory,
      ),
    );
  }

  static Map<String, _PartnerInfo> _buildPartnerDirectory(dynamic rawPartners) {
    if (rawPartners is! List) return const {};

    final directory = <String, _PartnerInfo>{};
    for (final partner in rawPartners) {
      if (partner is! Map) continue;
      final map = Map<String, dynamic>.from(partner);
      final code = (map['partnerCode'] ?? '').toString().trim();
      if (code.isEmpty) continue;
      directory[code] = _PartnerInfo(
        name: _pickFirstText(map, [
          'fullName',
          'partnerName',
        ], fallback: 'Unknown Partner'),
        panchayat: _pickFirstText(map, [
          'panchayatName',
          'areaName',
        ], fallback: ''),
      );
    }
    return directory;
  }

  static List<_AdminVacationPartnerGroup> _buildGroups({
    required dynamic rawItems,
    required Map<String, _PartnerInfo> partnerDirectory,
  }) {
    if (rawItems is! List) return const [];

    final grouped = <String, Map<int, _AdminVacationReaderBuilder>>{};

    for (final item in rawItems) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final partnerCode = _pickFirstText(map, [
        'addedByPartnerCode',
        'partnerCode',
      ], fallback: 'unassigned');
      final readerId = _parseInt(map['readerId']);
      final stableReaderId = readerId != 0
          ? readerId
          : map.hashCode ^ partnerCode.hashCode;

      grouped.putIfAbsent(partnerCode, () => {});
      final partnerReaders = grouped[partnerCode]!;
      partnerReaders.putIfAbsent(
        stableReaderId,
        () => _AdminVacationReaderBuilder.fromJson(map),
      );
      partnerReaders[stableReaderId]!.merge(map);
    }

    final groups =
        grouped.entries.map((entry) {
          final partnerInfo = partnerDirectory[entry.key];
          final readers =
              entry.value.values.map((builder) => builder.build()).toList()
                ..sort((a, b) {
                  final firstDate = a.startDate ?? DateTime(2999);
                  final secondDate = b.startDate ?? DateTime(2999);
                  return firstDate.compareTo(secondDate);
                });

          return _AdminVacationPartnerGroup(
            partnerCode: entry.key,
            partnerName: partnerInfo?.name ?? 'Unknown Partner',
            panchayatName: partnerInfo?.panchayat ?? '',
            readers: readers,
          );
        }).toList()..sort(
          (a, b) => a.partnerName.toLowerCase().compareTo(
            b.partnerName.toLowerCase(),
          ),
        );

    return groups;
  }

  static String _pickFirstText(
    Map<String, dynamic> map,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _AdminVacationPartnerGroup {
  final String partnerCode;
  final String partnerName;
  final String panchayatName;
  final List<_AdminVacationReader> readers;

  const _AdminVacationPartnerGroup({
    required this.partnerCode,
    required this.partnerName,
    required this.panchayatName,
    required this.readers,
  });

  int get readerCount => readers.length;
}

class _PartnerInfo {
  final String name;
  final String panchayat;

  const _PartnerInfo({required this.name, required this.panchayat});
}

class _AdminVacationReader {
  final String readerName;
  final String locationLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> publicationNames;
  final double? dailySavings;
  final double? totalSavings;

  const _AdminVacationReader({
    required this.readerName,
    required this.locationLabel,
    required this.startDate,
    required this.endDate,
    required this.publicationNames,
    required this.dailySavings,
    required this.totalSavings,
  });

  String? get summaryText {
    final daily = dailySavings;
    final total = totalSavings;

    if (daily == null && total == null) {
      final publications = publicationNames.length;
      if (publications <= 1) return null;
      return '$publications publications paused';
    }

    final parts = <String>[];
    if (daily != null) {
      parts.add('Daily savings: ${_formatCurrency(daily)}');
    }
    if (total != null) {
      parts.add('Total: ${_formatCurrency(total)}');
    }
    return parts.join(' | ');
  }

  static String _formatCurrency(double amount) {
    final formatted = amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return 'Rs. $formatted';
  }
}

class _AdminVacationReaderBuilder {
  String readerName;
  String locationLabel;
  DateTime? startDate;
  DateTime? endDate;
  final Set<String> publicationNames;
  double? dailySavings;
  double? totalSavings;

  _AdminVacationReaderBuilder({
    required this.readerName,
    required this.locationLabel,
    required this.startDate,
    required this.endDate,
    required this.publicationNames,
    required this.dailySavings,
    required this.totalSavings,
  });

  factory _AdminVacationReaderBuilder.fromJson(Map<String, dynamic> map) {
    return _AdminVacationReaderBuilder(
      readerName: _firstText(map, [
        'readerName',
        'fullName',
      ], fallback: 'Reader'),
      locationLabel: _buildLocationLabel(map),
      startDate: _parseDate(
        map['vacationStartDate'] ?? map['startDate'] ?? map['fromDate'],
      ),
      endDate: _parseDate(
        map['vacationEndDate'] ?? map['endDate'] ?? map['toDate'],
      ),
      publicationNames: _parsePublicationNames(map).toSet(),
      dailySavings: _parseDouble(
        map['dailySavings'] ?? map['dailyAmount'] ?? map['pricePerDay'],
      ),
      totalSavings: _parseDouble(
        map['totalSavings'] ?? map['totalAmountSaved'] ?? map['savedAmount'],
      ),
    );
  }

  void merge(Map<String, dynamic> map) {
    readerName = readerName.trim().isNotEmpty
        ? readerName
        : _firstText(map, ['readerName', 'fullName'], fallback: 'Reader');

    final mergedLocation = _buildLocationLabel(map);
    if (locationLabel.trim().isEmpty ||
        locationLabel == 'Address not available') {
      locationLabel = mergedLocation;
    }

    final nextStart = _parseDate(
      map['vacationStartDate'] ?? map['startDate'] ?? map['fromDate'],
    );
    final nextEnd = _parseDate(
      map['vacationEndDate'] ?? map['endDate'] ?? map['toDate'],
    );

    if (nextStart != null) {
      if (startDate == null || nextStart.isBefore(startDate!)) {
        startDate = nextStart;
      }
    }

    if (nextEnd != null) {
      if (endDate == null || nextEnd.isAfter(endDate!)) {
        endDate = nextEnd;
      }
    }

    publicationNames.addAll(_parsePublicationNames(map));

    final nextDaily = _parseDouble(
      map['dailySavings'] ?? map['dailyAmount'] ?? map['pricePerDay'],
    );
    if (nextDaily != null) {
      dailySavings = (dailySavings ?? 0) + nextDaily;
    }

    final nextTotal = _parseDouble(
      map['totalSavings'] ?? map['totalAmountSaved'] ?? map['savedAmount'],
    );
    if (nextTotal != null) {
      totalSavings = (totalSavings ?? 0) + nextTotal;
    }
  }

  _AdminVacationReader build() {
    return _AdminVacationReader(
      readerName: readerName,
      locationLabel: locationLabel,
      startDate: startDate,
      endDate: endDate,
      publicationNames: publicationNames.toList()..sort(),
      dailySavings: dailySavings,
      totalSavings: totalSavings,
    );
  }

  static String _firstText(
    Map<String, dynamic> map,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return fallback;
  }

  static String _buildLocationLabel(Map<String, dynamic> map) {
    final houseName = map['houseName']?.toString().trim() ?? '';
    final houseNo = map['houseNo']?.toString().trim() ?? '';
    final landmark = map['landmark']?.toString().trim() ?? '';
    final panchayatName = map['panchayatName']?.toString().trim() ?? '';
    final wardNumber = map['wardNumber']?.toString().trim() ?? '';
    final pincode = map['pincode']?.toString().trim() ?? '';

    return "$houseName, $houseNo, $landmark, $panchayatName, Ward $wardNumber, $pincode";
  }

  static List<String> _parsePublicationNames(Map<String, dynamic> map) {
    final publications = <String>{};

    final names = map['publicationNames'];
    if (names is List) {
      for (final item in names) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          publications.add(text);
        }
      }
    }

    for (final key in ['subscriptionName', 'itemName', 'name']) {
      final text = map[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        publications.add(text);
      }
    }

    final itemType = map['itemType']?.toString().trim() ?? '';
    if (publications.isEmpty &&
        itemType.isNotEmpty &&
        itemType.toLowerCase() != 'null') {
      publications.add(itemType);
    }

    return publications.toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
