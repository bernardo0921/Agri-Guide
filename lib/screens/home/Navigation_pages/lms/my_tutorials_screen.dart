import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/config/theme.dart';
import '../../../../../services/lms_api_service.dart';
import '../../../../../models/tutorial.dart';
import 'video_player_screen.dart';
import 'upload_tutorial_screen.dart' as upload;

class MyTutorialsScreen extends StatefulWidget {
  const MyTutorialsScreen({super.key});

  @override
  State<MyTutorialsScreen> createState() => _MyTutorialsScreenState();
}

class _MyTutorialsScreenState extends State<MyTutorialsScreen> {
  List<Tutorial> _myTutorials = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChanges = false;
  bool _isExtensionWorker = false;

  // static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadMyTutorials();
  }

  void _checkUserRole() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user != null) {
      final userType = user['user_type']?.toString().toLowerCase();
      _isExtensionWorker =
          userType == 'extension_worker' ||
          userType == 'extension' ||
          userType == 'extensionworker';
    }
  }

  Future<void> _loadMyTutorials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiService = LMSApiService(token);
      final tutorials = await apiService.getMyTutorials();

      setState(() {
        _myTutorials = tutorials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTutorial(Tutorial tutorial) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tutorial'),
        content: Text('Are you sure you want to delete "${tutorial.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiService = LMSApiService(token);
      await apiService.deleteTutorial(tutorial.id);

      if (mounted) {
        setState(() {
          _myTutorials.removeWhere((t) => t.id == tutorial.id);
          _hasChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tutorial deleted successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  void _navigateToVideoPlayer(Tutorial tutorial) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(tutorial: tutorial),
      ),
    );
  }

  void _navigateToUploadTutorial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const upload.UploadTutorialScreen(),
      ),
    ).then((uploaded) {
      if (uploaded == true) {
        setState(() {
          _hasChanges = true;
        });
        _loadMyTutorials();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pop(context, _hasChanges);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('My Tutorials')),
        body: _buildBody(),
        floatingActionButton: _isExtensionWorker ? _buildUploadButton() : null,
      ),
    );
  }

  Widget _buildUploadButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToUploadTutorial,
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: AppColors.textWhite,
      icon: const Icon(Icons.add),
      label: const Text('Upload'),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.accentRed.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading tutorials',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMyTutorials,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_myTutorials.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No tutorials yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isExtensionWorker
                    ? 'Tap the Upload button to create your first tutorial'
                    : 'You haven\'t uploaded any tutorials',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyTutorials,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTutorials.length,
        itemBuilder: (context, index) {
          final tutorial = _myTutorials[index];
          return _buildTutorialItem(tutorial, isDark);
        },
      ),
    );
  }

  Widget _buildTutorialItem(Tutorial tutorial, bool isDark) {
    final thumbnailUrl = tutorial.thumbnailUrl;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToVideoPlayer(tutorial),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 120,
                  height: 68,
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  child: thumbnailUrl != null
                      ? Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildDefaultThumbnail();
                          },
                        )
                      : _buildDefaultThumbnail(),
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      tutorial.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tutorial.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 13,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${tutorial.getFormattedViewCount()} views',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.schedule,
                          size: 13,
                          color: AppColors.textMedium,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            tutorial.getRelativeTime(),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMedium,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              if (_isExtensionWorker)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: AppColors.accentRed),
                  onPressed: () => _deleteTutorial(tutorial),
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      color: AppColors.paleGreen,
      child: Center(
        child: Icon(
          Icons.play_circle_filled,
          size: 32,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
