// lib/screens/home/Navigation_pages/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:agri_guide/widgets/logout_button.dart';

class DashboardPageContent extends StatelessWidget {
  const DashboardPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: const Color(0xFF7CB342),
        foregroundColor: Colors.white,
        actions: const [
          // Simple logout icon button
          LogoutButton(),
          
          // OR use the user menu dropdown (uncomment to use)
          // UserMenuButton(),
          
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your existing dashboard content
            const Text(
              'Welcome to Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Add your dashboard widgets here
            _buildStatCard(
              'Total Crops',
              '12',
              Icons.agriculture,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Active Tasks',
              '5',
              Icons.task_alt,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Weather Alerts',
              '2',
              Icons.wb_sunny,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
        ],
      ),
    );
  }
}