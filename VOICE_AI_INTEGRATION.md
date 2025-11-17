# Voice AI Service Integration Guide

## Overview

The Voice AI Service enables voice-based interaction with your AI advisory system. Users can send text messages and receive audio responses with customizable voices. This is integrated directly into the AI Advisory Page.

## Features

- **Voice Responses**: Get AI responses read aloud with natural speech synthesis
- **Multiple Voices**: Choose from different voice options (e.g., 'Zephyr')
- **Session Continuity**: Maintain conversation context across messages
- **Audio Playback**: Automatic playback of AI responses with audio controls
- **Seamless Integration**: Toggle between text-only and voice modes

## Components

### 1. VoiceAIService (`lib/services/voice_ai_service.dart`)

The main service that combines AI chat functionality with voice capabilities.

#### Key Methods:

```dart
// Initialize the service with an auth token
await VoiceAIService.initialize(authToken: 'your_token');

// Send a message and get voice response
final result = await VoiceAIService.chatWithVoice(
  message: 'How do I grow tomatoes?',
  sessionId: currentSessionId,
  voice: 'Zephyr',
);

// Send message without automatic audio playback
final result = await VoiceAIService.sendVoiceMessage(
  message: 'Tell me about pest control',
  voice: 'Zephyr',
  includeAudio: true,
);

// Get available voices
final voicesResult = await VoiceAIService.getAvailableVoices();

// Play audio from base64
await VoiceAIService.playAudio(base64AudioString);

// Stop audio playback
await VoiceAIService.stopAudio();

// Clear current session
await VoiceAIService.clearSession();
```

#### Response Format:

```dart
{
  'success': bool,
  'response': String,      // AI response text
  'audioBase64': String?,  // Base64 encoded audio data
  'sessionId': String,     // Current session ID
  'voiceUsed': String,     // Voice that was used
  'error': String?         // Error message if failed
}
```

### 2. Updated AI Advisory Page

The AI Advisory Page now includes:

#### Voice Mode Toggle Button
- Located in the message input area (mic icon)
- Indicates when voice mode is active
- Shows current voice selection

#### Voice Mode Indicator
- Displays when voice mode is enabled
- Shows selected voice
- Quick disable button

#### Automatic Features
- Responses are read aloud when voice mode is active
- Text responses are still displayed
- Session IDs are maintained for continuity

## Usage in AI Advisory Page

### Basic Setup

The voice functionality is automatically initialized when the page loads. No additional setup is required beyond the standard authentication.

### Enabling Voice Mode

1. **Click the Mic Icon**: Toggle voice mode on/off in the message input area
2. **Confirmation**: A snackbar shows voice mode status
3. **Send Message**: Type your message and send normally
4. **Auto Playback**: Response text appears and audio plays automatically

### Example Code

```dart
// In AIAdvisoryPageState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAuthentication();
    // Initialize voice service with auth token
    final authService = Provider.of<AuthService>(context, listen: false);
    VoiceAIService.initialize(authToken: authService.token!);
  });
}

// Voice toggle
void _toggleVoiceMode() {
  setState(() {
    _isUsingVoice = !_isUsingVoice;
  });
}

// Send message (handles both text and voice)
Future<void> _sendMessage() async {
  final result = _isUsingVoice
      ? await VoiceAIService.chatWithVoice(
          message: prompt,
          sessionId: _currentSessionId,
          voice: selectedVoice,
        )
      : await AIService.sendMessage(prompt);
  
  // Handle response...
}
```

## Backend API Endpoints

The service communicates with the following backend endpoints:

### Send Voice Message
```
POST /api/voice/chat/
Authorization: Token {auth_token}

Request:
{
  "message": "Your question",
  "session_id": "optional_session_id",
  "voice": "Zephyr",
  "include_audio": true
}

Response:
{
  "session_id": "uuid",
  "response": "AI response text",
  "text_response": "AI response text",
  "audio_base64": "encoded_audio_data",
  "audio": "encoded_audio_data",
  "voice_used": "Zephyr"
}
```

### Get Available Voices
```
GET /api/voice/voices/
Authorization: Token {auth_token}

Response:
{
  "voices": [
    {
      "name": "Zephyr",
      "description": "A natural male voice",
      "gender": "male"
    },
    ...
  ]
}
```

## Configuration

### Voice Selection

Currently, the default voice is 'Zephyr'. To change:

```dart
// In AIAdvisoryPageState
String selectedVoice = 'YourVoiceName'; // Change default

// Or dynamically load available voices
void _loadAvailableVoices() async {
  final result = await VoiceAIService.getAvailableVoices();
  if (result['success']) {
    setState(() {
      availableVoices = result['voices'];
    });
  }
}
```

### Backend URL

The service uses the configured backend URL:
```
https://agriguide-backend-79j2.onrender.com/api
```

To change, update the `_baseUrl` in `voice_ai_service.dart`.

## Error Handling

The service provides comprehensive error handling:

```dart
final result = await VoiceAIService.chatWithVoice(
  message: 'Your message',
);

if (!result['success']) {
  // Handle error
  String error = result['error'];
  
  if (result['requiresLogin'] == true) {
    // User needs to log in again
    Navigator.pushReplacementNamed(context, '/login');
  } else {
    // Show error to user
    showErrorDialog(error);
  }
}
```

## Audio Playback Control

### Stop Playback
```dart
await VoiceAIService.stopAudio();
```

### Check Audio State
```dart
PlayerState state = await VoiceAIService.getAudioState();
if (state == PlayerState.playing) {
  // Audio is playing
}
```

## Session Management

Voice messages maintain session continuity just like text messages:

```dart
// Sessions are automatically managed
// Current session ID is stored and used for all subsequent messages
String? currentSessionId = await VoiceAIService.getCurrentSessionId();

// Manually set a session
await VoiceAIService.setSessionId(sessionId);

// Clear session (start fresh conversation)
await VoiceAIService.clearSession();
```

## Resource Cleanup

Important: Always clean up resources when done:

```dart
@override
void dispose() {
  VoiceAIService.dispose(); // Dispose audio player
  super.dispose();
}
```

## Troubleshooting

### Audio Not Playing
- Check network connection
- Ensure audio data is valid base64
- Verify backend returns `audio_base64` field
- Check device audio settings

### No Response from Backend
- Verify authentication token is valid
- Check backend is running and accessible
- Review error message for details
- Check network connectivity

### Session Not Persisting
- Ensure `setSessionId` is called after receiving response
- Check SharedPreferences storage
- Verify token hasn't expired

## Requirements

- **Package Dependencies**:
  - `http`: For HTTP requests
  - `shared_preferences`: For storing session IDs
  - `audioplayers`: For audio playback
  - `provider`: For state management

- **Permissions** (Android):
  - `android.permission.INTERNET` (for backend communication)

- **Permissions** (iOS):
  - Internet connectivity

## Future Enhancements

Potential improvements:
- [ ] Speech-to-text for voice input
- [ ] Multiple voice options with preview
- [ ] Voice quality settings
- [ ] Audio playback controls (pause, resume, replay)
- [ ] Voice message history/bookmarking
- [ ] Offline audio caching

## Support

For issues or questions about the voice integration, check:
1. Backend voice API documentation
2. Audio player library documentation
3. Backend logs for API errors
