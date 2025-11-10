// models/tutorial.dart - Updated for full S3 URLs (no getFullThumbnailUrl needed)
class Tutorial {
  final int id;
  final String title;
  final String description;
  final String category;
  final String videoUrl; // Full S3 URL from backend
  final String? thumbnailUrl; // Full S3 URL from backend
  final int uploaderId;
  final String uploaderName;
  final String? uploaderProfilePictureUrl; // Full S3 URL from backend
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
    this.uploaderProfilePictureUrl,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      videoUrl: json['video_url'], // Already full S3 URL
      thumbnailUrl: json['thumbnail_url'], // Already full S3 URL
      uploaderId: json['uploader_id'],
      uploaderName: json['uploader_name'],
      uploaderProfilePictureUrl:
          json['uploader_profile_picture'], // Already full S3 URL
      viewCount: json['view_count'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'uploader_profile_picture': uploaderProfilePictureUrl,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // === Utility Methods ===

  /// Formats the view count (e.g., 1.2K, 3.4M)
  String getFormattedViewCount() {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  /// Returns how long ago the tutorial was uploaded
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

  /// Returns the uploader's initials (e.g., "BE" for "Bernard Ephraim")
  String getUploaderInitials() {
    final nameParts = uploaderName.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}
