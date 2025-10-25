import 'package:flutter/material.dart';
// import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that formats and displays AI-generated text with support for:
/// - Clickable URLs
/// - Bold text (**text**)
/// - Inline code (`code`)
/// - Bullet points
/// - Numbered lists
/// - Headers
class AITextFormatter extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? linkColor;
  final Color? codeBackgroundColor;
  final Color? codeTextColor;

  const AITextFormatter({
    super.key,
    required this.text,
    this.baseStyle,
    this.linkColor,
    this.codeBackgroundColor,
    this.codeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    // Remove all asterisks that are used for formatting
    final cleanedText = _removeFormattingAsterisks(text);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildFormattedContent(context, cleanedText),
    );
  }

  /// Removes asterisks used for markdown formatting while preserving content
  String _removeFormattingAsterisks(String text) {
    // Remove bold markers (**text**)
    String cleaned = text.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => match.group(1)!,
    );
    
    // Remove any remaining standalone asterisks used for formatting
    cleaned = cleaned.replaceAll(RegExp(r'(?<!\*)\*(?!\*)'), '');
    
    return cleaned;
  }

  /// Builds formatted content by parsing the text into blocks
  List<Widget> _buildFormattedContent(BuildContext context, String text) {
    final widgets = <Widget>[];
    final lines = text.split('\n');
    
    String currentParagraph = '';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        if (currentParagraph.isNotEmpty) {
          widgets.add(_buildFormattedText(context, currentParagraph));
          widgets.add(const SizedBox(height: 8));
          currentParagraph = '';
        }
        continue;
      }
      
      // Handle headers
      if (line.startsWith('#')) {
        if (currentParagraph.isNotEmpty) {
          widgets.add(_buildFormattedText(context, currentParagraph));
          widgets.add(const SizedBox(height: 8));
          currentParagraph = '';
        }
        widgets.add(_buildHeader(context, line));
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // Handle bullet points
      if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        if (currentParagraph.isNotEmpty) {
          widgets.add(_buildFormattedText(context, currentParagraph));
          widgets.add(const SizedBox(height: 8));
          currentParagraph = '';
        }
        widgets.add(_buildBulletPoint(context, line));
        continue;
      }
      
      // Handle numbered lists
      if (RegExp(r'^\d+\.').hasMatch(line)) {
        if (currentParagraph.isNotEmpty) {
          widgets.add(_buildFormattedText(context, currentParagraph));
          widgets.add(const SizedBox(height: 8));
          currentParagraph = '';
        }
        widgets.add(_buildNumberedPoint(context, line));
        continue;
      }
      
      // Accumulate regular text
      currentParagraph += (currentParagraph.isEmpty ? '' : ' ') + line;
    }
    
    // Add any remaining paragraph
    if (currentParagraph.isNotEmpty) {
      widgets.add(_buildFormattedText(context, currentParagraph));
    }
    
    return widgets.isEmpty ? [_buildFormattedText(context, text)] : widgets;
  }

  /// Builds a header widget
  Widget _buildHeader(BuildContext context, String line) {
    int level = 0;
    while (level < line.length && line[level] == '#') {
      level++;
    }
    
    final headerText = line.substring(level).trim();
    final fontSize = 20.0 - (level * 2.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _buildFormattedText(
        context,
        headerText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds a bullet point widget
  Widget _buildBulletPoint(BuildContext context, String line) {
    final bulletRegex = RegExp(r'^[•\-\*]\s*(.*)$');
    final match = bulletRegex.firstMatch(line);
    final content = match?.group(1) ?? line;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: baseStyle ?? TextStyle(
              color: Colors.grey.shade800,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          Expanded(
            child: _buildFormattedText(context, content),
          ),
        ],
      ),
    );
  }

  /// Builds a numbered list item widget
  Widget _buildNumberedPoint(BuildContext context, String line) {
    final numberRegex = RegExp(r'^(\d+)\.\s*(.*)$');
    final match = numberRegex.firstMatch(line);
    final number = match?.group(1) ?? '1';
    final content = match?.group(2) ?? line;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: baseStyle ?? TextStyle(
              color: Colors.grey.shade800,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          Expanded(
            child: _buildFormattedText(context, content),
          ),
        ],
      ),
    );
  }

  /// Builds formatted text with inline formatting (bold, code, links)
  Widget _buildFormattedText(BuildContext context, String text, {TextStyle? style}) {
    final spans = _parseInlineFormatting(context, text);
    
    return RichText(
      text: TextSpan(
        style: style ?? baseStyle ?? TextStyle(
          color: Colors.grey.shade800,
          fontSize: 15,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }

  /// Parses inline formatting (URLs, bold, code)
  List<InlineSpan> _parseInlineFormatting(BuildContext context, String text) {
    final spans = <InlineSpan>[];

    // Regex patterns
    final urlRegex = RegExp(
      r'(\b(?:https?:\/\/|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:\/[^\s\)\.,\]]*)?|\b[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:\/[^\s\)\.,\]]*)?)',
      caseSensitive: false,
    );

    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    final codeRegex = RegExp(r'`([^`]+)`');

    final combinedRegex = RegExp(
      '(${urlRegex.pattern})|(${boldRegex.pattern})|(${codeRegex.pattern})',
      caseSensitive: false,
    );

    int currentIndex = 0;

    for (final Match match in combinedRegex.allMatches(text)) {
      // Add plain text before the match
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      // URL Match
      if (match.group(1) != null) {
        final cleanUrl = match.group(0)!.trim().replaceAll(RegExp(r'[.,]$'), '');
        spans.add(_buildUrlSpan(context, cleanUrl));
      }
      // Bold Match
      else if (match.group(2) != null) {
        spans.add(
          TextSpan(
            text: match.group(2)!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }
      // Code Match
      else if (match.group(3) != null) {
        spans.add(_buildCodeSpan(match.group(3)!));
      }

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
  }

  /// Builds a URL span with click and long-press handlers
  InlineSpan _buildUrlSpan(BuildContext context, String url) {
    final displayText = url.length > 50 ? '${url.substring(0, 47)}...' : url;

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: () => _launchURL(url),
        onLongPress: () => _showUrlOptions(context, url),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: linkColor ?? Colors.blue,
                width: 1,
              ),
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              color: linkColor ?? Colors.blue,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a code span
  InlineSpan _buildCodeSpan(String code) {
    return TextSpan(
      text: ' $code ',
      style: TextStyle(
        fontFamily: 'monospace',
        backgroundColor: codeBackgroundColor ?? Colors.grey.shade200,
        color: codeTextColor ?? Colors.red.shade700,
        fontSize: 14,
      ),
    );
  }

  /// Launches a URL in the browser
  Future<void> _launchURL(String url) async {
    try {
      String cleanUrl = url.trim().replaceAll(RegExp(r'[.,]$'), '');
      
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final Uri uri = Uri.parse(cleanUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('⚠️ Could not launch URL: $cleanUrl');
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
    }
  }

  /// Shows options for a URL (copy or open)
  void _showUrlOptions(BuildContext context, String url) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Open URL'),
              subtitle: Text(
                url.length > 50 ? '${url.substring(0, 47)}...' : url,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _launchURL(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy URL'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('URL copied to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Extension methods for easy usage
extension AITextFormatterExtension on String {
  /// Converts the string to an AITextFormatter widget
  Widget toAIFormattedText({
    TextStyle? baseStyle,
    Color? linkColor,
    Color? codeBackgroundColor,
    Color? codeTextColor,
  }) {
    return AITextFormatter(
      text: this,
      baseStyle: baseStyle,
      linkColor: linkColor,
      codeBackgroundColor: codeBackgroundColor,
      codeTextColor: codeTextColor,
    );
  }
}