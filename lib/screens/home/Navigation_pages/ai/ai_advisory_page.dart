// ai_advisory_page.dart - With Language Selection Support
import 'dart:io';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../services/ai_service.dart';
import '../../../../../widgets/chat_history_panel.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isStreaming = false;
  String? _errorMessage;
  String? _currentSessionId;
  File? _selectedImage;

  String _streamingText = '';
  int _currentStreamingMessageIndex = -1;
  
  // Language selection state
  String _selectedLanguage = 'english'; // Default language
  final List<Map<String, String>> _availableLanguages = [
    {'value': 'english', 'label': 'English'},
    {'value': 'sesotho', 'label': 'Sesotho'},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _showLanguageSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text('Select Language', style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 20),
            ..._availableLanguages.map((lang) => ListTile(
              leading: Radio<String>(
                value: lang['value']!,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                  _showSnackBar(
                    'Language changed to ${lang['label']}',
                    colorScheme.primary,
                  );
                },
              ),
              title: Text(lang['label']!),
              onTap: () {
                setState(() {
                  _selectedLanguage = lang['value']!;
                });
                Navigator.pop(context);
                _showSnackBar(
                  'Language changed to ${lang['label']}',
                  colorScheme.primary,
                );
              },
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _showImagePreviewDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _showImagePreviewDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Image Preview', style: theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                  height: 300,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a message (optional)...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _sendImageMessage();
                      },
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose Image Source', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colorScheme.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: colorScheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImageMessage() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isLoggedIn) {
      _showErrorDialog('Please log in to send messages');
      return;
    }

    if (_selectedImage == null) return;

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

    // Include language parameter
    final result = await AIService.sendImageMessage(
      _selectedImage!,
      message: message.isEmpty ? null : message,
      language: _selectedLanguage, // Pass selected language
    );

    setState(() {
      _selectedImage = null;
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _messages.add({'text': result['response'], 'isUser': false});
        if (result['sessionId'] != null) {
          _currentSessionId = result['sessionId'];
        }
      });
      _scrollToBottom();
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Unknown error occurred';
      });
      if (mounted) {
        _showErrorDialog(result['error'] ?? 'Failed to get response');
      }
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
      // Include language parameter
      final requestData = {
        'message': prompt,
        'language': _selectedLanguage, // Pass selected language
        if (_currentSessionId != null) 'session_id': _currentSessionId,
      };

      await for (var event in AIService.sendMessageStream(
        requestData: requestData,
      )) {
        if (!mounted) break;

        if (event['success'] == true) {
          if (event['type'] == 'session_id') {
            final newSessionId = event['sessionId'];
            if (_currentSessionId == null && newSessionId != null) {
              setState(() {
                _currentSessionId = newSessionId;
              });
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
            setState(() {
              if (_currentStreamingMessageIndex >= 0) {
                _messages[_currentStreamingMessageIndex]['text'] =
                    event['response'];
                _messages[_currentStreamingMessageIndex]['isStreaming'] = false;
              }
              _isStreaming = false;
              _currentStreamingMessageIndex = -1;
              _streamingText = '';
            });
            _scrollToBottom();
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
      if (mounted) {
        _showErrorDialog('Connection error: $e');
      }
    }
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
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Error', style: theme.textTheme.titleLarge),
        content: Text(message, style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Future<void> _handleSessionSelect(String sessionId) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Navigator.of(context).pop();

    if (sessionId == 'new') {
      setState(() {
        _currentSessionId = null;
        _messages.clear();
        _errorMessage = null;
      });
      await AIService.startNewSession();
      if (mounted) {
        _showSnackBar('Started new chat', colorScheme.primary);
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AIService.setSessionId(sessionId);
      final result = await AIService.getChatHistory(sessionId);

      if (result['success'] == true) {
        final history = result['history'] as List<dynamic>? ?? [];

        setState(() {
          _currentSessionId = sessionId;
          _messages.clear();
          _messages.addAll(
            history.map((m) {
              return {
                'text': m['message'] as String,
                'isUser': (m['role'] as String) == 'user',
                'imageUrl': m['image_url'] as String?,
              };
            }),
          );
          _isLoading = false;
        });

        _scrollToBottom();

        if (mounted) {
          _showSnackBar(
            'Loaded chat with ${history.length} messages',
            colorScheme.primary,
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

  String _getInitials(AuthService authService) {
    final user = authService.user;

    if (user != null) {
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
      }

      final username = user['username'] as String? ?? '';
      if (username.isNotEmpty) {
        return username
            .substring(0, username.length > 2 ? 2 : username.length)
            .toUpperCase();
      }
    }

    return 'U';
  }

  String? _getProfilePictureUrl(AuthService authService) {
    final user = authService.user;
    if (user == null) return null;

    final profilePicture = user['profile_picture'] as String?;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (profilePicture.startsWith('http')) {
        return profilePicture;
      }
      return '$baseUrl$profilePicture';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.status == AuthStatus.unknown) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          );
        }

        if (!authService.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          );
        }

        final String? userProfileUrl = _getProfilePictureUrl(authService);
        final String? userInitials = _getInitials(authService);

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: colorScheme.surface,
          drawer: Drawer(
            child: ChatHistoryPanel(
              onSessionSelected: _handleSessionSelect,
              currentSessionId: _currentSessionId,
            ),
          ),
          body: Column(
            children: [
              if (_errorMessage != null) _buildErrorBanner(),
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
                          final isUserMessage = msg['isUser'];

                          return EnhancedChatMessageBubble(
                            message: msg['text'],
                            isUser: isUserMessage,
                            imageFile: msg['image'] as File?,
                            imageUrl: msg['imageUrl'] as String?,
                            isStreaming: msg['isStreaming'] ?? false,
                            userProfileUrl: isUserMessage
                                ? userProfileUrl
                                : null,
                            userInitials: isUserMessage ? userInitials : null,
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

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);

    return Container(
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade700,
              ),
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
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo.png', width: 80, height: 80),
          const SizedBox(height: 16),
          Text(AppStrings.aiGreetings, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            AppStrings.aiAdvisoryIntro,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.aiSdvisoryIntro2,
            style: theme.textTheme.bodyMedium?.copyWith(
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get current language label
    final currentLangLabel = _availableLanguages
        .firstWhere((lang) => lang['value'] == _selectedLanguage)['label'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.outline.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Language indicator bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Language: $currentLangLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _showLanguageSelector,
                  child: Icon(
                    Icons.edit,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          // Input row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.history, color: colorScheme.primary),
                onPressed: openDrawer,
                tooltip: AppStrings.chatHistory,
              ),
              IconButton(
                icon: Icon(Icons.image, color: colorScheme.primary),
                onPressed: (_isLoading || _isStreaming)
                    ? null
                    : _showImageSourceDialog,
                tooltip: 'Share Image',
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  enabled: !_isLoading && !_isStreaming,
                  decoration: InputDecoration(
                    hintText: AppStrings.captionInAiChatTextBox,
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
                      colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: (_isLoading || _isStreaming) ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// EnhancedChatMessageBubble - Unchanged (keeping existing code)
class EnhancedChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final File? imageFile;
  final String? imageUrl;
  final bool isStreaming;
  final String? userProfileUrl;
  final String? userInitials;

  const EnhancedChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.imageFile,
    this.imageUrl,
    this.isStreaming = false,
    this.userProfileUrl,
    this.userInitials,
  });

  void _copyToClipboard(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final hasImage = imageFile != null || imageUrl != null;
    final hasText = message.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context),
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context, message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary
                      : (isDarkMode ? colorScheme.surface : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.outline.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasImage) _buildImageSection(context, hasText),
                    if (hasText && !hasImage) _buildTextSection(context),
                    if (!isUser && hasImage && hasText)
                      _buildTextSection(context),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, bool hasText) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(hasText ? 0 : (isUser ? 4 : 16)),
            bottomRight: Radius.circular(hasText ? 0 : (isUser ? 16 : 4)),
          ),
          child: GestureDetector(
            onTap: () => _showImageFullScreen(context),
            child: imageFile != null
                ? Image.file(
                    imageFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stacktrace) {
                      return Container(
                        height: 250,
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (hasText && imageFile != null || imageUrl != null)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTimestamp(context),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUser)
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.4,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AITextFormatter(
                    text: message,
                    baseStyle: theme.textTheme.bodyMedium!.copyWith(
                      height: 1.4,
                    ),
                    linkColor: Colors.blue,
                    codeBackgroundColor: isDarkMode
                        ? colorScheme.surface.withOpacity(0.5)
                        : Colors.grey.shade200,
                    codeTextColor: Colors.red.shade700,
                  ),
                ),
                if (isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildTypingCursor(context),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: _buildTimestamp(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeString,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isUser
                ? Colors.white.withOpacity(0.8)
                : theme.textTheme.bodySmall?.color,
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 4),
          Icon(Icons.done_all, size: 14, color: Colors.blue.shade300),
        ],
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isUser ? colorScheme.primary : colorScheme.surface;

    if (isUser) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: userProfileUrl != null ? Colors.transparent : bgColor,
        backgroundImage: userProfileUrl != null
            ? NetworkImage(userProfileUrl!)
            : null,
        onBackgroundImageError: userProfileUrl != null
            ? (exception, stackTrace) {
                debugPrint('Error loading profile image in chat: $exception');
              }
            : null,
        child: userProfileUrl == null
            ? Text(
                userInitials ?? 'U',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              )
            : null,
      );
    } else {
      return CircleAvatar(
        radius: 16,
        backgroundColor: bgColor,
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }

  Widget _buildTypingCursor(BuildContext context) {
    return _TypingCursor(isStreaming: isStreaming);
  }

  void _showImageFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Center(
                  child: InteractiveViewer(
                    child: imageFile != null
                        ? Image.file(imageFile!)
                        : Image.network(imageUrl!),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing cursor widget
class _TypingCursor extends StatefulWidget {
  final bool isStreaming;

  const _TypingCursor({required this.isStreaming});

  @override
  State<_TypingCursor> createState() => _TypingCursorState();
}

class _TypingCursorState extends State<_TypingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isStreaming) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TypingCursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isStreaming && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 2,
        height: 16,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}