import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A service for sending prompts to the Django Gemini API with session management
class GeminiService {
  /// Replace this with your backend endpoint
  static const String _baseUrl = 'http://10.214.246.118:8000/api';
  
  /// Cached session ID
  static String? _sessionId;

  /// Gets or creates a unique session ID for conversation continuity
  static Future<String> getSessionId() async {
    if (_sessionId != null) return _sessionId!;
    
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('gemini_session_id');
    
    if (_sessionId == null) {
      _sessionId = const Uuid().v4();
      await prefs.setString('gemini_session_id', _sessionId!);
    }
    
    return _sessionId!;
  }

  /// Sends a user prompt to the backend and returns Gemini's text response.
  /// 
  /// [prompt] - The user's message/question
  /// [history] - Optional conversation history for context
  static Future<String> askGemini(
    String prompt, {
    List<Map<String, dynamic>>? history,
  }) async {
    try {
      final sessionId = await getSessionId();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': prompt,
          'session_id': sessionId,
          'history': history ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response text found.';
      } else {
        return 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return '⚠️ Request failed: $e';
    }
  }

  /// Clears the current chat session both locally and on the server
  static Future<void> clearSession() async {
    try {
      final sessionId = await getSessionId();
      
      await http.post(
        Uri.parse('$_baseUrl/chat/clear/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_id': sessionId}),
      );
      
      // Clear local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gemini_session_id');
      _sessionId = null;
    } catch (e) {
      print('Error clearing session: $e');
    }
  }

  /// Tests the connection to the backend server
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/test/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed: $e',
      };
    }
  }

  /// Converts conversation history from app format to API format
  /// 
  /// Takes messages in format: [{'text': '...', 'isUser': true/false}]
  /// Returns format: [{'role': 'user'/'model', 'parts': ['...']}]
  static List<Map<String, dynamic>> convertHistoryToApiFormat(
    List<Map<String, dynamic>> messages,
  ) {
    return messages.map((msg) {
      return {
        'role': msg['isUser'] == true ? 'user' : 'model',
        'parts': [msg['text']],
      };
    }).toList();
  }
}