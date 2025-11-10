class Tutorial {
  final int id;
  final String title;
  final String description;
  final String category;
  final String videoUrl;
  final String? thumbnailUrl;
  final int uploaderId;
  final String uploaderName;
  final String? uploaderProfilePicture;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.uploaderId,
    required this.uploaderName,
    this.uploaderProfilePicture,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      uploaderId: json['uploader_id'] as int,
      uploaderName: json['uploader_name'] as String,
      uploaderProfilePicture: json['uploader_profile_picture'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'uploader_id': uploaderId,
      'uploader_name': uploaderName,
      'uploader_profile_picture': uploaderProfilePicture,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get full URL for video
  String getFullVideoUrl(String baseUrl) {
    if (videoUrl.startsWith('http')) {
      return videoUrl;
    }
    return '$baseUrl$videoUrl';
  }

  // Get full URL for thumbnail
  String? getFullThumbnailUrl(String baseUrl) {
    if (thumbnailUrl == null) return null;
    if (thumbnailUrl!.startsWith('http')) {
      return thumbnailUrl;
    }
    return '$baseUrl$thumbnailUrl';
  }

  // Get full URL for uploader profile picture
  String? getFullUploaderProfilePictureUrl(String baseUrl) {
    if (uploaderProfilePicture == null) return null;
    if (uploaderProfilePicture!.startsWith('http')) {
      return uploaderProfilePicture;
    }
    return '$baseUrl$uploaderProfilePicture';
  }

  // Get uploader initials for avatar fallback
  String getUploaderInitials() {
    final parts = uploaderName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return uploaderName.substring(0, uploaderName.length > 2 ? 2 : uploaderName.length).toUpperCase();
  }

  // Format view count
  String getFormattedViewCount() {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  // Get relative time
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}