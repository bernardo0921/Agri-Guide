import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  Future<String> generateResponse(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }
}
