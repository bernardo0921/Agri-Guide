import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agri_guide/services/ai_services/ai_text_formmater.dart';

/// Enhanced Chat Message Bubble with optional TTS button
class EnhancedChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final File? imageFile;
  final String? imageUrl;
  final bool isStreaming;
  final String? userProfileUrl;
  final String? userInitials;
  final bool showTTSButton;
  final bool isTTSSpeaking;
  final VoidCallback? onTTSToggle;

  const EnhancedChatMessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.imageFile,
    this.imageUrl,
    this.isStreaming = false,
    this.userProfileUrl,
    this.userInitials,
    this.showTTSButton = false,
    this.isTTSSpeaking = false,
    this.onTTSToggle,
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
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
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
                          color: colorScheme.outline.withValues(alpha: 0.2),
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
                // TTS Button for AI messages in voice mode
                if (showTTSButton && !isUser && hasText)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      icon: Icon(
                        isTTSSpeaking
                            ? Icons.stop_circle
                            : Icons.play_circle_filled,
                        color: isTTSSpeaking ? Colors.red : colorScheme.primary,
                      ),
                      onPressed: onTTSToggle,
                      tooltip: isTTSSpeaking ? 'Stop' : 'Play',
                      iconSize: 32,
                    ),
                  ),
              ],
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
        if (hasText && (imageFile != null || imageUrl != null))
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
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
                        ? colorScheme.surface.withValues(alpha: 0.5)
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
                ? Colors.white.withValues(alpha: 0.8)
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
                style: const TextStyle(
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
                color: Colors.black.withValues(alpha: 0.9),
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

/// Pulsing dot indicator for listening state
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
