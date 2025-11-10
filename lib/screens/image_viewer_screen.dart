// screens/image_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/post.dart';
import '../services/community_api_service.dart';
import '../widgets/comments_bottom_sheet.dart';

class ImageViewerScreen extends StatefulWidget {
  final Post post;

  const ImageViewerScreen({
    super.key,
    required this.post,
  });

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
    
    _animationController = AnimationController(
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
      // Zoom out
      _animateZoom(Matrix4.identity());
    } else {
      // Zoom in
      final double newScale = 2.5;
      final double dx = -position.dx * (newScale - 1);
      final double dy = -position.dy * (newScale - 1);
      
      final Matrix4 matrix = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(newScale);
      
      _animateZoom(matrix);
    }
  }

  void _animateZoom(Matrix4 end) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: end,
    ).animate(
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
    
    if (result != null && mounted) {
      setState(() {
        _commentsCount = result;
      });
    }
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Post',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
            const SnackBar(content: Text('Post deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = CommunityApiService.getImageUrl(widget.post.image);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop({
          'likesCount': _likesCount,
          'commentsCount': _commentsCount,
          'isLiked': _isLiked,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
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
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.green[400],
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
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  color: Colors.grey[400],
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
                      Colors.black.withOpacity(0.6),
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.3),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                          ),
                          color: Colors.grey[900],
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
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.share,
                                      color: Colors.blue,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Share',
                                    style: TextStyle(color: Colors.white),
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
                                      color: Colors.red[900],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Delete Post',
                                    style: TextStyle(color: Colors.red),
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
                        Colors.black.withOpacity(0.8),
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
                                      color: Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      onPressed: _handleLike,
                                      icon: Icon(
                                        _isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: _isLiked ? Colors.red : Colors.white,
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
                                      color: Colors.black.withOpacity(0.3),
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
                                backgroundColor: Colors.green[700],
                                backgroundImage: widget.post.authorProfilePicture != null
                                    ? NetworkImage(
                                        CommunityApiService.getImageUrl(
                                          widget.post.authorProfilePicture,
                                        ),
                                      )
                                    : null,
                                child: widget.post.authorProfilePicture == null
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: Colors.grey[400],
                                            fontSize: 13,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: Container(
                                            width: 3,
                                            height: 3,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[600],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          widget.post.timeAgo,
                                          style: TextStyle(
                                            color: Colors.grey[400],
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