// lib/widgets/logout_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // If user confirmed logout
    if (shouldLogout == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Get auth service and logout
        final authService = Provider.of<AuthService>(context, listen: false);

        print('🔐 Starting logout process...');
        await authService.logout();

        print('✅ Logout successful');

        if (context.mounted) {
          // Close loading indicator
          Navigator.pop(context);

          // AuthWrapper will automatically handle navigation to LoginScreen
          // Just pop back to root to ensure clean navigation
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        print('❌ Logout error: $e');

        if (context.mounted) {
          // Close loading indicator
          Navigator.pop(context);

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error logging out: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout_rounded),
      tooltip: 'Logout',
      onPressed: () => _handleLogout(context),
    );
  }
}

// Alternative: Logout button with user menu dropdown
class UserMenuButton extends StatelessWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.user;

        return PopupMenuButton<String>(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (user?['username'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          tooltip: 'Account menu',
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['username'] ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['email'] ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const Divider(height: 16),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'profile',
              child: const Row(
                children: [
                  Icon(Icons.person_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'settings',
              child: const Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red.shade400)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'profile':
                // Navigate to profile page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile page coming soon')),
                );
                break;
              case 'settings':
                // Navigate to settings page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings page coming soon')),
                );
                break;
              case 'logout':
                await _handleLogout(context);
                break;
            }
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red.shade400),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    // If user confirmed logout
    if (shouldLogout == true && context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Get auth service and logout
        final authService = Provider.of<AuthService>(context, listen: false);

        await authService.logout();

        if (context.mounted) {
          // Close loading indicator
          Navigator.pop(context);

          // AuthWrapper will automatically handle navigation
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          // Close loading indicator
          Navigator.pop(context);

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error logging out: $e')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }
}
