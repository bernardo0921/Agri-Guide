import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  Future<Map<String, dynamic>> _loadSystemInstruction() async {
    final jsonString =
        await rootBundle.loadString('assets/system_instruction.json');
    return jsonDecode(jsonString);
  }

  Future<String> sendMessage(String userMessage) async {
    final systemInstruction = await _loadSystemInstruction();

    final url =
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": userMessage}
          ]
        }
      ],
      "system_instruction": systemInstruction,
      "generationConfig": {"temperature": 0.3, "top_p": 0.8}
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      print("Gemini error: ${response.body}");
      throw Exception("Failed to get response from Gemini API");
    }
  }
}
