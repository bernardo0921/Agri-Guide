// FILE 2: notifications_page.dart (Updated)
// ============================================
// screens/notifications_page.dart
import 'package:agri_guide/screens/home/Navigation_pages/community/community_page.dart';
import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notifications_services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await NotificationService.getNotifications(
        unreadOnly: _showUnreadOnly,
      );

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      await NotificationService.markAsRead(notification.id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final count = await NotificationService.markAllAsRead();
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NotificationService.deleteNotification(notification.id);
        await _loadNotifications();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  /// Handle notification tap - Navigate to CommunityPage with postId
  Future<void> _onNotificationTap(AppNotification notification) async {
    // Mark as read first
    await _markAsRead(notification);

    if (!mounted) return;

    // Import CommunityPage at the top:
    // import '../path/to/community_page.dart';

    // Navigate to CommunityPage with the postId
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityPageWithPostHighlight(
          highlightPostId: notification.postId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          // Filter toggle
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showUnreadOnly ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              _loadNotifications();
            },
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread only',
          ),
          // Mark all as read
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _loadNotifications,
        color: colorScheme.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            return _buildNotificationCard(notification);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: GestureDetector(
        onTap: () => _onNotificationTap(notification), // Updated to navigate
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? colorScheme.surface : Colors.white)
                : colorScheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? Colors.grey[800]! : Colors.grey[200]!)
                  : colorScheme.primary.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                  image: notification.senderProfilePicture != null
                      ? DecorationImage(
                    image: NetworkImage(
                      notification.senderProfilePicture!,
                    ),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: notification.senderProfilePicture == null
                    ? Icon(Icons.person, color: colorScheme.primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Post preview (if available)
                    if (notification.postContentPreview.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification.postContentPreview,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Time
                    Text(
                      notification.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showUnreadOnly
                ? 'No unread notifications'
                : 'No notifications yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'You\'re all caught up!'
                : 'When you get notifications, they\'ll show up here',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

