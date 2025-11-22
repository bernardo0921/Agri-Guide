import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/config/theme.dart';
import '../../../../../services/lms_api_service.dart';

class UploadTutorialScreen extends StatefulWidget {
  const UploadTutorialScreen({super.key});

  @override
  State<UploadTutorialScreen> createState() => _UploadTutorialScreenState();
}

class _UploadTutorialScreenState extends State<UploadTutorialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'crops';
  File? _videoFile;
  File? _thumbnailFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  static const Map<String, String> categoryMap = {
    'crops': 'Crops',
    'livestock': 'Livestock',
    'irrigation': 'Irrigation',
    'pest_control': 'Pest Control',
    'soil_management': 'Soil Management',
    'harvesting': 'Harvesting',
    'post_harvest': 'Post-Harvest',
    'farm_equipment': 'Farm Equipment',
    'marketing': 'Marketing',
    'other': 'Other',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);

        final fileSize = await file.length();
        if (fileSize > 100 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Video file too large. Please select a video under 100MB.',
                ),
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
          return;
        }

        setState(() {
          _videoFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick video: ${e.toString()}';
      });
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _thumbnailFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick thumbnail: ${e.toString()}';
      });
    }
  }

  Future<void> _uploadTutorial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a video file'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiService = LMSApiService(token);

      await apiService.uploadTutorial(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        videoFile: _videoFile!,
        thumbnailFile: _thumbnailFile,
        onProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tutorial uploaded successfully!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Tutorial')),
      body: _isUploading ? _buildUploadingView() : _buildForm(),
    );
  }

  Widget _buildUploadingView() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            Text('Uploading tutorial...', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accentRed.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.accentRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.accentRed),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter tutorial title',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe what this tutorial covers',
                  prefixIcon: const Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
                maxLength: 1000,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categoryMap.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Video file picker
              _buildFilePicker(
                label: 'Video File *',
                file: _videoFile,
                icon: Icons.video_library,
                onTap: _pickVideo,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // Thumbnail picker
              _buildFilePicker(
                label: 'Thumbnail (Optional)',
                file: _thumbnailFile,
                icon: Icons.image,
                onTap: _pickThumbnail,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Upload button
              ElevatedButton.icon(
                onPressed: _uploadTutorial,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Tutorial'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required String label,
    required File? file,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
          color: file != null
              ? AppColors.paleGreen
              : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: file != null
                  ? AppColors.primaryGreen
                  : AppColors.textMedium,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file != null
                        ? file.path.split('/').last
                        : 'Tap to select file',
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null
                          ? AppColors.primaryGreen
                          : AppColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (file != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    if (icon == Icons.video_library) {
                      _videoFile = null;
                    } else {
                      _thumbnailFile = null;
                    }
                  });
                },
                color: AppColors.accentRed,
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMedium,
              ),
          ],
        ),
      ),
    );
  }
}
