import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service that combines AI chat with voice capabilities
class VoiceAIService {
  static const String _baseUrl =
      'https://agriguide-backend-79j2.onrender.com/api';

  static String? _cachedToken;
  static String? _cachedSessionId;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Initialize the voice AI service with auth token
  static Future<void> initialize({required String authToken}) async {
    _cachedToken = authToken;
    // Service is now ready to use
  }

  /// Gets the cached auth token
  static Future<String?> _getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;

    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('token');
    return _cachedToken;
  }

  /// Gets the current session ID
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

  /// Send a voice message and get voice response with text
  ///
  /// Parameters:
  /// - [message]: Text message to send
  /// - [sessionId]: Optional session ID for conversation continuity
  /// - [voice]: Voice name for TTS (default: 'Zephyr')
  /// - [includeAudio]: Whether to request audio response (default: true)
  ///
  /// Returns a Map with:
  /// - 'success': bool
  /// - 'response': String (AI response text)
  /// - 'audioBase64': String (base64 encoded audio, if includeAudio is true)
  /// - 'sessionId': String (session ID)
  /// - 'error': String (error message if failed)
  static Future<Map<String, dynamic>> sendVoiceMessage({
    required String message,
    String? sessionId,
    String voice = 'Zephyr',
    bool includeAudio = true,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final currentSessionId = sessionId ?? await _getSessionId();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/voice/chat/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': message,
              'session_id': currentSessionId,
              'voice': voice,
              'include_audio': includeAudio,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newSessionId = data['session_id'];

        // Cache the session ID
        if (newSessionId != null) {
          await _setSessionId(newSessionId);
        }

        return {
          'success': true,
          'response':
              data['response'] ?? data['text_response'] ?? 'No response',
          'audioBase64': data['audio_base64'] ?? data['audio'],
          'sessionId': newSessionId,
          'voiceUsed': data['voice_used'] ?? voice,
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
          'error': 'Error ${response.statusCode}: ${response.reasonPhrase}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Voice message error: $e'};
    }
  }

  /// Play audio from base64 string
  static Future<void> playAudio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  /// Stop audio playback
  static Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  /// Get available voices from the backend
  static Future<Map<String, dynamic>> getAvailableVoices() async {
    final token = await _getAuthToken();
    if (token == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/voice/voices/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'voices': data['voices'] ?? []};
      } else {
        return {'success': false, 'error': 'Failed to fetch voices'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error fetching voices: $e'};
    }
  }

  /// Complete flow: Send message and play audio response
  static Future<Map<String, dynamic>> chatWithVoice({
    required String message,
    String? sessionId,
    String voice = 'Zephyr',
  }) async {
    try {
      // Send message and get response
      final response = await sendVoiceMessage(
        message: message,
        sessionId: sessionId,
        voice: voice,
        includeAudio: true,
      );

      if (!response['success']) {
        return response;
      }

      // Play audio if available
      if (response['audioBase64'] != null && response['audioBase64'] != '') {
        try {
          await playAudio(response['audioBase64']);
        } catch (e) {
          print('Warning: Could not play audio: $e');
          // Don't fail the whole operation if audio fails
        }
      }

      return response;
    } catch (e) {
      return {'success': false, 'error': 'Chat with voice error: $e'};
    }
  }

  /// Get current session ID
  static Future<String?> getCurrentSessionId() async {
    return await _getSessionId();
  }

  /// Set a specific session ID
  static Future<void> setSessionId(String sessionId) async {
    await _setSessionId(sessionId);
  }

  /// Clear the current session
  static Future<void> clearSession() async {
    _cachedSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_session_id');
  }

  /// Check audio player state
  static Future<PlayerState> getAudioState() async {
    return await _audioPlayer.state;
  }

  /// Dispose resources
  static void dispose() {
    _audioPlayer.dispose();
  }
}
