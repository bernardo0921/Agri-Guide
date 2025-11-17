/// Example Usage of Voice AI Service in AI Advisory Page
///
/// NOTE: This is example code for reference. These examples show how to use
/// the VoiceAIService in various scenarios.

// ==============================================================================
// INITIALIZATION
// ==============================================================================

// In your auth service or app initialization:
// void initializeVoiceAI(String authToken) {
//   VoiceAIService.initialize(authToken: authToken);
// }

// ==============================================================================
// BASIC USAGE IN AI ADVISORY PAGE
// ==============================================================================

// The AIAdvisoryPage has built-in voice support that works like this:

// 1. User toggles voice mode (mic button in message input area)
// 2. User types a message and sends it
// 3. If voice mode is enabled:
//    - Message is sent via VoiceAIService.chatWithVoice()
//    - Response text appears in chat
//    - Audio is automatically played
// 4. If voice mode is disabled:
//    - Message is sent via AIService.sendMessage() (text only)
//    - Response text appears in chat

// ==============================================================================
// ADVANCED USAGE EXAMPLES
// ==============================================================================

/*
// Example 1: Send a voice message and handle response manually
Future<void> sendVoiceMessageManually() async {
  final result = await VoiceAIService.chatWithVoice(
    message: 'What is the best time to plant rice?',
    voice: 'Zephyr',
  );
  
  if (result['success']) {
    print('Response: ${result['response']}');
    print('Audio played automatically');
    print('Session: ${result['sessionId']}');
  } else {
    print('Error: ${result['error']}');
  }
}

// Example 2: Send message without automatic audio playback
Future<void> sendVoiceMessageWithoutAutoPlay() async {
  final result = await VoiceAIService.sendVoiceMessage(
    message: 'Tell me about soil health',
    voice: 'Zephyr',
    includeAudio: true,
  );
  
  if (result['success']) {
    // Handle audio yourself
    if (result['audioBase64'] != null) {
      await VoiceAIService.playAudio(result['audioBase64']);
      // ... audio will play
    }
  }
}

// Example 3: Get available voices and let user choose
Future<void> selectVoiceFromAvailable() async {
  final voicesResult = await VoiceAIService.getAvailableVoices();
  
  if (voicesResult['success']) {
    final voices = voicesResult['voices'] as List;
    
    for (final voice in voices) {
      print('Voice: ${voice['name']}');
      print('  - Gender: ${voice['gender']}');
      print('  - Description: ${voice['description']}');
    }
    
    // Use the first available voice
    if (voices.isNotEmpty) {
      final selectedVoice = voices[0]['name'];
      // await chatWithSelectedVoice(selectedVoice);
    }
  }
}

// Example 4: Maintain conversation with session ID
Future<void> multiTurnConversation() async {
  String? sessionId;
  
  // First message
  var result = await VoiceAIService.chatWithVoice(
    message: 'How do I prepare soil for planting?',
  );
  
  if (result['success']) {
    sessionId = result['sessionId'];
    print('Session created: $sessionId');
    print('Response 1: ${result['response']}');
  }
  
  // Follow-up message in same session
  if (sessionId != null) {
    result = await VoiceAIService.chatWithVoice(
      message: 'What about fertilizer?',
      sessionId: sessionId,
    );
    
    if (result['success']) {
      print('Response 2: ${result['response']}');
      print('Still in session: ${result['sessionId']}');
    }
  }
}

// Example 5: Stop audio playback manually
Future<void> stopAudioPlayback() async {
  try {
    await VoiceAIService.stopAudio();
    print('Audio stopped');
  } catch (e) {
    print('Error stopping audio: $e');
  }
}

// Example 6: Check current session and switch sessions
Future<void> sessionManagement() async {
  // Get current session
  String? currentSession = await VoiceAIService.getCurrentSessionId();
  print('Current session: $currentSession');
  
  // Switch to a different session
  String newSessionId = 'some-session-uuid';
  await VoiceAIService.setSessionId(newSessionId);
  print('Switched to session: $newSessionId');
  
  // Clear session (start fresh)
  await VoiceAIService.clearSession();
  print('Session cleared - next message will start new session');
}

// Example 7: Use in a widget with error handling
Future<void> sendVoiceMessageWithCompleteErrorHandling() async {
  try {
    final result = await VoiceAIService.chatWithVoice(
      message: 'How do I control pests naturally?',
      voice: 'Zephyr',
    );
    
    if (!result['success']) {
      if (result['requiresLogin'] == true) {
        // Handle authentication failure
        print('User needs to log in again');
        // Navigate to login page
      } else {
        // Handle other errors
        print('Error: ${result['error']}');
        // Show error to user
      }
    } else {
      // Success
      print('Message: ${result['response']}');
      print('Audio status: playing');
    }
  } catch (e) {
    print('Unexpected error: $e');
  }
}

// Example 8: Stream multiple messages with voice
Future<void> streamMultipleQuestions(List<String> questions) async {
  String? sessionId;
  
  for (final question in questions) {
    print('Sending: $question');
    
    final result = await VoiceAIService.chatWithVoice(
      message: question,
      sessionId: sessionId,
    );
    
    if (result['success']) {
      sessionId = result['sessionId'];
      print('Response: ${result['response']}\n');
      
      // Add delay to avoid overwhelming the API
      await Future.delayed(const Duration(seconds: 2));
    } else {
      print('Error: ${result['error']}');
      break;
    }
  }
}
*/

// ==============================================================================
// INTEGRATION WITH AI ADVISORY PAGE
// ==============================================================================

// How voice works in AIAdvisoryPage:

// 1. Voice Mode Toggle:
//    - User clicks the mic icon in message input area
//    - Sets _isUsingVoice = true/false
//    - Shows voice indicator when enabled

// 2. Sending Messages:
//    final result = _isUsingVoice
//        ? await VoiceAIService.chatWithVoice(
//            message: prompt,
//            sessionId: _currentSessionId,
//            voice: selectedVoice,
//          )
//        : await AIService.sendMessage(prompt);

// 3. Displaying Responses:
//    - Response text added to _messages
//    - If voice mode and audio available, audio plays automatically
//    - Session ID updated for next message

// 4. Session Management:
//    - _currentSessionId tracks active session
//    - Persisted to SharedPreferences for continuity
//    - Can be cleared for new conversation

// ==============================================================================
// CLEANUP AND DISPOSAL
// ==============================================================================

// Always call this in dispose():
// VoiceAIService.dispose();

// ==============================================================================
// CONFIGURATION
// ==============================================================================

// To use different voices, modify in AIAdvisoryPageState:
// String selectedVoice = 'YourVoiceName'; // Default voice

// To load voices dynamically:
// Future<void> loadAvailableVoices() async {
//   final result = await VoiceAIService.getAvailableVoices();
//   if (result['success']) {
//     // Update UI with available voices
//   }
// }
