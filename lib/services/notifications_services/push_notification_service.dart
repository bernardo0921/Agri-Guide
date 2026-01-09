import 'package:flutter/foundation.dart';

/// PushNotificationService stub — original project used Firebase Messaging (FCM).
/// To remove Firebase while keeping the public API stable, this stub provides
/// the same initialize() method but performs no Firebase operations.
class PushNotificationService {
  static bool _initialized = false;

  /// Initialize push notification service.
  /// This implementation is a no-op to allow builds without Firebase.
  static Future<void> initialize() async {
    if (_initialized) return;

    // No-op: formerly initialized FirebaseMessaging and configured handlers.
    if (kDebugMode) {
      debugPrint('PushNotificationService.initialize() called — no-op (Firebase removed)');
    }

    _initialized = true;
  }
}
