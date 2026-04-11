import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String userCode;
  const NotificationsScreen({super.key, required this.userCode});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Notifications/${widget.userCode}");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _notifications = json.decode(response.body);
          _isLoading = false;
        });
        // Mark all as read when opening the screen
        _markAllAsRead();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Fixed: changed widget.readerCode to widget.userCode
      final url = Uri.parse("${ApiConstants.baseUrl}/Notifications/mark-all-read/${widget.userCode}");
      await http.put(url);
    } catch (e) {
      debugPrint("Error marking notifications as read: $e");
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/Notifications/$id");
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _notifications.removeWhere((n) => n['notificationId'] == id);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete notification")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF9C55E)))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return _buildNotificationCard(n);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No notifications yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final presentation = _resolveNotificationPresentation(n);
    final dt = DateTime.tryParse((n['createdAt'] ?? '').toString());
    final timeStr = dt == null ? '' : DateFormat('MMM d, h:mm a').format(dt);
    final isRead = n['isRead'] == true;

    return Dismissible(
      key: Key(n['notificationId'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(n['notificationId']),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2F2F2)),
          boxShadow: [
            BoxShadow( // Keep original box shadow
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(presentation),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          presentation.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    presentation.message,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _NotificationPresentation _resolveNotificationPresentation(
    Map<String, dynamic> notification,
  ) {
    final type = (notification['type'] ?? '').toString().trim().toLowerCase();
    final title = (notification['title'] ?? '').toString().trim();
    final message = (notification['message'] ?? '').toString().trim();
    final combined = '$title $message'.toLowerCase();

    if (type == 'swapproposal' || combined.contains('swap proposal')) {
      return const _NotificationPresentation(
        title: 'New Swap Proposal',
        messageFallback: '',
        icon: Icons.swap_horiz_rounded,
        color: Color(0xFF4DA3FF),
      ).withMessage(message);
    }

    if (type == 'swapaccepted' || combined.contains('accepted')) {
      return const _NotificationPresentation(
        title: 'Swap Proposal Accepted!',
        messageFallback: '',
        icon: Icons.check_circle_rounded,
        color: Color(0xFF5DBB75),
      ).withMessage(message);
    }

    if (type == 'swapcompleted' || combined.contains('completed successfully')) {
      return const _NotificationPresentation(
        title: 'Swap Completed!',
        messageFallback: '',
        icon: Icons.emoji_events_rounded,
        color: Color(0xFFF0B43A),
      ).withMessage(message);
    }

    if (type == 'swapdeliverypending' ||
        type == 'deliveryassigned' ||
        combined.contains('delivery assigned') ||
        combined.contains('pending your delivery')) {
      return const _NotificationPresentation(
        title: 'New Delivery Assigned',
        messageFallback: '',
        icon: Icons.local_shipping_outlined,
        color: Color(0xFF6C63FF),
      ).withMessage(message);
    }

    if (type == 'ordershipped' ||
        combined.contains('order shipped') ||
        combined.contains('has been shipped')) {
      return const _NotificationPresentation(
        title: 'Order Shipped',
        messageFallback: '',
        icon: Icons.notifications_none_rounded,
        color: Color(0xFFB7B7B7),
      ).withMessage(message);
    }

    if (type == 'productbookingadmin' ||
        combined.contains('booked') && widget.userCode.toLowerCase() == 'admin') {
      return const _NotificationPresentation(
        title: 'New Product Booking',
        messageFallback: '',
        icon: Icons.inventory_2_outlined,
        color: Color(0xFF7C8AA5),
      ).withMessage(message);
    }

    if (type == 'productbookingpartner' ||
        combined.contains('booked') ||
        type == 'newsubscription' ||
        combined.contains('subscribed to')) {
      final isSubscription = type == 'newsubscription' || combined.contains('subscribed to');
      return _NotificationPresentation(
        title: isSubscription ? 'New Subscription' : 'New Product Booking',
        messageFallback: '',
        icon: isSubscription ? Icons.menu_book_rounded : Icons.local_mall_outlined,
        color: isSubscription ? const Color(0xFF2E8B57) : const Color(0xFF5A8DEE),
      ).withMessage(message);
    }

    return const _NotificationPresentation(
      title: 'Notification',
      messageFallback: '',
      icon: Icons.notifications_none_rounded,
      color: Color(0xFFB7B7B7),
    ).withValues(
      title: title.isEmpty ? 'Notification' : title,
      message: message,
    );
  }

  Widget _buildLeadingIcon(_NotificationPresentation presentation) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(presentation.icon, color: presentation.color, size: 18),
    );
  }
}

class _NotificationPresentation {
  final String title;
  final String message;
  final String messageFallback;
  final IconData icon;
  final Color color;

  const _NotificationPresentation({
    required this.title,
    required this.messageFallback,
    required this.icon,
    required this.color,
    this.message = '',
  });

  _NotificationPresentation withMessage(String message) {
    return _NotificationPresentation(
      title: title,
      messageFallback: messageFallback,
      icon: icon,
      color: color,
      message: message.isEmpty ? messageFallback : message,
    );
  }

  _NotificationPresentation withValues({
    required String title,
    required String message,
  }) {
    return _NotificationPresentation(
      title: title,
      messageFallback: messageFallback,
      icon: icon,
      color: color,
      message: message.isEmpty ? messageFallback : message,
    );
  }
}
