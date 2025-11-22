import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

/// Service for handling AI chat functionality with authentication
class AIService {
  static const String _baseUrl =
      'https://agriguide-backend-79j2.onrender.com/api';

  static String? _cachedToken;
  static String? _cachedSessionId;

  static Future<String?> _getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  static Future<void> setAuthToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearAuthToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<String?> _getSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId;
    final prefs = await SharedPreferences.getInstance();
    _cachedSessionId = prefs.getString('ai_session_id');
    return _cachedSessionId;
  }

  static Future<void> _setSessionId(String sessionId) async {
    _cachedSessionId = sessionId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_session_id', sessionId);
  }

  static Future<void> _clearSessionId() async {
    _cachedSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_session_id');
  }

  /// Sends a message to the AI with streaming support
  /// Now accepts 'language' in requestData: 'english' or 'sesotho'
  static Stream<Map<String, dynamic>> sendMessageStream({
    required Map<String, dynamic> requestData,
  }) async* {
    final token = await _getAuthToken();
    if (token == null) {
      yield {'success': false, 'error': 'Not authenticated'};
      return;
    }

    final message = requestData['message'] as String?;
    final sessionId = requestData['session_id'] as String?;
    final language = requestData['language'] as String? ?? 'english';

    if (message == null || message.isEmpty) {
      yield {'success': false, 'error': 'Message is required'};
      return;
    }

    final url = Uri.parse('$_baseUrl/chat-stream/');
    final request = http.Request('POST', url);

    request.headers.addAll({
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    });

    final requestBody = {
      'message': message,
      'language': language,
      if (sessionId != null) 'session_id': sessionId,
    };

    request.body = json.encode(requestBody);

    // // // print('🚀 Sending stream request | session: $sessionId | language: $language');

    try {
      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        if (streamedResponse.statusCode == 401) {
          yield {
            'success': false,
            'error': 'Authentication failed. Please login again.',
            'requiresLogin': true,
          };
        } else {
          yield {
            'success': false,
            'error': 'Server error: ${streamedResponse.statusCode}'
          };
        }
        return;
      }

      String buffer = '';
      String fullResponse = '';

      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;

        while (buffer.contains('\n\n')) {
          final index = buffer.indexOf('\n\n');
          final message = buffer.substring(0, index);
          buffer = buffer.substring(index + 2);

          if (message.startsWith('data: ')) {
            final jsonStr = message.substring(6).trim();
            try {
              final data = json.decode(jsonStr);

              if (data['type'] == 'session_id') {
                final newSessionId = data['session_id'];
                if (newSessionId != null) {
                  await _setSessionId(newSessionId);
                  // print('✅ Received session_id: $newSessionId | language: ${data['language']}');
                }
                yield {
                  'success': true,
                  'type': 'session_id',
                  'sessionId': newSessionId,
                  'language': data['language'],
                };
              } else if (data['type'] == 'chunk') {
                fullResponse += data['text'];
                yield {
                  'success': true,
                  'type': 'chunk',
                  'chunk': data['text'],
                  'fullText': fullResponse,
                };
              } else if (data['type'] == 'done') {
                yield {
                  'success': true,
                  'type': 'done',
                  'response': data['full_text'],
                  'sessionId': _cachedSessionId,
                };
              } else if (data['type'] == 'error') {
                yield {
                  'success': false,
                  'type': 'error',
                  'error': data['error'],
                };
              }
            } catch (e) {
              // // print('Error parsing SSE data: $e');
            }
          }
        }
      }
    } on http.ClientException catch (e) {
      yield {
        'success': false,
        'error': 'Network error: ${e.message}. Please check your connection.',
      };
    } on SocketException catch (e) {
      yield {
        'success': false,
        'error': 'Connection error: ${e.message}. Check your internet.',
      };
    } catch (e) {
      yield {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Sends a message to the AI (non-streaming)
  /// [language] - 'english' or 'sesotho'
  static Future<Map<String, dynamic>> sendMessage(
    String message, {
    String language = 'english',
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final sessionId = await _getSessionId();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          'language': language,
          if (sessionId != null) 'session_id': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSessionId = data['session_id'];

        if (newSessionId != null) {
          await _setSessionId(newSessionId);
        }

        return {
          'success': true,
          'response': data['response'] ?? 'No response received.',
          'sessionId': newSessionId,
          'language': data['language'],
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
          'error': errorData['error'] ?? 'Error ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}.',
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

  /// Sends an image with optional text message to the AI
  /// [language] - 'english' or 'sesotho'
  static Future<Map<String, dynamic>> sendImageMessage(
    File imageFile, {
    String? message,
    String language = 'english',
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    final sessionId = await _getSessionId();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/chat/'));

      request.headers['Authorization'] = 'Token $token';

      // Add language field
      request.fields['language'] = language;

      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }

      if (message != null && message.isNotEmpty) {
        request.fields['message'] = message;
      }

      var imageStream = http.ByteStream(imageFile.openRead());
      var imageLength = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // // print('📸 Sending image | language: $language');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSessionId = data['session_id'];
        final imageUrl = data['image_url'];

        if (newSessionId != null) {
          await _setSessionId(newSessionId);
        }

        return {
          'success': true,
          'response': data['response'] ?? 'Image analyzed successfully.',
          'sessionId': newSessionId,
          'imageUrl': imageUrl,
          'language': data['language'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Authentication failed. Please login again.',
          'requiresLogin': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to send image: ${response.statusCode}',
        };
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.message}.',
      };
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  // ========== Remaining methods unchanged ==========

  static Future<Map<String, dynamic>> getChatSessions() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/sessions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

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

  static Future<Map<String, dynamic>> getChatHistory(String sessionId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history/$sessionId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

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

  static Future<Map<String, dynamic>> clearCurrentSession() async {
    try {
      final token = await _getAuthToken();
      final sessionId = await _getSessionId();

      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      if (sessionId == null) {
        return {'success': true, 'message': 'No active session.'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/clear/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({'session_id': sessionId}),
      ).timeout(const Duration(seconds: 15));

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
        return {'success': true, 'message': 'Session cleared locally.'};
      }
    } catch (e) {
      await _clearSessionId();
      return {'success': true, 'message': 'Session cleared locally.'};
    }
  }

  static Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/delete/$sessionId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 15));

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

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'Authentication required.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/test/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

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

  static Future<Map<String, dynamic>> verifyToken() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {'success': false, 'error': 'No token found.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/verify-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

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

  static Future<void> startNewSession() async {
    await _clearSessionId();
  }

  static Future<void> setSessionId(String sessionId) async {
    await _setSessionId(sessionId);
  }
}