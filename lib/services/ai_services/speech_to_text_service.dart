import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

/// Service for handling Speech-to-Text functionality
/// Supports English and Sesotho languages
class SpeechToTextService {
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLanguage = 'en_US';

  // Callbacks
  Function(String)? onResult;
  Function(String)? onPartialResult;
  Function? onStart;
  Function? onStop;
  Function(String)? onError;

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  /// Initialize Speech-to-Text service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _speech = stt.SpeechToText();

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('🎤 STT Status: $status');
          if (status == 'listening') {
            _isListening = true;
            if (onStart != null) onStart!();
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
            if (onStop != null) onStop!();
          }
        },
        onError: (error) {
          debugPrint('❌ STT Error: ${error.errorMsg}');
          _isListening = false;
          if (onError != null) onError!(error.errorMsg);
        },
      );

      _isInitialized = available;
      
      if (available) {
        debugPrint('✅ Speech-to-Text initialized');
        // Print available locales
        final locales = await getAvailableLocales();
        debugPrint('📱 Available locales: ${locales.length}');
      } else {
        debugPrint('❌ Speech-to-Text not available');
      }

      return available;
    } catch (e) {
      debugPrint('❌ STT initialization error: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({String? language}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        if (onError != null) onError!('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      debugPrint('⚠️ Already listening');
      return;
    }

    // Set language if provided
    if (language != null) {
      setLanguage(language);
    }

    try {
      await _speech.listen(
        onResult: (result) {
          final recognizedWords = result.recognizedWords;
          
          if (result.finalResult) {
            debugPrint('✅ Final result: $recognizedWords');
            if (onResult != null) onResult!(recognizedWords);
          } else {
            debugPrint('🔄 Partial result: $recognizedWords');
            if (onPartialResult != null) onPartialResult!(recognizedWords);
          }
        },
        localeId: _currentLanguage,
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );

      _isListening = true;
      debugPrint('🎤 Started listening in language: $_currentLanguage');
    } catch (e) {
      debugPrint('❌ STT listen error: $e');
      if (onError != null) onError!('Failed to start listening: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isInitialized || !_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      debugPrint('⏹️ Stopped listening');
    } catch (e) {
      debugPrint('❌ STT stop error: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!_isInitialized || !_isListening) return;

    try {
      await _speech.cancel();
      _isListening = false;
      debugPrint('❌ Cancelled listening');
    } catch (e) {
      debugPrint('❌ STT cancel error: $e');
    }
  }

  /// Set language based on app language
  /// 'english' -> 'en_US', 'sesotho' -> 'st_ZA'
  void setLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'english':
        _currentLanguage = 'en_US';
        break;
      case 'sesotho':
        _currentLanguage = 'st_ZA'; // Sesotho (South Africa)
        break;
      default:
        _currentLanguage = 'en_US';
    }
    debugPrint('🌍 STT Language set to: $_currentLanguage');
  }

  /// Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return [];
    }

    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint('❌ STT getLocales error: $e');
      return [];
    }
  }

  /// Check if locale is available
  Future<bool> isLocaleAvailable(String locale) async {
    final locales = await getAvailableLocales();
    return locales.any((l) => l.localeId == locale);
  }

  /// Get last error
  String? getLastError() {
    if (!_isInitialized) return null;
    return _speech.lastError?.errorMsg;
  }

  /// Check if speech recognition is available
  Future<bool> hasPermission() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _speech.isAvailable;
  }

  /// Dispose service
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      if (_isListening) {
        await stopListening();
      }
      _isInitialized = false;
      debugPrint('🗑️ Speech-to-Text service disposed');
    } catch (e) {
      debugPrint('❌ STT dispose error: $e');
    }
  }

  // Getters
  String get currentLanguage => _currentLanguage;
}