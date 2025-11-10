// models/comment.dart
class Comment {
  final int id;
  final String userName;
  final String userUsername;
  final String? userProfilePicture;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCurrentUser;

  Comment({
    required this.id,
    required this.userName,
    required this.userUsername,
    this.userProfilePicture,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isCurrentUser,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userName: json['user_name'] ?? 'Unknown User',
      userUsername: json['user_username'] ?? '',
      userProfilePicture: json['user_profile_picture'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isCurrentUser: json['is_current_user'] ?? false,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'user_username': userUsername,
      'user_profile_picture': userProfilePicture,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_current_user': isCurrentUser,
    };
  }
}