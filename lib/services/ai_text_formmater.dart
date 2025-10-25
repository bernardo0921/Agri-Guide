import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A widget that formats and displays AI-generated text with support for:
/// - Clickable URLs (displayed on separate lines)
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildFormattedContent(context, text),
    );
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
          widgets.addAll(_buildParagraphWithUrls(context, currentParagraph));
          currentParagraph = '';
        }
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Handle headers
      if (line.startsWith('#')) {
        if (currentParagraph.isNotEmpty) {
          widgets.addAll(_buildParagraphWithUrls(context, currentParagraph));
          currentParagraph = '';
        }
        widgets.add(_buildHeader(context, line));
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Handle bullet points
      if (line.startsWith('•') ||
          line.startsWith('-') ||
          line.startsWith('*')) {
        if (currentParagraph.isNotEmpty) {
          widgets.addAll(_buildParagraphWithUrls(context, currentParagraph));
          currentParagraph = '';
        }
        widgets.add(_buildBulletPoint(context, line));
        continue;
      }

      // Handle numbered lists
      if (RegExp(r'^\d+\.').hasMatch(line)) {
        if (currentParagraph.isNotEmpty) {
          widgets.addAll(_buildParagraphWithUrls(context, currentParagraph));
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
      widgets.addAll(_buildParagraphWithUrls(context, currentParagraph));
    }

    return widgets.isEmpty ? _buildParagraphWithUrls(context, text) : widgets;
  }

  /// Builds paragraph and extracts URLs to display separately
  List<Widget> _buildParagraphWithUrls(BuildContext context, String text) {
    final widgets = <Widget>[];
    final urlRegex = RegExp(
      r'(\b(?:https?:\/\/|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:\/[^\s\)\.,\]]*)?)',
      caseSensitive: false,
    );

    final urls = <String>[];
    String textWithoutUrls = text;

    // Extract all URLs
    for (final match in urlRegex.allMatches(text)) {
      final url = match.group(0)!.trim().replaceAll(RegExp(r'[.,\)\]\:]$'), '');
      urls.add(url);
      // Replace URL with placeholder
      textWithoutUrls = textWithoutUrls.replaceFirst(url, '');
    }

    // Clean up extra spaces
    textWithoutUrls = textWithoutUrls.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Add text content if not empty
    if (textWithoutUrls.isNotEmpty) {
      widgets.add(_buildFormattedText(context, textWithoutUrls));
    }

    // Add URLs as separate clickable cards
    for (final url in urls) {
      if (textWithoutUrls.isNotEmpty || urls.indexOf(url) > 0) {
        widgets.add(const SizedBox(height: 8));
      }
      widgets.add(_buildUrlCard(context, url));
    }

    if (widgets.isNotEmpty) {
      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }

  /// Builds a clickable URL card
  Widget _buildUrlCard(BuildContext context, String url) {
    final displayUrl = url.length > 60 ? '${url.substring(0, 57)}...' : url;

    return GestureDetector(
      onTap: () => _launchURL(url),
      onLongPress: () => _showUrlOptions(context, url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              size: 18,
              color: linkColor ?? Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayUrl,
                style: TextStyle(
                  color: linkColor ?? Colors.blue.shade700,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: Colors.blue.shade400),
          ],
        ),
      ),
    );
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
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
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
            style:
                baseStyle ??
                TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.4,
                ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildParagraphWithUrls(context, content),
            ),
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
            style:
                baseStyle ??
                TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.4,
                ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildParagraphWithUrls(context, content),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds formatted text with inline formatting (bold, code)
  Widget _buildFormattedText(
    BuildContext context,
    String text, {
    TextStyle? style,
  }) {
    final spans = _parseInlineFormatting(context, text);

    return RichText(
      text: TextSpan(
        style:
            style ??
            baseStyle ??
            TextStyle(color: Colors.grey.shade800, fontSize: 15, height: 1.4),
        children: spans,
      ),
    );
  }

  /// Parses inline formatting (bold, code) - URLs are handled separately
  List<InlineSpan> _parseInlineFormatting(BuildContext context, String text) {
    final spans = <InlineSpan>[];

    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    final codeRegex = RegExp(r'`([^`]+)`');

    final combinedRegex = RegExp(
      '(${boldRegex.pattern})|(${codeRegex.pattern})',
      caseSensitive: false,
    );

    int currentIndex = 0;

    for (final Match match in combinedRegex.allMatches(text)) {
      // Add plain text before the match
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }

      // Bold Match
      if (match.group(1) != null) {
        final boldText = RegExp(
          r'\*\*(.+?)\*\*',
        ).firstMatch(match.group(0)!)?.group(1);
        if (boldText != null) {
          spans.add(
            TextSpan(
              text: boldText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
      }
      // Code Match
      else if (match.group(2) != null) {
        final codeText = RegExp(
          r'`([^`]+)`',
        ).firstMatch(match.group(0)!)?.group(1);
        if (codeText != null) {
          spans.add(_buildCodeSpan(codeText));
        }
      }

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return spans;
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
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
