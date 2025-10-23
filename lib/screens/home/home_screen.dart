import 'package:agri_guide/screens/home/Navigation_pages/drawer_screen.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/ai_advisory_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/community_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/dashboard_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/pages/lms_page.dart';
import 'package:agri_guide/screens/home/Navigation_pages/widgets/buttom_navigation_bar.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of screens for each navigation item
  final List<Widget> _screens = [
    const DashboardPageContent(),
    const AIAdvisoryPageContent(),
    const CommunityPageContent(),
    const LMSPageContent(),
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        onNavigate: _onNavItemTapped, // Pass the navigation callback
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

