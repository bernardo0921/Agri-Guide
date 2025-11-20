// widgets/comment_card.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../config/theme.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
              color: AppColors.paleGreen,
              image: comment.userProfilePicture != null
                  ? DecorationImage(
                      image: NetworkImage(comment.userProfilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: comment.userProfilePicture == null
                ? Icon(
                    Icons.person,
                    size: 18,
                    color: AppColors.primaryGreen,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Comment Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppColors.surfaceDark 
                    : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info and time
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? AppColors.textWhite : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        comment.timeAgo,
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      if (showDeleteButton && onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Comment content
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                    ),
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