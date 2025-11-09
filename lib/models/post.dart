class Post {
  final int id;
  final String authorName;
  final String authorUsername;
  final String? authorProfilePicture;
  final String content;
  final String? image;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.authorName,
    required this.authorUsername,
    this.authorProfilePicture,
    required this.content,
    this.image,
    required this.tags,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      authorName: json['author_name'] ?? 'Unknown User',
      authorUsername: json['author_username'] ?? '',
      authorProfilePicture: json['author_profile_picture'],
      content: json['content'] ?? '',
      image: json['image'],
      tags: List<String>.from(json['tags'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hr${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}