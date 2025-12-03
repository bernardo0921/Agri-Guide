// models/notification.dart
class AppNotification {
  final int id;
  final String notificationType; // 'like' or 'comment'
  final String senderName;
  final String? senderProfilePicture;
  final int postId;
  final String postContentPreview;
  final String? commentContent;
  final bool isRead;
  final DateTime createdAt;
  final String timeAgo;
  final String message;

  AppNotification({
    required this.id,
    required this.notificationType,
    required this.senderName,
    this.senderProfilePicture,
    required this.postId,
    required this.postContentPreview,
    this.commentContent,
    required this.isRead,
    required this.createdAt,
    required this.timeAgo,
    required this.message,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      notificationType: json['notification_type'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderProfilePicture: json['sender_profile_picture'],
      postId: json['post_id'] ?? 0,
      postContentPreview: json['post_content_preview'] ?? '',
      commentContent: json['comment_content'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      timeAgo: json['time_ago'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notification_type': notificationType,
      'sender_name': senderName,
      'sender_profile_picture': senderProfilePicture,
      'post_id': postId,
      'post_content_preview': postContentPreview,
      'comment_content': commentContent,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'time_ago': timeAgo,
      'message': message,
    };
  }

  AppNotification copyWith({
    int? id,
    String? notificationType,
    String? senderName,
    String? senderProfilePicture,
    int? postId,
    String? postContentPreview,
    String? commentContent,
    bool? isRead,
    DateTime? createdAt,
    String? timeAgo,
    String? message,
  }) {
    return AppNotification(
      id: id ?? this.id,
      notificationType: notificationType ?? this.notificationType,
      senderName: senderName ?? this.senderName,
      senderProfilePicture: senderProfilePicture ?? this.senderProfilePicture,
      postId: postId ?? this.postId,
      postContentPreview: postContentPreview ?? this.postContentPreview,
      commentContent: commentContent ?? this.commentContent,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      timeAgo: timeAgo ?? this.timeAgo,
      message: message ?? this.message,
    );
  }
}