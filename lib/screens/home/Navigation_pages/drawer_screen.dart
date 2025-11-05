import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onNavigate;

  const AppDrawer({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFF5F5F5),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7CB342), Color(0xFF8BC34A)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFF5F5F5),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF7CB342),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display user info from AuthService
                  Consumer<AuthService>(
                    builder: (context, authService, child) {
                      final user = authService.user;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?['username'] ?? 'Farmer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?['email'] ?? 'user@agriguide.com',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              onTap: () {
                Navigator.pop(context);
                if (onNavigate != null) onNavigate!(0);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.psychology_rounded,
              title: 'AI Advisory',
              onTap: () {
                Navigator.pop(context);
                if (onNavigate != null) onNavigate!(1);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.store_rounded,
              title: 'Market Info',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.people_rounded,
              title: 'Community',
              onTap: () {
                Navigator.pop(context);
                if (onNavigate != null) onNavigate!(2);
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.school_rounded,
              title: 'Learning LMS',
              onTap: () {
                Navigator.pop(context);
                if (onNavigate != null) onNavigate!(3);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: Color(0xFFE0E0E0), height: 1),
            ),
            _buildMenuItem(
              context,
              icon: Icons.shopping_cart_rounded,
              title: 'My Orders',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.agriculture_rounded,
              title: 'Sell Your Harvest',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.person_rounded,
              title: 'Profile',
              onTap: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: Color(0xFFE0E0E0), height: 1),
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings_rounded,
              title: 'Settings',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.help_rounded,
              title: 'Help & Support',
              onTap: () => Navigator.pop(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(color: Color(0xFFE0E0E0), height: 1),
            ),
            _buildMenuItem(
              context,
              icon: Icons.logout_rounded,
              title: 'Logout',
              iconColor: const Color(0xFFE57373),
              textColor: const Color(0xFFE57373),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Close drawer first
    Navigator.pop(context);

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFE57373)),
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
        builder: (context) => const Center(child: CircularProgressIndicator()),
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

          // SIMPLIFIED: No manual navigation needed!
          // AuthWrapper will automatically detect the status change
          // and show LoginScreen

          // Optional: Navigate to root to clear any nested navigation
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
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          icon,
          color: iconColor ?? const Color(0xFF7CB342),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor ?? const Color(0xFF333333),
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        horizontalTitleGap: 12,
      ),
    );
  }
}
