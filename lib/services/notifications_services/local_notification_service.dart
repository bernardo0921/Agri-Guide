// FILE 1: local_notification_service.dart
// ============================================
// services/local_notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

import '../../screens/others/notifications_page.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Global navigation key for handling notification navigation
  /// Set this in main.dart after creating the MaterialApp
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        return status.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
      >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return false;
  }

  /// Handle notification tap - Navigate to NotificationsPage
  static void _onNotificationTapped(NotificationResponse response) {
    if (navigatorKey?.currentContext == null) return;

    final context = navigatorKey!.currentContext!;

    debugPrint('Notification tapped with payload: ${response.payload}');

    // Import the NotificationsPage at the top of this file:
    // import '../screens/notifications_page.dart';

    // Navigate to NotificationsPage
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsPage(),
      ),
    );
  }

  /// Show a notification for a new like
  static Future<void> showLikeNotification({
    required int notificationId,
    required String userName,
    required String postPreview,
    int? postId,
  }) async {
    await _showNotification(
      id: notificationId,
      title: '❤️ New Like',
      body: '$userName liked your post: "$postPreview"',
      payload: postId != null ? 'post:$postId' : null,
    );
  }

  /// Show a notification for a new comment
  static Future<void> showCommentNotification({
    required int notificationId,
    required String userName,
    required String commentText,
    int? postId,
  }) async {
    await _showNotification(
      id: notificationId,
      title: '💬 New Comment',
      body: '$userName commented: "$commentText"',
      payload: postId != null ? 'post:$postId' : null,
    );
  }

  /// Show a generic notification
  static Future<void> showNotification({
    required int notificationId,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: notificationId,
      title: title,
      body: body,
      payload: payload,
    );
  }

  /// Internal method to show notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'agriguide_channel', // channel ID
      'AgriGuide Notifications', // channel name
      channelDescription: 'Notifications for likes, comments, and posts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
