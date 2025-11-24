// models/notification.dart
class AppNotification {
  final int id;
  final String notificationType;
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
      id: json['id'],
      notificationType: json['notification_type'],
      senderName: json['sender_name'],
      senderProfilePicture: json['sender_profile_picture'],
      postId: json['post_id'],
      postContentPreview: json['post_content_preview'] ?? '',
      commentContent: json['comment_content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      timeAgo: json['time_ago'],
      message: json['message'],
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
}