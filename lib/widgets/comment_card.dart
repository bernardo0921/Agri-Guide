// widgets/comment_card.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const CommentCard({
    super.key,
    required this.comment,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[100],
              image: comment.userProfilePicture != null
                  ? DecorationImage(
                      image: NetworkImage(comment.userProfilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: comment.userProfilePicture == null
                ? Icon(Icons.person, size: 18, color: Colors.green[700])
                : null,
          ),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info and time
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      const Spacer(),
                      if (showDeleteButton && onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Comment content
                  Text(
                    comment.content,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
