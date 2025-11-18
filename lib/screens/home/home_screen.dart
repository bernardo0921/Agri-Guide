import 'package:agri_guide/screens/home/Navigation_pages/ai/ai_advisory_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/community/community_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/dashboard_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/lms/lms_page.dart';
import 'package:agri_guide/widgets/buttom_navigation_bar.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'profile/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Base URL for constructing full image URLs
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  int _selectedIndex = 0;

  // List of screens for each navigation item
  late final List<Widget> _screens;

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

    // Initialize screens with navigation callback
    _screens = [
      DashboardPageContent(onNavigate: _onNavItemTapped),
      const AIAdvisoryPage(),
      const CommunityPage(),
      const LMSPageContent(),
    ];
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

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'profile':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const ProfilePage()));
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

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String text,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: value,
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

  /// Get user initials for avatar fallback
  String _getInitials(AuthService authService) {
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

  /// Get the full profile picture URL
  String? _getProfilePictureUrl(AuthService authService) {
    final user = authService.user;
    if (user == null) return null;

    final profilePicture = user['profile_picture'] as String?;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      // If it's already a full URL, return it
      if (profilePicture.startsWith('http')) {
        return profilePicture;
      }
      // Otherwise, prepend the base URL
      return '$baseUrl$profilePicture';
    }
    return null;
  }

  /// Build AppBar actions with profile avatar
  List<Widget> _buildAppBarActions(AuthService authService) {
    final profilePictureUrl = _getProfilePictureUrl(authService);
    final initials = _getInitials(authService);

    return [
      Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.shade100,
              backgroundImage: profilePictureUrl != null
                  ? NetworkImage(profilePictureUrl)
                  : null,
              onBackgroundImageError: profilePictureUrl != null
                  ? (exception, stackTrace) {
                      debugPrint('Error loading profile image: $exception');
                    }
                  : null,
              child: profilePictureUrl == null
                  ? Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (!authService.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          });

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            // Don't show leading button, let AIAdvisoryPage handle its own drawer
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                if (_selectedIndex == 1) ...[
                  Icon(Icons.eco, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 8),
                ],
                Text(_pageTitles[_selectedIndex]),
              ],
            ),
            actions: _buildAppBarActions(authService),
          ),
          body: IndexedStack(index: _selectedIndex, children: _screens),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onNavItemTapped,
          ),
        );
      },
    );
  }
}
