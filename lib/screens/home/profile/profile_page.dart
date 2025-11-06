// lib/screens/home/Navigation_pages/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart'; // Ensure this path is correct

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Helper method to get initials (copied from home_screen.dart)
  String _getInitials(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    // We use a Consumer to react to real-time user data (e.g., if it changes)
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.user;
        final fullName =
            '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
        final email = user?['email'] ?? 'N/A';
        final username = user?['username'] ?? 'N/A';
        final initials = _getInitials(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Profile'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Profile Avatar
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green.shade400,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Full Name
                  Text(
                    fullName.isNotEmpty ? fullName : 'User',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  
                  // Username
                  Text(
                    '@$username',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // User Details Cards
                  _buildDetailCard(Icons.email, 'Email Address', email),
                  const SizedBox(height: 12),
                  _buildDetailCard(Icons.badge, 'Username', username),
                  const SizedBox(height: 12),
                  // Add more details here later (e.g., phone, location)
                  
                  // Action Button
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Placeholder for Edit Profile functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile - Coming soon')),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade600, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}