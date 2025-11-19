import 'package:agri_guide/screens/home/Navigation_pages/ai/ai_advisory_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/community/community_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/dashboard_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/lms/lms_page.dart';
import 'package:agri_guide/widgets/buttom_navigation_bar.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
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

    // Listen to language changes to rebuild UI
    AppNotifiers.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppNotifiers.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
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
        ).showSnackBar(SnackBar(content: Text(AppStrings.settingsComingSoon)));
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.helpSupportComingSoon)),
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
        title: Text(AppStrings.logoutTitle),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.logout),
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

  /// Get page titles based on current language
  List<String> get _pageTitles => [
        AppStrings.dashboard,
        AppStrings.aiAdvisory,
        AppStrings.community,
        AppStrings.learning,
      ];

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

          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return ValueListenableBuilder(
          valueListenable: AppNotifiers.languageNotifier,
          builder: (context, language, child) {
            return Scaffold(
              appBar: AppBar(
                // Don't show leading button, let AIAdvisoryPage handle its own drawer
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    if (_selectedIndex == 1) ...[
                      Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                        height: 80,
                      ),
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
      },
    );
  }
}