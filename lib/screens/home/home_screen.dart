import 'package:agri_guide/screens/home/Navigation_pages/drawer_screen.dart';
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
      drawer: const AppDrawer(),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
      ),
    );
  }
}

// Dashboard Page Content
class DashboardPageContent extends StatelessWidget {
  const DashboardPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Dashboard Page',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }
}

// AI Advisory Page Content
class AIAdvisoryPageContent extends StatelessWidget {
  const AIAdvisoryPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI Advisory',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'AI Advisory Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// Community Page Content
class CommunityPageContent extends StatelessWidget {
  const CommunityPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Community',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'Community Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

// LMS Page Content
class LMSPageContent extends StatelessWidget {
  const LMSPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Learning Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Center(
        child: Text(
          'LMS Page',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}