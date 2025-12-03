// widgets/notification_badge.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/notifications_page.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      // Silently fail - don't show error for badge
    }
  }

  void _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
    
    // Refresh count when returning from notifications page
    _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: colorScheme.onSurface,
          ),
          onPressed: _navigateToNotifications,
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: Colors.red[600],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}