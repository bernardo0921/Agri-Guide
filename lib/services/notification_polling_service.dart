// services/notification_polling_service.dart
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';
import '../models/notification.dart';

class NotificationPollingService {
  static Timer? _pollingTimer;
  static Set<int> _shownNotificationIds = {};
  static bool _isPolling = false;

  /// Start polling for new notifications
  static Future<void> startPolling({
    Duration interval = const Duration(minutes: 1),
  }) async {
    if (_isPolling) return;

    // Load previously shown notification IDs
    await _loadShownNotifications();

    _isPolling = true;

    // Check immediately
    await _checkForNewNotifications();

    // Then check periodically
    _pollingTimer = Timer.periodic(interval, (timer) async {
      await _checkForNewNotifications();
    });

    // print(
    //   '✅ Notification polling started (checking every ${interval.inMinutes} minute(s))',
    // );
  }

  /// Stop polling
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    // print('🛑 Notification polling stopped');
  }

  /// Check for new notifications
  static Future<void> _checkForNewNotifications() async {
    try {
      // Fetch unread notifications from the server
      final notifications = await NotificationService.getNotifications(
        unreadOnly: true,
      );

      for (final notification in notifications) {
        // Only show notification if we haven't shown it before
        if (!_shownNotificationIds.contains(notification.id)) {
          await _showLocalNotification(notification);
          _shownNotificationIds.add(notification.id);
          await _saveShownNotifications();
        }
      }
    } catch (e) {
      // print('Error checking notifications: $e');
    }
  }

  /// Show a local notification based on the notification type
  static Future<void> _showLocalNotification(
    AppNotification notification,
  ) async {
    switch (notification.notificationType) {
      case 'like':
        await LocalNotificationService.showLikeNotification(
          notificationId: notification.id,
          userName: notification.senderName,
          postPreview: notification.postContentPreview ?? 'your post',
          postId: notification.postId,
        );
        break;

      case 'comment':
        await LocalNotificationService.showCommentNotification(
          notificationId: notification.id,
          userName: notification.senderName,
          commentText: notification.commentContent ?? 'commented on your post',
          postId: notification.postId,
        );
        break;

      default:
        await LocalNotificationService.showNotification(
          notificationId: notification.id,
          title: notification.senderName,
          body: notification.message,
          payload: 'post:${notification.postId}',
        );
    }
  }

  /// Load shown notification IDs from storage
  static Future<void> _loadShownNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? ids = prefs.getStringList('shown_notification_ids');
      if (ids != null) {
        _shownNotificationIds = ids.map((id) => int.parse(id)).toSet();
      }
    } catch (e) {
      // print('Error loading shown notifications: $e');
    }
  }

  /// Save shown notification IDs to storage
  static Future<void> _saveShownNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> ids = _shownNotificationIds
          .map((id) => id.toString())
          .toList();
      await prefs.setStringList('shown_notification_ids', ids);
    } catch (e) {
      // print('Error saving shown notifications: $e');
    }
  }

  /// Clear shown notifications history (useful on logout)
  static Future<void> clearHistory() async {
    _shownNotificationIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shown_notification_ids');
  }

  /// Force check for notifications (useful for manual refresh)
  static Future<void> forceCheck() async {
    await _checkForNewNotifications();
  }
}
