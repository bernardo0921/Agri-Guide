# urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('api/chat/', views.chat_with_ai, name='chat_with_ai'),
    path('api/chat/clear/', views.clear_chat_session, name='clear_chat'),
    path('api/test/', views.test_connection, name='test_connection'),
]

# ============================================
# requirements.txt
# ============================================
"""
Django>=4.2.0
google-generativeai>=0.3.0
python-dotenv>=1.0.0
django-cors-headers>=4.3.0
"""

# ============================================
# .env (Create this file in your project root)
# ============================================
"""
GEMINI_API_KEY=your_gemini_api_key_here
"""

# ============================================
# settings.py (Add these configurations)
# ============================================
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Add to INSTALLED_APPS
INSTALLED_APPS = [
    ...
    'corsheaders',
]

# Add to MIDDLEWARE (near the top, after SecurityMiddleware)
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',  # Add this
    'django.contrib.sessions.middleware.SessionMiddleware',
    ...
]

# CORS settings (adjust for production)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    # Add your Flutter app's origin if testing on web
]

# Or for development only:
# CORS_ALLOW_ALL_ORIGINS = True
"""

# ============================================
# Example Flutter/Dart API Call
# ============================================
"""
// gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class GeminiService {
  static const String baseUrl = 'http://your-django-server.com/api';
  static String? _sessionId;

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

  static Future<String> askGemini(String prompt, {List<Map<String, dynamic>>? history}) async {
    try {
      final sessionId = await getSessionId();
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': prompt,
          'session_id': sessionId,
          'history': history ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'];
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    }
  }

  static Future<void> clearSession() async {
    try {
      final sessionId = await getSessionId();
      
      await http.post(
        Uri.parse('$baseUrl/chat/clear/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': sessionId}),
      );
      
      // Clear local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gemini_session_id');
      _sessionId = null;
    } catch (e) {
      print('Error clearing session: $e');
    }
  }
}
"""