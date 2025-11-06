import 'package:agri_guide/screens/home/Navigation_pages/drawer_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const DashboardPageContent(),
    const AIAdvisoryPage(),
    const CommunityPageContent(),
    const LMSPageContent(),
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
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
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
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            }
          });
          
          // Show loading while redirecting
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is authenticated, show the home screen
        return Scaffold(
          drawer: AppDrawer(
            onNavigate: _onNavItemTapped,
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