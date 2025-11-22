import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/community_api_service.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../screens/image_viewer_screen.dart';
import '../config/theme.dart';
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

  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isLikeLoading = false;
  bool _isContentExpanded = false;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
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

    final previousLiked = _isLiked;
    final previousCount = _likesCount;

    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      await CommunityApiService.toggleLike(widget.post.id);
    } catch (e) {
      setState(() {
        _isLiked = previousLiked;
        _likesCount = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update like: $e'),
            backgroundColor: AppColors.accentRed,
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

    if (result != null && mounted) {
      if (result['deleted'] == true) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
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
            _buildHeader(context, isDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildContent(isDark),
                  if (widget.post.image != null) ...[
                    const SizedBox(height: 12),
                    _buildImage(),
                  ],
                  if (widget.post.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTags(isDark),
                  ],
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  _buildFooter(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final profileImageUrl = CommunityApiService.getImageUrl(
      widget.post.authorProfilePicture,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isDark ? AppColors.surfaceDark : AppColors.paleGreen).withValues(alpha: 0.3),
            Colors.transparent,
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
                  colors: [AppColors.lightGreen, AppColors.primaryGreen],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                radius: 24,
                child: CircleAvatar(
                  backgroundColor: AppColors.paleGreen,
                  radius: 22,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: AppColors.primaryGreen,
                          size: 24,
                        )
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
                          color: isDark ? AppColors.textWhite : AppColors.textDark,
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
                          colors: [AppColors.lightGreen, AppColors.primaryGreen],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.verified,
                        color: AppColors.textWhite,
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
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.authorUsername,
                      style: TextStyle(
                        color: AppColors.textMedium,
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.textLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.post.timeAgo,
                      style: TextStyle(
                        color: AppColors.textMedium,
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
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.textMedium,
                  size: 20,
                ),
              ),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
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
                            color: AppColors.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppColors.accentRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete Post',
                          style: TextStyle(
                            color: AppColors.accentRed,
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

  Widget _buildContent(bool isDark) {
    final content = widget.post.content;

    final textSpan = TextSpan(text: content);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      maxWidth: MediaQuery.of(context).size.width - 48,
    );

    final isContentTruncated = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: isDark ? AppColors.textWhite : AppColors.textDark,
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
                color: AppColors.primaryGreen,
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
                color: AppColors.primaryGreen,
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
                color: Colors.black.withValues(alpha: 0.1),
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
                    color: AppColors.backgroundLight,
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
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading image...',
                          style: TextStyle(
                            color: AppColors.textMedium,
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
                    color: AppColors.accentRed.withValues(alpha: 0.1),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentRed.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: AppColors.accentRed,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: AppColors.accentRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please try again later',
                          style: TextStyle(
                            color: AppColors.textMedium,
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

  Widget _buildTags(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.post.tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? AppColors.primaryGreen.withValues(alpha: 0.2)
                : AppColors.paleGreen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark 
                  ? AppColors.primaryGreen.withValues(alpha: 0.5)
                  : AppColors.lightGreen,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
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
                color: AppColors.primaryGreen,
              ),
              const SizedBox(width: 6),
              Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(_commentsCount),
            onTap: _openComments,
            color: Colors.blue,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: _formatCount(_likesCount),
            onTap: _handleLike,
            color: AppColors.accentRed,
            isActive: _isLiked,
            isDark: isDark,
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
              onTap: () => _onShare(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: AppColors.textMedium,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
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

  Future<void> _onShare(BuildContext context) async {
    try {
      final postId = widget.post.id;
      final deepLinkUrl = 'https://agriguide-backend-79j2.onrender.com/post/$postId';

      final shareText = '''
Check out this post from ${widget.post.authorName}:

${widget.post.content.length > 100 ? '${widget.post.content.substring(0, 100)}...' : widget.post.content}

View on AgriGuide: $deepLinkUrl
''';

      final result = await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Post from AgriGuide Community'),
      );

      if (result.status == ShareResultStatus.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Post shared successfully!'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share post: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    required bool isDark,
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
            color: isActive 
                ? color 
                : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive 
                  ? Colors.transparent 
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive 
                    ? AppColors.textWhite 
                    : (isDark ? AppColors.textWhite : AppColors.textDark),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive 
                      ? AppColors.textWhite 
                      : (isDark ? AppColors.textWhite : AppColors.textDark),
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