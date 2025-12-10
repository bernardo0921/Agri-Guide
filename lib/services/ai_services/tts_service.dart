import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Text-to-Speech functionality
/// Supports English and Sesotho languages
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  late FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;

  // TTS Settings
  double _volume = 0.8;
  double _pitch = 1.0;
  double _speechRate = 0.5;
  String _currentLanguage = 'en-US'; // Default to English

  // Callbacks
  Function? onStart;
  Function? onComplete;
  Function? onError;
  Function(String)? onProgress;

  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  /// Initialize TTS service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    try {
      // Set default values
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setLanguage(_currentLanguage);

      // Android specific settings
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.awaitSpeakCompletion(true);

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        if (onStart != null) onStart!();
        debugPrint('🔊 TTS Started');
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        if (onComplete != null) onComplete!();
        debugPrint('✅ TTS Completed');
      });

      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        debugPrint('⏹️ TTS Cancelled');
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        debugPrint('⏸️ TTS Paused');
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        debugPrint('▶️ TTS Continued');
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        if (onError != null) onError!();
        debugPrint('❌ TTS Error: $msg');
      });

      _flutterTts.setProgressHandler((text, start, end, word) {
        if (onProgress != null) onProgress!(word);
      });

      _isInitialized = true;
      debugPrint('✅ TTS Service initialized');
    } catch (e) {
      debugPrint('❌ TTS initialization error: $e');
      _isInitialized = false;
    }
  }

  /// Speak text with automatic language detection
  Future<void> speak(String text, {String? language}) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    try {
      // Set language if provided
      if (language != null) {
        await setLanguage(language);
      }

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('❌ TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _isPaused = false;
    } catch (e) {
      debugPrint('❌ TTS stop error: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;
    
    try {
      await _flutterTts.pause();
      _isPaused = true;
    } catch (e) {
      debugPrint('❌ TTS pause error: $e');
    }
  }

  /// Resume speaking
  Future<void> resume() async {
    if (!_isInitialized || !_isPaused) return;
    
    try {
      // Note: flutter_tts doesn't have a resume method on Android
      // We need to use stop and speak again
      _isPaused = false;
    } catch (e) {
      debugPrint('❌ TTS resume error: $e');
    }
  }

  /// Set language based on app language
  /// 'english' -> 'en-US', 'sesotho' -> 'st-ZA'
  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await initialize();

    String ttsLanguage;
    
    switch (language.toLowerCase()) {
      case 'english':
        ttsLanguage = 'en-US';
        break;
      case 'sesotho':
        ttsLanguage = 'st-ZA'; // Sesotho (South Africa)
        break;
      default:
        ttsLanguage = 'en-US';
    }

    try {
      final isAvailable = await _flutterTts.isLanguageAvailable(ttsLanguage);
      
      if (isAvailable) {
        await _flutterTts.setLanguage(ttsLanguage);
        _currentLanguage = ttsLanguage;
        debugPrint('🌍 TTS Language set to: $ttsLanguage');
      } else {
        debugPrint('⚠️ Language $ttsLanguage not available, using default');
        await _flutterTts.setLanguage('en-US');
        _currentLanguage = 'en-US';
      }
    } catch (e) {
      debugPrint('❌ TTS setLanguage error: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) await initialize();
    
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _flutterTts.setVolume(_volume);
    } catch (e) {
      debugPrint('❌ TTS setVolume error: $e');
    }
  }

  /// Set pitch (0.5 to 2.0)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await initialize();
    
    _pitch = pitch.clamp(0.5, 2.0);
    try {
      await _flutterTts.setPitch(_pitch);
    } catch (e) {
      debugPrint('❌ TTS setPitch error: $e');
    }
  }

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();
    
    _speechRate = rate.clamp(0.0, 1.0);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (e) {
      debugPrint('❌ TTS setSpeechRate error: $e');
    }
  }

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    if (!_isInitialized) await initialize();
    
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (e) {
      debugPrint('❌ TTS getLanguages error: $e');
      return [];
    }
  }

  /// Get available voices
  Future<List<Map<String, String>>> getAvailableVoices() async {
    if (!_isInitialized) await initialize();
    
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(
        voices?.map((voice) => Map<String, String>.from(voice)) ?? []
      );
    } catch (e) {
      debugPrint('❌ TTS getVoices error: $e');
      return [];
    }
  }

  /// Set voice
  Future<void> setVoice(Map<String, String> voice) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _flutterTts.setVoice(voice);
    } catch (e) {
      debugPrint('❌ TTS setVoice error: $e');
    }
  }

  /// Check if language is installed
  Future<bool> isLanguageAvailable(String language) async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _flutterTts.isLanguageAvailable(language);
    } catch (e) {
      debugPrint('❌ TTS isLanguageAvailable error: $e');
      return false;
    }
  }

  /// Dispose TTS service
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    try {
      await stop();
      _isInitialized = false;
      debugPrint('🗑️ TTS Service disposed');
    } catch (e) {
      debugPrint('❌ TTS dispose error: $e');
    }
  }

  // Getters for current settings
  double get volume => _volume;
  double get pitch => _pitch;
  double get speechRate => _speechRate;
  String get currentLanguage => _currentLanguage;
}