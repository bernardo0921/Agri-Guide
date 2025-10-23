import 'package:flutter/material.dart';

// App Drawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(
          0xFFF5F5F5,
        ), // Light background matching your screens
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
                  colors: [
                    Color(0xFF7CB342), // Matching green from your app
                    Color(0xFF8BC34A),
                  ],
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
                  const Text(
                    'Farmer John',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'john@harvestanalytics.com',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.home_rounded,
              title: 'Home',
              onTap: () => Navigator.pop(context),
            ),
            _buildMenuItem(
              context,
              icon: Icons.store_rounded,
              title: 'Marketplace',
              onTap: () => Navigator.pop(context),
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
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
