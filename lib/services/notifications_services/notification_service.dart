import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/notification.dart';

class NotificationService {
  static const String baseUrl =
      'https://agriguide-backend-79j2.onrender.com';

  static String? _cachedToken;

  /// Get auth token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  /// Get headers with Token authentication
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Token $token',
    };
  }

  /// Get all notifications
  static Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = await _getHeaders();
      final queryParam = unreadOnly ? '?unread_only=true' : '';
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/$queryParam'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('notifications')) {
          final List<dynamic> data = responseData['notifications'];
          return data.map((json) => AppNotification.fromJson(json)).toList();
        }
        else if (responseData.containsKey('results')) {
          final List<dynamic> data = responseData['results'];
          return data.map((json) => AppNotification.fromJson(json)).toList();
        }
        else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading notifications: $e');
    }
  }

  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return 0;
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/unread-count/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unread_count'] ?? 0;
      } else if (response.statusCode == 401) {
        return 0;
      } else {
        throw Exception('Failed to load unread count: ${response.statusCode}');
      }
    } catch (e) {
      return 0;
    }
  }

  /// Mark a notification as read
  static Future<void> markAsRead(int notificationId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read/'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode != 200) {
        throw Exception(
          'Failed to mark notification as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<int> markAllAsRead() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/notifications/mark-all-read/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to mark all as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId/delete/'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception(
          'Failed to delete notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  static Future<void> deleteAllNotifications() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/notifications/delete-all/'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception(
          'Failed to delete all notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error deleting all notifications: $e');
    }
  }

  /// Clear cached token (call this on logout)
  static Future<void> clearAuthToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}