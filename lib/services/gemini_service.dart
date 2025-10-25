import 'dart:convert';
import 'package:http/http.dart' as http;

/// A service for sending prompts to the Django Gemini proxy API
class GeminiService {
  /// Replace this with your backend endpoint
  static const String _baseUrl = 'http://127.0.0.1:8000/api/gemini/ask/';

  /// Sends a user prompt to the backend and returns Gemini's text response.
  static Future<String> askGemini(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
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
}
