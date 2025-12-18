// widgets/notification_badge.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notifications_services/notification_service.dart';
import '../screens/others/notifications_page.dart';
import '../services/ai_services/tts_service.dart';
import '../services/ai_services/speech_to_text_service.dart';

class NotificationBadge extends StatefulWidget {
  const NotificationBadge({super.key});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _unreadCount = 0;
  bool _isLoading = false;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    // Subscribe to notification change events for instant updates
    _subscription = NotificationService.onNotificationsChanged.listen((_) {
      _loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
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
    // Stop any active TTS/STT to avoid platform callbacks during navigation
    try {
      await TTSService().stop();
    } catch (_) {}
    try {
      await SpeechToTextService().stopListening();
    } catch (_) {}

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationsPage()),
      );
    } catch (e, st) {
      debugPrint('Failed to open NotificationsPage: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open notifications: $e')),
        );
      }
      return;
    }

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
            child: IgnorePointer(
              // Ensure the visual badge does not block taps on the IconButton
              ignoring: true,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
          ),
      ],
    );
  }
}
