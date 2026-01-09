// ai_advisory_page.dart - Complete TTS Integration
// NOTE: This file works with enhanced_chat_message_bubble.dart
import 'dart:io';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/core/language/app_language.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agri_guide/services/ai_services/ai_service.dart';
import 'package:agri_guide/widgets/chat_history_panel.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/services/ai_services/tts_service.dart';
import 'package:agri_guide/services/ai_services/speech_to_text_service.dart';
import 'package:agri_guide/widgets/enhanced_chat_message_bubble.dart';

enum ChatMode { text, voice }

class AIAdvisoryPage extends StatefulWidget {
  const AIAdvisoryPage({super.key});

  @override
  State<AIAdvisoryPage> createState() => AIAdvisoryPageState();
}

class AIAdvisoryPageState extends State<AIAdvisoryPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _imagePicker = ImagePicker();

  static const String baseUrl =
      'https://agriguide-backend-79j2.onrender.com/api';

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _errorMessage;
  String? _currentSessionId;
  File? _selectedImage;

  String _streamingText = '';
  int _currentStreamingMessageIndex = -1;

  // TTS & STT
  final TTSService _ttsService = TTSService();
  final SpeechToTextService _sttService = SpeechToTextService();
  ChatMode _chatMode = ChatMode.text;
  bool _isTTSSpeaking = false;
  bool _isSTTListening = false;
  String _partialSTTResult = '';

  @override
  void initState() {
    super.initState();
    _initializeTTSAndSTT();
  }

  Future<void> _initializeTTSAndSTT() async {
    await _ttsService.initialize();
    await _sttService.initialize();

    _ttsService.onStart = () {
      if (mounted) setState(() => _isTTSSpeaking = true);
    };

    _ttsService.onComplete = () {
      if (mounted) setState(() => _isTTSSpeaking = false);
    };

    _ttsService.onError = () {
      if (mounted) setState(() => _isTTSSpeaking = false);
    };

    _sttService.onStart = () {
      if (mounted) {
        setState(() {
          _isSTTListening = true;
          _partialSTTResult = '';
        });
      }
    };

    _sttService.onStop = () {
      if (mounted) {
        setState(() {
          _isSTTListening = false;
          _partialSTTResult = '';
        });
      }
    };

    _sttService.onPartialResult = (result) {
      if (mounted) setState(() => _partialSTTResult = result);
    };

    _sttService.onResult = (result) {
      if (mounted) {
        setState(() {
          _controller.text = result;
          _partialSTTResult = '';
          _isSTTListening = false;
        });
        if (_chatMode == ChatMode.voice) _sendMessage();
      }
    };

    _sttService.onError = (error) {
      if (mounted) {
        setState(() {
          _isSTTListening = false;
          _partialSTTResult = '';
        });
        _showSnackBar(error, Colors.red);
      }
    };
  }

  @override
  void dispose() {
    // Dispose controllers
    _controller.dispose();
    _scrollController.dispose();

    // Clear callbacks so services won't call back into this widget after dispose
    try {
      _ttsService.onStart = null;
      _ttsService.onComplete = null;
      _ttsService.onError = null;
      _ttsService.onProgress = null;
    } catch (_) {}

    try {
      _sttService.onStart = null;
      _sttService.onStop = null;
      _sttService.onPartialResult = null;
      _sttService.onResult = null;
      _sttService.onError = null;
    } catch (_) {}

    // Stop and dispose services (fire-and-forget; services handle safety)
    try {
      _ttsService.stop();
      _ttsService.dispose();
    } catch (_) {}

    try {
      _sttService.stopListening();
      _sttService.dispose();
    } catch (_) {}

    super.dispose();
  }

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  String _getBackendLanguage() {
    return AppNotifiers.languageNotifier.value == AppLanguage.english
        ? 'english'
        : 'sesotho';
  }

  void _toggleChatMode() {
    setState(() {
      if (_chatMode == ChatMode.text) {
        _chatMode = ChatMode.voice;
        _showSnackBar(
          'Voice mode activated',
          Theme.of(context).colorScheme.primary,
        );
      } else {
        _chatMode = ChatMode.text;
        _ttsService.stop();
        _sttService.stopListening();
        _showSnackBar(
          'Text mode activated',
          Theme.of(context).colorScheme.primary,
        );
      }
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isSTTListening) {
      await _sttService.stopListening();
    } else {
      await _sttService.startListening(language: _getBackendLanguage());
    }
  }

  Future<void> _toggleTTSPlayback(String text) async {
    if (_isTTSSpeaking) {
      await _ttsService.stop();
    } else {
      await _ttsService.speak(text, language: _getBackendLanguage());
    }
  }

  Future<void> _sendMessage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      _showErrorDialog('Please log in to send messages');
      return;
    }

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add({'text': prompt, 'isUser': true});
      _isStreaming = true;
      _errorMessage = null;
      _controller.clear();
      _messages.add({'text': '', 'isUser': false, 'isStreaming': true});
      _currentStreamingMessageIndex = _messages.length - 1;
      _streamingText = '';
    });

    _scrollToBottom();

    try {
      final requestData = {
        'message': prompt,
        'language': _getBackendLanguage(),
        if (_currentSessionId != null) 'session_id': _currentSessionId,
      };

      String fullAIResponse = '';

      await for (var event in AIService.sendMessageStream(
        requestData: requestData,
      )) {
        if (!mounted) break;

        if (event['success'] == true) {
          if (event['type'] == 'session_id') {
            final newSessionId = event['sessionId'];
            if (_currentSessionId == null && newSessionId != null) {
              setState(() => _currentSessionId = newSessionId);
            }
          } else if (event['type'] == 'chunk') {
            setState(() {
              _streamingText = event['fullText'];
              if (_currentStreamingMessageIndex >= 0) {
                _messages[_currentStreamingMessageIndex]['text'] =
                    _streamingText;
              }
            });
            _scrollToBottom();
          } else if (event['type'] == 'done') {
            fullAIResponse = event['response'];
            setState(() {
              if (_currentStreamingMessageIndex >= 0) {
                _messages[_currentStreamingMessageIndex]['text'] =
                    fullAIResponse;
                _messages[_currentStreamingMessageIndex]['isStreaming'] = false;
              }
              _isStreaming = false;
              _currentStreamingMessageIndex = -1;
              _streamingText = '';
            });
            _scrollToBottom();

            if (_chatMode == ChatMode.voice && fullAIResponse.isNotEmpty) {
              await _ttsService.speak(
                fullAIResponse,
                language: _getBackendLanguage(),
              );
            }
          }
        } else {
          setState(() {
            _errorMessage = event['error'] ?? 'Unknown error occurred';
            _isStreaming = false;
            if (_currentStreamingMessageIndex >= 0) {
              _messages.removeAt(_currentStreamingMessageIndex);
              _currentStreamingMessageIndex = -1;
            }
          });
          if (mounted) {
            _showErrorDialog(event['error'] ?? 'Failed to get response');
          }
          break;
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isStreaming = false;
        if (_currentStreamingMessageIndex >= 0) {
          _messages.removeAt(_currentStreamingMessageIndex);
          _currentStreamingMessageIndex = -1;
        }
      });
      if (mounted) _showErrorDialog('Connection error: $e');
    }
  }

  Future<void> _sendImageMessage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn || _selectedImage == null) return;

    final message = _controller.text.trim();

    setState(() {
      _messages.add({
        'text': message.isEmpty ? 'Please analyze this image' : message,
        'isUser': true,
        'image': _selectedImage,
      });
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });

    _scrollToBottom();

    final result = await AIService.sendImageMessage(
      _selectedImage!,
      message: message.isEmpty ? null : message,
      language: _getBackendLanguage(),
    );

    setState(() {
      _selectedImage = null;
      _isLoading = false;
    });

    if (result['success']) {
      final aiResponse = result['response'] as String;

      setState(() {
        _messages.add({'text': aiResponse, 'isUser': false});
        if (result['sessionId'] != null) {
          _currentSessionId = result['sessionId'];
        }
      });

      _scrollToBottom();

      if (_chatMode == ChatMode.voice) {
        await _ttsService.speak(aiResponse, language: _getBackendLanguage());
      }
    } else {
      setState(
        () => _errorMessage = result['error'] ?? 'Unknown error occurred',
      );
      if (mounted) {
        _showErrorDialog(result['error'] ?? 'Failed to get response');
      }
    }
  }

  // Pick an image from camera or gallery then send it via existing flow
  Future<void> _pickAndSendImage() async {
    // present options
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(null),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _selectedImage = file;
      });

      // send immediately
      await _sendImageMessage();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to pick image: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // See next artifact for remaining UI methods...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.status == AuthStatus.unknown ||
            !authService.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!authService.isLoggedIn) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          });
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surface,
          drawer: Drawer(
            child: ChatHistoryPanel(
              onSessionSelected: (id) async {
                // Drawer is already closed by ChatHistoryPanel; proceed to handle selection

                try {
                  if (id == 'new') {
                    // Start a fresh session
                    await AIService.startNewSession();

                    if (!mounted) return;

                    setState(() {
                      _currentSessionId = null;
                      _messages.clear();
                      _isStreaming = false;
                      _errorMessage = null;
                    });

                    _showSnackBar(AppStrings.startNewChat, Theme.of(context).colorScheme.primary);
                    return;
                  }

                  // Load existing session history
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  final result = await AIService.getChatHistory(id);

                  if (!mounted) return;

                  if (result['success'] == true) {
                    final history = result['history'] as List? ?? [];

                    // Map backend history items to internal message format
                    final List<Map<String, dynamic>> loaded = [];

                    for (var item in history) {
                      if (item is Map) {
                        // Try multiple possible keys for flexibility
                        final role = (item['role'] ?? item['sender'] ?? '')?.toString().toLowerCase();
                        final text = (item['message'] ?? item['text'] ?? item['content'] ?? '')?.toString() ?? '';
                        final imageUrl = item['image_url'] ?? item['image'];

                        final isUser = role == 'user' || role == 'u' || item['is_user'] == true || item['from'] == 'user';

                        final msg = <String, dynamic>{
                          'text': text,
                          'isUser': isUser,
                          'isStreaming': false,
                        };

                        if (imageUrl != null) msg['imageUrl'] = imageUrl;

                        loaded.add(msg);
                      }
                    }

                    // Persist session id locally
                    await AIService.setSessionId(id);

                    setState(() {
                      _currentSessionId = id;
                      _messages.clear();
                      _messages.addAll(loaded);
                      _isLoading = false;
                    });

                    // Scroll to end to show latest messages
                    _scrollToBottom();
                  } else {
                    setState(() {
                      _isLoading = false;
                      _errorMessage = result['error'] ?? 'Failed to load session history';
                    });

                    if (mounted) {
                      _showErrorDialog(result['error'] ?? 'Failed to load session history');
                    }
                  }
                } catch (e) {
                  if (!mounted) return;
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Failed to load session: $e';
                  });
                  _showErrorDialog('Failed to load session: $e');
                }
              },
              currentSessionId: _currentSessionId,
            ),
          ),
          body: Column(
            children: [
              _buildModeToggle(),
              if (_errorMessage != null) _buildErrorBanner(),
              if (_isSTTListening) _buildSTTIndicator(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return EnhancedChatMessageBubble(
                            message: msg['text'],
                            isUser: msg['isUser'],
                            imageFile: msg['image'] as File?,
                            imageUrl: msg['imageUrl'] as String?,
                            isStreaming: msg['isStreaming'] ?? false,
                            showTTSButton:
                                !msg['isUser'] && _chatMode == ChatMode.voice,
                            isTTSSpeaking: _isTTSSpeaking,
                            onTTSToggle: () => _toggleTTSPlayback(msg['text']),
                          );
                        },
                      ),
              ),
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _chatMode == ChatMode.text ? Icons.chat_bubble : Icons.mic,
            color: colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _chatMode == ChatMode.text ? 'Text Mode' : 'Voice Mode',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _chatMode == ChatMode.voice,
            onChanged: (_) => _toggleChatMode(),
            activeThumbColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSTTIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.mic, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listening...',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_partialSTTResult.isNotEmpty)
                  Text(_partialSTTResult, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          _PulsingDot(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 80, height: 80),
          const SizedBox(height: 16),
          Text(
            AppStrings.aiGreetings,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(AppStrings.aiAdvisoryIntro, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            _chatMode == ChatMode.voice
                ? 'Tap the microphone to speak'
                : AppStrings.aiSdvisoryIntro2,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: openDrawer,
            icon: const Icon(Icons.history),
            label: Text(AppStrings.viewChatHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.primary),
            onPressed: openDrawer,
          ),
          if (_chatMode == ChatMode.text)
            IconButton(
              icon: Icon(Icons.image, color: colorScheme.primary),
              onPressed: (_isLoading || _isStreaming)
                  ? null
                  : _pickAndSendImage,
            ),
          if (_chatMode == ChatMode.voice)
            IconButton(
              icon: Icon(
                _isSTTListening ? Icons.stop : Icons.mic,
                color: _isSTTListening ? Colors.red : colorScheme.primary,
              ),
              onPressed: (_isLoading || _isStreaming)
                  ? null
                  : _toggleVoiceInput,
            ),
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isLoading && !_isStreaming && !_isSTTListening,
              decoration: InputDecoration(
                hintText: _chatMode == ChatMode.voice
                    ? 'Tap mic or type...'
                    : AppStrings.captionInAiChatTextBox,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: (_isLoading || _isStreaming || _isSTTListening)
                  ? null
                  : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// Pulsing Dot Animation
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(_controller),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
