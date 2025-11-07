import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../services/ai_service.dart';
import '../../../../widgets/chat_history_panel.dart';
import 'package:agri_guide/services/ai_text_formmater.dart';

class AIAdvisoryPage extends StatefulWidget {
  const AIAdvisoryPage({super.key});

  @override
  State<AIAdvisoryPage> createState() => _AIAdvisoryPageState();
}

class _AIAdvisoryPageState extends State<AIAdvisoryPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Opens the chat history drawer
  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  /// Loads messages from local storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('ai_chat_messages');
      final savedSessionId = prefs.getString('current_session_id');

      if (messagesJson != null) {
        final List<dynamic> decoded = json.decode(messagesJson);
        setState(() {
          _messages.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
          _currentSessionId = savedSessionId;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Saves messages to local storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_chat_messages', json.encode(_messages));
      if (_currentSessionId != null) {
        await prefs.setString('current_session_id', _currentSessionId!);
      }
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  /// Sends a message to the AI
  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add({'text': prompt, 'isUser': true});
      _isLoading = true;
      _errorMessage = null;
      _controller.clear();
    });

    await _saveMessages();
    _scrollToBottom();

    // Send to backend
    final result = await AIService.sendMessage(prompt);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      // Add AI response
      setState(() {
        _messages.add({'text': result['response'], 'isUser': false});
        // Update session ID if returned
        if (result['session_id'] != null) {
          _currentSessionId = result['session_id'];
        }
      });

      await _saveMessages();
      _scrollToBottom();
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
  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clear local messages
      setState(() {
        _messages.clear();
        _errorMessage = null;
        _currentSessionId = null;
      });

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chat_messages');
      await prefs.remove('current_session_id');

      // Start new session on server
      await AIService.startNewSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chat cleared'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    }
  }

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
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('ai_chat_messages');
      await prefs.remove('current_session_id');
      
      await AIService.startNewSession();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Started new chat'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
      return;
    }

    // Load selected session
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Set the session ID in the service
      await AIService.setSessionId(sessionId);

      // Fetch chat history
      final result = await AIService.getChatHistory(sessionId);
      
      if (result['success'] == true) {
        final history = result['history'] as List<dynamic>? ?? [];
        
        setState(() {
          _currentSessionId = sessionId;
          _messages.clear();
          _messages.addAll(
            history.map((m) => {
              'text': m['message'] as String,
              'isUser': (m['role'] as String) == 'user',
            }),
          );
          _isLoading = false;
        });
        
        // Save to local storage
        await _saveMessages();
        _scrollToBottom();
        
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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
      child: Row(
        children: [
          // History button
          IconButton(
            icon: Icon(Icons.history, color: Colors.grey.shade600),
            onPressed: openDrawer,
            tooltip: 'Chat History',
          ),
          const SizedBox(width: 4),
          
          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Ask AgriGuide anything...',
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
    );
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