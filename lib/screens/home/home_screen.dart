import 'package:agri_guide/screens/home/Navigation_pages/pages/ai_advisory_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/community_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/dashboard_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/lms_page.dart';
import 'package:agri_guide/widgets/buttom_navigation_bar.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ... (imports and HomeScreen class remain the same)
// ... (imports and HomeScreen class remain the same)

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const DashboardPageContent(),
    const AIAdvisoryPage(),
    const CommunityPageContent(),
    const LMSPageContent(),
  ];

  // Page titles for AppBar
  final List<String> _pageTitles = [
    'Dashboard',
    'AI Advisory',
    'Community',
    'Learning',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthentication();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check authentication when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkAuthentication();
    }
  }

  /// Checks if user is authenticated
  Future<void> _checkAuthentication() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    // If not authenticated, redirect to login
    if (!authService.isLoggedIn) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- START OF MODIFIED MENU LOGIC ---
  // The _showProfileMenu method is now removed, and the logic is integrated
  // directly into the AppBar using PopupMenuButton.

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('View Profile - Coming soon')),
        );
        break;
      case 'settings':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings - Coming soon')));
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help & Support - Coming soon')),
        );
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  // Helper widget to build the styled menu items
  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String text, Color color) {
    return PopupMenuItem<String>(
      value: value,
      // Apply custom styling to the child widget
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout(context);
    }
  }

  String _getInitials() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user != null) {
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
      }

      final username = user['username'] as String? ?? '';
      if (username.isNotEmpty) {
        return username
            .substring(0, username.length > 2 ? 2 : username.length)
            .toUpperCase();
      }
    }

    return 'U';
  }
  // --- END OF MODIFIED MENU LOGIC ---

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // If user logs out while on this screen, redirect to login
        if (!authService.isLoggedIn) {
          // Use addPostFrameCallback to avoid calling setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          });

          // Show loading while redirecting
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated, show the home screen
        return Scaffold(
          appBar: AppBar(
            title: Text(_pageTitles[_selectedIndex]),
            actions: [
              // --- START OF NEW APPBAR ACTION WIDGET ---
              PopupMenuButton<String>(
                onSelected: _handleMenuSelection,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  // Custom styling applied via _buildMenuItem
                  _buildMenuItem(
                      'profile', Icons.person, 'View Profile', Colors.blue),
                  _buildMenuItem(
                      'settings', Icons.settings, 'Settings', Colors.grey.shade700),
                  _buildMenuItem(
                      'help', Icons.help_outline, 'Help & Support', Colors.orange),
                  const PopupMenuDivider(),
                  _buildMenuItem(
                      'logout', Icons.logout, 'Logout', Colors.red),
                ],
                // Apply styling to the menu itself for better appearance
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                color: Colors.white, // Background color of the menu
                // The widget that is displayed in the AppBar
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Text(
                      _getInitials(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // --- END OF NEW APPBAR ACTION WIDGET ---
            ],
          ),
          body: _screens[_selectedIndex],
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavItemTapped,
          ),
        );
      },
    );
  }
}