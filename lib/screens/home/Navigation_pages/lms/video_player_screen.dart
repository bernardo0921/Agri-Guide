import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/config/theme.dart';
import '../../../../../models/tutorial.dart';
import '../../../../../services/lms_api_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Tutorial tutorial;

  const VideoPlayerScreen({super.key, required this.tutorial});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _viewCountIncremented = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = widget.tutorial.videoUrl;

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryGreen,
          handleColor: AppColors.primaryGreen,
          backgroundColor: AppColors.borderLight,
          bufferedColor: AppColors.textLight,
        ),
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Error loading video',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.isPlaying && !_viewCountIncremented) {
          _incrementViewCount();
          _viewCountIncremented = true;
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: ${e.toString()}';
      });
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token != null) {
        final apiService = LMSApiService(token);
        await apiService.incrementViews(widget.tutorial.id);
      }
    } catch (e) {
      debugPrint('Failed to increment view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Video Player
          _buildVideoPlayer(),

          // Tutorial Details
          Expanded(
            child: Container(
              color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              child: _buildTutorialDetails(theme, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _initializePlayer();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTutorialDetails(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              widget.tutorial.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // View count and date
            Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 16,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.tutorial.getFormattedViewCount()} views',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.tutorial.getRelativeTime(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.paleGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.tutorial.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 16),

            // Uploader info
            Row(
              children: [
                _buildUploaderAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tutorial.uploaderName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textWhite : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Extension Farmer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Divider(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Description',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.tutorial.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploaderAvatar() {
    final profilePictureUrl = widget.tutorial.uploaderProfilePictureUrl;
    final initials = widget.tutorial.getUploaderInitials();

    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.paleGreen,
      backgroundImage: profilePictureUrl != null
          ? NetworkImage(profilePictureUrl)
          : null,
      onBackgroundImageError: profilePictureUrl != null
          ? (exception, stackTrace) {
              debugPrint('Error loading uploader image: $exception');
            }
          : null,
      child: profilePictureUrl == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            )
          : null,
    );
  }
}