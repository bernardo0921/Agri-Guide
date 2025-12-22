// screens/image_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agri_guide/models/post.dart';
import 'package:agri_guide/services/community_services/community_api_service.dart';
import 'package:agri_guide/widgets/comments_bottom_sheet.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/config/theme.dart';

class ImageViewerScreen extends StatefulWidget {
  final Post post;

  const ImageViewerScreen({super.key, required this.post});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  late bool _isLiked;
  late int _likesCount;
  late int _commentsCount;
  bool _isLikeLoading = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addListener(() {
          _transformationController.value = _animation!.value;
        });

    _isLiked = widget.post.isLiked;
    _likesCount = widget.post.likesCount;
    _commentsCount = widget.post.commentsCount;
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final position = details.localPosition;
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    if (scale > 1.0) {
      _animateZoom(Matrix4.identity());
    } else {
      final double newScale = 2.5;
      final double dx = -position.dx * (newScale - 1);
      final double dy = -position.dy * (newScale - 1);

      final Matrix4 matrix = Matrix4.identity()
        ..setEntry(0, 3, dx)
        ..setEntry(1, 3, dy)
        ..setEntry(0, 0, newScale)
        ..setEntry(1, 1, newScale);

      _animateZoom(matrix);
    }
  }

  void _animateZoom(Matrix4 end) {
    _animation = Matrix4Tween(begin: _transformationController.value, end: end)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
    _animationController.forward(from: 0);
  }

  Future<void> _handleLike() async {
    if (_isLikeLoading) return;

    setState(() {
      _isLikeLoading = true;
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
            content: Text('${AppStrings.failedToUpdateLike}: $e'),
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

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppStrings.shareFunctionalityComingSoon),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        title: Text(
          AppStrings.deletePost,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
        content: Text(
          AppStrings.deletePostConfirm,
          style: TextStyle(
            color: isDark ? AppColors.textLight : AppColors.textMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.cancel,
              style: TextStyle(
                color: isDark ? AppColors.textLight : AppColors.textMedium,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await CommunityApiService.deletePost(widget.post.id);
        if (mounted) {
          Navigator.of(context).pop({'deleted': true});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.postDeletedSuccessfully),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppStrings.failedToDeletePost}: $e'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = CommunityApiService.getImageUrl(widget.post.image);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop({
          'likesCount': _likesCount,
          'commentsCount': _commentsCount,
          'isLiked': _isLiked,
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: ValueListenableBuilder(
          valueListenable: AppNotifiers.languageNotifier,
          builder: (context, language, child) {
            return Stack(
              children: [
                // Zoomable Image
                GestureDetector(
                  onTap: _toggleControls,
                  onDoubleTapDown: _handleDoubleTapDown,
                  child: Center(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: Hero(
                        tag: 'post_image_${widget.post.id}',
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primaryGreen,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 64,
                                      color: AppColors.textLight,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppStrings.failedToLoadImage,
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                       ),
                     ),
                   ),
                 ),

                // Top Controls
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop({
                                'likesCount': _likesCount,
                                'commentsCount': _commentsCount,
                                'isLiked': _isLiked,
                              }),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                              ),
                              color: AppColors.surfaceDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[900],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.share,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppStrings.share,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentRed.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.accentRed,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        AppStrings.deletePost,
                                        style: TextStyle(
                                          color: AppColors.accentRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'share') {
                                  _handleShare();
                                } else if (value == 'delete') {
                                  _handleDelete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Controls
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Like Button
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: _handleLike,
                                          icon: Icon(
                                            _isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: _isLiked
                                                ? AppColors.accentRed
                                                : Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCount(_likesCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Comment Button
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: _openComments,
                                          icon: const Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatCount(_commentsCount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Author Info
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryGreen,
                                    backgroundImage:
                                        widget.post.authorProfilePicture != null
                                        ? NetworkImage(
                                            CommunityApiService.getImageUrl(
                                              widget.post.authorProfilePicture,
                                            ),
                                          )
                                        : null,
                                    child:
                                        widget.post.authorProfilePicture == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 20,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.post.authorName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '@${widget.post.authorUsername}',
                                              style: TextStyle(
                                                color: AppColors.textLight,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                  ),
                                              child: Container(
                                                width: 3,
                                                height: 3,
                                                decoration: BoxDecoration(
                                                  color: AppColors.textLight,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              widget.post.timeAgo,
                                              style: TextStyle(
                                                color: AppColors.textLight,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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
