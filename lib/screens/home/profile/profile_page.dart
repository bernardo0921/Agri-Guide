// lib/screens/home/Navigation_pages/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'edit_profile_page.dart';
// Assuming the following imports are for image handling, keeping them
// import '../../../utils/file_picker_helper.dart';
// import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State variables for data fetching and UI
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  // Existing profile image variables (keeping for continuity)
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Refactored to fetch the *complete* user profile from the backend
  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // *** IMPORTANT: The AuthService must have a fetchProfile() method
      // that calls the /api/auth/profile/ endpoint and updates its user state.
      await authService.fetchProfile();

      // Read the updated user data from the service
      final user = authService.user;

      setState(() {
        _profileData = user;
        // The profile_picture URL is used directly from the response
        _profileImageUrl = user?['profile_picture'];
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile data. Please try again.';
          print('Profile fetch error: $e');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper to safely get farmer profile data
  Map<String, dynamic>? _getFarmerProfile() {
    return _profileData?['farmer_profile'] as Map<String, dynamic>?;
  }

  // Helper to get user initials for fallback avatar
  String _getInitials(BuildContext context) {
    if (_profileData != null) {
      final firstName = _profileData!['first_name'] as String? ?? '';
      final lastName = _profileData!['last_name'] as String? ?? '';

      String initials = '';
      if (firstName.isNotEmpty) {
        initials += firstName[0];
      }
      if (lastName.isNotEmpty) {
        initials += lastName[0];
      }
      return initials.toUpperCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Determine the user's role and name for the header
    final String userType = _profileData?['user_type'] ?? 'user';
    final String fullName =
        '${_profileData?['first_name'] ?? 'Guest'} ${_profileData?['last_name'] ?? ''}';
    final bool isFarmer = userType == 'farmer';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchProfileData,
                      child: const Text('Retry Load'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                // 1. Profile Header Section
                _buildProfileHeader(
                  context,
                  fullName,
                  userType,
                  _profileImageUrl,
                  _profileData?['is_verified'] ?? false,
                ),
                const SizedBox(height: 25),

                // 2. User Contact Information
                _buildSectionHeader('Account Details'),
                _buildDetailCard(
                  Icons.email,
                  'Email Address',
                  _profileData?['email'] ?? 'N/A',
                ),
                _buildDetailCard(
                  Icons.phone,
                  'Phone Number',
                  _profileData?['phone_number'] ?? 'N/A',
                ),
                const Divider(height: 20, color: Colors.black12),

                // 3. Role-Specific Information (Farmer/Extension Worker)
                if (isFarmer) ..._buildFarmerDetails(),

                if (!isFarmer) ...[
                  // Placeholder for Extension Worker details
                  _buildSectionHeader('Worker Details'),
                  _buildDetailCard(
                    Icons.work,
                    'Organization',
                    _profileData?['extension_worker_profile']?['organization'] ??
                        'N/A',
                  ),
                  // You can add more Extension Worker details here
                ],

                const SizedBox(height: 30),

                // 4. Action Buttons
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Edit Profile Page, passing the current data
                      if (_profileData != null) {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfilePage(initialData: _profileData!),
                              ),
                            )
                            .then((_) {
                              // Reload data when returning to ensure the page is fresh
                              _fetchProfileData();
                            });
                      }
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Placeholder for Logout/Settings
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement proper logout logic via AuthService
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logging out... (Placeholder)'),
                      ),
                    );
                  },
                  icon: Icon(Icons.logout, color: Colors.red.shade700),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
    );
  }

  // --- UI Helpers ---

  Widget _buildProfileHeader(
    BuildContext context,
    String fullName,
    String userType,
    String? profileImageUrl,
    bool isVerified,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            // Profile Picture/Initials Placeholder
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.green.shade100,
              // Use network image if available, otherwise show initials
              backgroundImage:
                  profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl) as ImageProvider<Object>?
                  : null,
              child: profileImageUrl == null || profileImageUrl.isEmpty
                  ? Text(
                      _getInitials(context),
                      style: TextStyle(
                        fontSize: 48,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            // Verification Badge
            if (isVerified)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.check, size: 24, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        // User Name
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E4620), // Deep Green
          ),
        ),
        const SizedBox(height: 5),
        // User Type / Role Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            userType.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFarmerDetails() {
    final farmerProfile = _getFarmerProfile();
    final String location = farmerProfile?['location'] ?? 'N/A';
    final String region = farmerProfile?['region'] ?? 'N/A';
    final String farmName = farmerProfile?['farm_name'] ?? 'N/A';
    // Format farm size and experience nicely
    final String farmSize = farmerProfile?['farm_size'] != null
        ? '${farmerProfile!['farm_size']} acres'
        : 'N/A';
    final String cropsGrown = farmerProfile?['crops_grown'] ?? 'N/A';
    final String farmingMethod = farmerProfile?['farming_method'] ?? 'N/A';
    final String yearsOfExperience =
        farmerProfile?['years_of_experience'] != null
        ? '${farmerProfile!['years_of_experience']} years'
        : 'N/A';

    return [
      _buildSectionHeader('Farming Profile'),

      // Grouping 1: Farm Identity
      _buildDetailCard(Icons.agriculture, 'Farm Name', farmName),
      _buildDetailCard(Icons.fence, 'Farm Size', farmSize),

      const Divider(height: 20, color: Colors.black12),

      // Grouping 2: Location
      _buildDetailCard(Icons.location_on, 'Location (Specific)', location),
      _buildDetailCard(Icons.map, 'Region', region),

      const Divider(height: 20, color: Colors.black12),

      // Grouping 3: Practices
      _buildDetailCard(Icons.grain, 'Primary Crops', cropsGrown),
      _buildDetailCard(Icons.eco, 'Farming Method', farmingMethod),
      _buildDetailCard(
        Icons.trending_up,
        'Years of Experience',
        yearsOfExperience,
      ),

      const Divider(height: 20, color: Colors.black12),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  // Enhanced _buildDetailCard for a farmer-friendly look
  Widget _buildDetailCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade50, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade50.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
