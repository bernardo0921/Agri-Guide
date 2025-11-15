import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/community_api_service.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../screens/image_viewer_screen.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onDelete;

  const PostCard({super.key, required this.post, this.onDelete});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  bool _isLikeAnimating = false;

  // Local state for likes and comments
  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isLikeLoading = false;

  // Content expansion state
  bool _isContentExpanded = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize local state from post
    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state if post data changes externally
    if (oldWidget.post.id != widget.post.id) {
      _isLiked = widget.post.isLiked;
      _likesCount = widget.post.likesCount;
      _commentsCount = widget.post.commentsCount;
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isLikeLoading) return;

    setState(() {
      _isLikeLoading = true;
      _isLikeAnimating = true;
    });

    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
      setState(() {
        _isLikeAnimating = false;
      });
    });

    // Optimistically update UI
    final previousLiked = _isLiked;
    final previousCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      await CommunityApiService.toggleLike(widget.post.id);
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = previousLiked;
        _likesCount = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  void _openComments() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: widget.post),
    );

    // Update comment count if returned from bottom sheet
    if (result != null && mounted) {
      setState(() {
        _commentsCount = result;
      });
    }
  }

  void _openImageViewer() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(post: widget.post),
      ),
    );

    // Update state from image viewer
    if (result != null && mounted) {
      if (result['deleted'] == true) {
        // Post was deleted, trigger parent refresh
        if (widget.onDelete != null) {
          widget.onDelete!();
        }
      } else {
        setState(() {
          _likesCount = result['likesCount'] ?? _likesCount;
          _commentsCount = result['commentsCount'] ?? _commentsCount;
          _isLiked = result['isLiked'] ?? _isLiked;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildContent(),
                  if (widget.post.image != null) ...[
                    const SizedBox(height: 12),
                    _buildImage(),
                  ],
                  if (widget.post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTags(),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  _buildFooter(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final profileImageUrl = CommunityApiService.getImageUrl(
      widget.post.authorProfilePicture,
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final headerBgColor = isDarkMode
        ? const Color(0xFF2A2A2A)
        : Colors.green[50]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            headerBgColor.withOpacity(0.3),
            (isDarkMode ? Colors.white : Colors.white).withOpacity(0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'profile_${widget.post.id}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.green[300]!, Colors.green[500]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  radius: 22,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(Icons.person, color: Colors.green[700], size: 24)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[600]!],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.alternate_email,
                      size: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.authorUsername,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[600]
                              : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.timeAgo,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: PopupMenuButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  size: 20,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red[700],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Post',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete' && widget.onDelete != null) {
                  widget.onDelete!();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final content = widget.post.content;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if content needs truncation
    final textSpan = TextSpan(text: content);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 48,
    ); // 16 padding on each side

    final isContentTruncated = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
            letterSpacing: 0.2,
          ),
          maxLines: _isContentExpanded ? null : 3,
          overflow: _isContentExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        if (isContentTruncated && !_isContentExpanded) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isContentExpanded = true;
              });
            },
            child: Text(
              'View More',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
        if (_isContentExpanded && isContentTruncated) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isContentExpanded = false;
              });
            },
            child: Text(
              'View Less',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImage() {
    final postImageUrl = CommunityApiService.getImageUrl(widget.post.image);

    return GestureDetector(
      onTap: _openImageViewer,
      child: Hero(
        tag: 'post_image_${widget.post.id}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              postImageUrl,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[200]!, Colors.grey[300]!],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 3,
                            color: Colors.green[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading image...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.red[50]!, Colors.red[100]!],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.red[400],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please try again later',
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTags() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.post.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.green[900]!, Colors.green[800]!]
                  : [Colors.green[50]!, Colors.green[100]!],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode ? Colors.green[700]! : Colors.green[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(isDarkMode ? 0.2 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer,
                size: 12,
                color: isDarkMode ? Colors.green[400] : Colors.green[700],
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.green[300] : Colors.green[800],
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Update the _buildFooter method in _PostCardState class
  Widget _buildFooter(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(_commentsCount),
            onTap: _openComments,
            gradient: LinearGradient(
              colors: [Colors.blue[400]!, Colors.blue[600]!],
            ),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(_likesCount),
            onTap: _handleLike,
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.red[600]!],
            ),
            isActive: _isLiked,
            scale: _isLikeAnimating
                ? Tween<double>(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(
                      parent: _likeAnimationController,
                      curve: Curves.elasticOut,
                    ),
                  )
                : null,
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _onShare(context), // Updated to call _onShare
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method to the _PostCardState class
  Future<void> _onShare(BuildContext context) async {
    try {
      // Generate the deep link URL
      final postId = widget.post.id;
      final deepLinkUrl = 'http://https://agriguide-backend-79j2.onrender.com/post/$postId';

      // Create share content with post preview
      final shareText =
          '''
Check out this post from ${widget.post.authorName}:

${widget.post.content.length > 100 ? '${widget.post.content.substring(0, 100)}...' : widget.post.content}

View on AgriGuide: $deepLinkUrl
''';

      // Share the content
      final result = await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Post from AgriGuide Community'),
      );

      // Optional: Track share analytics
      if (result.status == ShareResultStatus.success) {
        print('Post ${widget.post.id} shared successfully');

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post shared successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sharing post: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Gradient gradient,
    bool isActive = false,
    Animation<double>? scale,
  }) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? gradient : null,
            color: isActive ? null : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.transparent : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (scale != null) {
      return ScaleTransition(scale: scale, child: button);
    }
    return button;
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
