import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../services/ai_service.dart';
import '../../../services/voice_ai_service.dart';
import '../../../widgets/chat_history_panel.dart';
import 'package:agri_guide/services/ai_text_formmater.dart';
import 'package:agri_guide/services/auth_service.dart';

class AIAdvisoryPage extends StatefulWidget {
  const AIAdvisoryPage({super.key});

  @override
  State<AIAdvisoryPage> createState() => AIAdvisoryPageState();
}

class AIAdvisoryPageState extends State<AIAdvisoryPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentSessionId;
  bool _isChatHistoryPanelOpen = false;
  bool _isUsingVoice = false;
  String selectedVoice = 'Zephyr';

  @override
  void initState() {
    super.initState();
    // Check authentication when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
    // REMOVED: Local message loading - messages now come from backend only
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    VoiceAIService.dispose();
    super.dispose();
  }

  /// Opens the chat history drawer
  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Sends a message to the AI (text or voice)
  Future<void> _sendMessage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      _showErrorDialog('Please log in to send messages');
      return;
    }

    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // Add user message to UI
    setState(() {
      _messages.add({'text': prompt, 'isUser': true});
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });

    _scrollToBottom();

    // Use voice or text service based on mode
    final result = _isUsingVoice
        ? await VoiceAIService.chatWithVoice(
            message: prompt,
            sessionId: _currentSessionId,
            voice: selectedVoice,
          )
        : await AIService.sendMessage(prompt);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Add AI response to UI
      setState(() {
        _messages.add({'text': result['response'], 'isUser': false});
        // Update session ID if returned
        if (result['sessionId'] != null) {
          _currentSessionId = result['sessionId'];
        }
      });

      _scrollToBottom();

      print('✅ Message sent successfully');
      print('📋 Current session: $_currentSessionId');
      print('💬 Total messages in UI: ${_messages.length}');

      if (_isUsingVoice) {
        print('🎵 Audio played');
      }
    } else {
      // Handle error
      setState(() {
        _errorMessage = result['error'] ?? 'Unknown error occurred';
      });

      // Show error dialog
      if (mounted) {
        _showErrorDialog(result['error'] ?? 'Failed to get response');
      }
    }
  }

  /// Shows error dialog
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

  /// Clears the chat history
  /// Scrolls to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle selecting a session from the history panel
  Future<void> _handleSessionSelect(String sessionId) async {
    // Close the drawer
    Navigator.of(context).pop();

    if (sessionId == 'new') {
      // Start fresh chat
      setState(() {
        _currentSessionId = null;
        _messages.clear();
        _errorMessage = null;
      });

      await AIService.startNewSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Started new chat'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }

      print('🆕 New session started');
      return;
    }

    // Load selected session from backend
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Set the session ID in the service
      await AIService.setSessionId(sessionId);

      // Fetch chat history from backend
      final result = await AIService.getChatHistory(sessionId);

      if (result['success'] == true) {
        final history = result['history'] as List<dynamic>? ?? [];

        setState(() {
          _currentSessionId = sessionId;
          _messages.clear();
          _messages.addAll(
            history.map(
              (m) => {
                'text': m['message'] as String,
                'isUser': (m['role'] as String) == 'user',
              },
            ),
          );
          _isLoading = false;
        });

        _scrollToBottom();

        // print('📖 Loaded session $sessionId with ${history.length} messages');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded chat with ${history.length} messages'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['error'] ?? 'Failed to load chat history';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading session: $e';
      });
    }
  }

  /// Check authentication status
  void _checkAuthentication() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to use the AI Assistant'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

  /// Toggle the chat history panel
  void toggleChatHistoryPanel() {
    setState(() {
      _isChatHistoryPanelOpen = !_isChatHistoryPanelOpen;
    });
    if (_isChatHistoryPanelOpen) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      drawer: Drawer(
        child: ChatHistoryPanel(
          onSessionSelected: _handleSessionSelect,
          currentSessionId: _currentSessionId,
        ),
      ),
      body: Column(
        children: [
          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
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
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return EnhancedChatMessageBubble(
                        message: msg['text'],
                        isUser: msg['isUser'],
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_isLoading) _buildTypingIndicator(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 80, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            'Hello! I\'m your AgriGuide AI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about farming and agriculture',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: openDrawer,
            icon: const Icon(Icons.history),
            label: const Text('View Chat History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = (value + delay) % 1.0;
        final opacity = (animValue < 0.5)
            ? animValue * 2
            : (1.0 - animValue) * 2;

        return Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (_isLoading && mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice mode indicator
          if (_isUsingVoice)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, size: 18, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voice mode: $selectedVoice',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isUsingVoice = false;
                      });
                    },
                    child: const Text('Disable'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Input row
          Row(
            children: [
              // History button
              IconButton(
                icon: Icon(Icons.history, color: Colors.green.shade600),
                onPressed: openDrawer,
                tooltip: 'Chat History',
              ),

              // Text input
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: _isUsingVoice
                        ? 'Ask me anything (voice response)...'
                        : 'Ask AgriGuide anything...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(
                        color: Colors.green.shade300,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Voice mode toggle button
              IconButton(
                icon: Icon(
                  _isUsingVoice ? Icons.mic : Icons.mic_none,
                  color: _isUsingVoice
                      ? Colors.blue.shade600
                      : Colors.grey.shade500,
                ),
                onPressed: _isLoading ? null : _toggleVoiceMode,
                tooltip: _isUsingVoice
                    ? 'Disable voice'
                    : 'Enable voice responses',
              ),

              // Send button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade700],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Toggle voice mode on/off
  void _toggleVoiceMode() {
    setState(() {
      _isUsingVoice = !_isUsingVoice;
    });

    if (_isUsingVoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice mode enabled - responses will be read aloud with $selectedVoice voice',
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Enhanced Chat Message Bubble
class EnhancedChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const EnhancedChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context, message),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? Colors.green.shade600 : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      )
                    : AITextFormatter(
                        text: message,
                        baseStyle: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 15,
                          height: 1.4,
                        ),
                        linkColor: Colors.blue,
                        codeBackgroundColor: Colors.grey.shade200,
                        codeTextColor: Colors.red.shade700,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? Colors.green.shade600 : Colors.grey.shade300,
      child: Icon(
        isUser ? Icons.person : Icons.eco,
        size: 18,
        color: isUser ? Colors.white : Colors.green.shade700,
      ),
    );
  }
}
