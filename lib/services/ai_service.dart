import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling AI chat functionality with authentication
class AIService {
  /// Base URL for your Django backend
  static const String _baseUrl = 'http://192.168.100.7:5000/api';

  /// Cached authentication token
  static String? _cachedToken;

  /// Cached session ID
  static String? _cachedSessionId;

  /// Gets the authentication token from SharedPreferences
  static Future<String?> _getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  /// Sets the authentication token (call this after login)
  static Future<void> setAuthToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  /// Clears the authentication token (call this after logout)
  static Future<void> clearAuthToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// Gets the current session ID from SharedPreferences
  static Future<String?> _getSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId;

    final prefs = await SharedPreferences.getInstance();
    _cachedSessionId = prefs.getString('ai_session_id');
    return _cachedSessionId;
  }

  /// Sets the session ID
  static Future<void> _setSessionId(String sessionId) async {
    _cachedSessionId = sessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_session_id', sessionId);
  }

  /// Clears the session ID
  static Future<void> _clearSessionId() async {
    _cachedSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_session_id');
  }

  /// Sends a message to the AI and returns the response
  ///
  /// Returns a Map with:
  /// - 'success': bool
  /// - 'response': String (AI response text)
  /// - 'sessionId': String (session ID for conversation continuity)
  /// - 'error': String (error message if failed)
  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication required. Please login first.',
        };
      }

      final sessionId = await _getSessionId();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({
              'message': message,
              if (sessionId != null) 'session_id': sessionId,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout. Please check your connection.');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSessionId = data['session_id'];

        // Cache the session ID for future requests
        if (newSessionId != null) {
          await _setSessionId(newSessionId);
        }

        return {
          'success': true,
          'response': data['response'] ?? 'No response received.',
          'sessionId': newSessionId,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'requiresLogin': true,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'error': 'Chat endpoint not found. Session may have expired.',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error':
              errorData['error'] ??
              'Error ${response.statusCode}: ${response.body}',
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}. Please check your connection.',
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'error': 'Invalid response format: ${e.message}',
      };
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Gets all chat sessions for the authenticated user
  static Future<Map<String, dynamic>> getChatSessions() async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/chat/sessions/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'sessions': data['sessions'] ?? []};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed.',
          'requiresLogin': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch sessions: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Gets chat history for a specific session
  static Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/chat/history/$sessionId/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'history': data['history'] ?? [],
          'sessionId': data['session_id'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed.',
          'requiresLogin': true,
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Session not found.'};
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch history: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Clears the current chat session
  static Future<Map<String, dynamic>> clearCurrentSession() async {
    try {
      final token = await _getAuthToken();
      final sessionId = await _getSessionId();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      if (sessionId == null) {
        // No active session to clear
        return {'success': true, 'message': 'No active session.'};
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat/clear/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({'session_id': sessionId}),
          )
          .timeout(const Duration(seconds: 15));

      // Clear local session ID regardless of server response
      await _clearSessionId();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Session cleared successfully.'};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed.',
          'requiresLogin': true,
        };
      } else {
        // Session cleared locally, but server returned error
        return {'success': true, 'message': 'Session cleared locally.'};
      }
    } catch (e) {
      // Clear local session even if request fails
      await _clearSessionId();
      return {'success': true, 'message': 'Session cleared locally.'};
    }
  }

  /// Deletes a specific chat session
  static Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http
          .delete(
            Uri.parse('$_baseUrl/chat/delete/$sessionId/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      // If deleting current session, clear local cache
      final currentSessionId = await _getSessionId();
      if (currentSessionId == sessionId) {
        await _clearSessionId();
      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Session deleted successfully.'};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed.',
          'requiresLogin': true,
        };
      } else if (response.statusCode == 404) {
        return {'success': false, 'error': 'Session not found.'};
      } else {
        return {
          'success': false,
          'error': 'Failed to delete session: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Tests the connection to the backend
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/test/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Connection successful!',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed.',
          'requiresLogin': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Verifies if the current token is valid
  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await _getAuthToken();

      if (token == null) {
        return {'success': false, 'error': 'No token found.'};
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/auth/verify-token/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'valid': data['valid'] ?? false,
          'user': data['user'],
        };
      } else {
        return {'success': false, 'error': 'Token verification failed.'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }

  /// Starts a new chat session (clears current and starts fresh)
  static Future<void> startNewSession() async {
    await _clearSessionId();
  }
}
