// voice_chat_service.dart - Flutter service for voice chat
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

class VoiceChatService {
  final String baseUrl;
  final String authToken;
  final AudioPlayer audioPlayer = AudioPlayer();

  VoiceChatService({
    required this.baseUrl,
    required this.authToken,
  });

  /// Send a voice chat message and get audio response
  Future<VoiceChatResponse> sendVoiceMessage({
    required String message,
    String? sessionId,
    String voice = 'Zephyr',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/voice/chat/stream/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'message': message,
          'session_id': sessionId,
          'voice': voice,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VoiceChatResponse.fromJson(data);
      } else {
        throw Exception('Failed to get voice response: ${response.body}');
      }
    } catch (e) {
      throw Exception('Voice chat error: $e');
    }
  }

  /// Play audio from base64 string
  Future<void> playAudioFromBase64(String base64Audio) async {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(base64Audio);
      
      // Create temporary file or use BytesSource
      await audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      print('Error playing audio: $e');
      throw e;
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    await audioPlayer.stop();
  }

  /// Get available voices
  Future<List<Voice>> getAvailableVoices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/voice/voices/'),
        headers: {
          'Authorization': 'Token $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['voices'] as List)
            .map((v) => Voice.fromJson(v))
            .toList();
      } else {
        throw Exception('Failed to get voices');
      }
    } catch (e) {
      throw Exception('Error fetching voices: $e');
    }
  }

  /// Complete voice chat flow: send message and play response
  Future<String> chatWithVoice({
    required String message,
    String? sessionId,
    String voice = 'Zephyr',
  }) async {
    try {
      // Get response
      final response = await sendVoiceMessage(
        message: message,
        sessionId: sessionId,
        voice: voice,
      );

      // Play audio if available
      if (response.audioBase64 != null) {
        await playAudioFromBase64(response.audioBase64!);
      }

      return response.textResponse;
    } catch (e) {
      throw Exception('Voice chat flow error: $e');
    }
  }

  void dispose() {
    audioPlayer.dispose();
  }
}

class VoiceChatResponse {
  final String sessionId;
  final String textResponse;
  final String? audioBase64;
  final String voiceUsed;

  VoiceChatResponse({
    required this.sessionId,
    required this.textResponse,
    this.audioBase64,
    required this.voiceUsed,
  });

  factory VoiceChatResponse.fromJson(Map<String, dynamic> json) {
    return VoiceChatResponse(
      sessionId: json['session_id'],
      textResponse: json['text_response'],
      audioBase64: json['audio_base64'],
      voiceUsed: json['voice_used'],
    );
  }
}

class Voice {
  final String name;
  final String description;
  final String gender;

  Voice({
    required this.name,
    required this.description,
    required this.gender,
  });

  factory Voice.fromJson(Map<String, dynamic> json) {
    return Voice(
      name: json['name'],
      description: json['description'],
      gender: json['gender'],
    );
  }
}

// Example usage in a Flutter widget:
/*
class VoiceChatScreen extends StatefulWidget {
  @override
  _VoiceChatScreenState createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  late VoiceChatService voiceService;
  String? sessionId;
  bool isLoading = false;
  String selectedVoice = 'Zephyr';

  @override
  void initState() {
    super.initState();
    voiceService = VoiceChatService(
      baseUrl: 'https://your-api.com',
      authToken: 'your-auth-token',
    );
  }

  Future<void> sendMessage(String message) async {
    setState(() => isLoading = true);
    
    try {
      final response = await voiceService.chatWithVoice(
        message: message,
        sessionId: sessionId,
        voice: selectedVoice,
      );
      
      setState(() {
        sessionId = response.sessionId;
      });
      
      // Show text response while audio plays
      print('AI Response: ${response.textResponse}');
      
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your UI here
    return Container();
  }
}
*/
