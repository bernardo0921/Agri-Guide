// lib/screens/home/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'edit_profile_page.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Base URL for constructing full image URLs
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  // State variables for data fetching and UI
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    // Listen to language changes to rebuild UI
    AppNotifiers.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    AppNotifiers.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Fetch the complete user profile from the backend
  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Fetch profile from backend
      await authService.fetchProfile();

      // Read the updated user data from the service
      final user = authService.user;

      setState(() {
        _profileData = user;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.unknownErrorOccurred;
          debugPrint('Profile fetch error: $e');
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

  /// Helper to safely get farmer profile data
  Map<String, dynamic>? _getFarmerProfile() {
    return _profileData?['farmer_profile'] as Map<String, dynamic>?;
  }

  /// Helper to get user initials for fallback avatar
  String _getInitials() {
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

      if (initials.isEmpty) {
        final username = _profileData!['username'] as String? ?? '';
        if (username.isNotEmpty) {
          initials = username[0];
        }
      }

      return initials.toUpperCase();
    }
    return 'U';
  }

  /// Get the full profile picture URL
  String? _getProfilePictureUrl() {
    final profilePicture = _profileData?['profile_picture'] as String?;
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

  /// Handle logout
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout(context);

      // Ensure navigation to login page immediately after logout
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the user's role and name for the header
    final String userType = _profileData?['user_type'] ?? 'user';
    final String firstName = _profileData?['first_name'] ?? 'Guest';
    final String lastName = _profileData?['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final bool isFarmer = userType == 'farmer';

    return ValueListenableBuilder(
      valueListenable: AppNotifiers.languageNotifier,
      builder: (context, language, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.myProfile,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green.shade700,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )
              : _error != null
              ? _buildErrorState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: <Widget>[
                    // 1. Profile Header Section
                    _buildProfileHeader(
                      fullName,
                      userType,
                      _profileData?['is_verified'] ?? false,
                    ),
                    const SizedBox(height: 25),

                    // 2. User Contact Information
                    _buildSectionHeader(AppStrings.accountDetails),
                    _buildDetailCard(
                      Icons.person_outline,
                      AppStrings.username,
                      _profileData?['username'] ?? 'N/A',
                    ),
                    _buildDetailCard(
                      Icons.email_outlined,
                      AppStrings.emailAddress,
                      _profileData?['email'] ?? 'N/A',
                    ),
                    _buildDetailCard(
                      Icons.phone_outlined,
                      AppStrings.phoneNumber,
                      _profileData?['phone_number'] ?? 'N/A',
                    ),
                    const SizedBox(height: 10),

                    // 3. Role-Specific Information (Farmer/Extension Worker)
                    if (isFarmer) ..._buildFarmerDetails(),

                    if (!isFarmer) ...[
                      _buildSectionHeader(AppStrings.workerDetails),
                      _buildDetailCard(
                        Icons.work_outline,
                        AppStrings.organization,
                        _profileData?['extension_worker_profile']?['organization'] ??
                            'N/A',
                      ),
                      _buildDetailCard(
                        Icons.badge_outlined,
                        AppStrings.employeeId,
                        _profileData?['extension_worker_profile']?['employee_id'] ??
                            'N/A',
                      ),
                      _buildDetailCard(
                        Icons.school_outlined,
                        AppStrings.specialization,
                        _profileData?['extension_worker_profile']?['specialization'] ??
                            'N/A',
                      ),
                    ],

                    const SizedBox(height: 30),

                    // 4. Action Buttons
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_profileData != null) {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (context) => EditProfilePage(
                                      initialData: _profileData!,
                                    ),
                                  ),
                                )
                                .then((_) {
                                  _fetchProfileData();
                                });
                          }
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: Text(
                          AppStrings.editProfile,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Logout Button
                    Center(
                      child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon: Icon(Icons.logout, color: Colors.red.shade700),
                        label: Text(
                          AppStrings.logout,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // --- UI Helpers ---

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 64),
            const SizedBox(height: 16),
            Text(
              AppStrings.failedToLoadProfile,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? AppStrings.unknownErrorOccurred,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchProfileData,
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String fullName,
    String userType,
    bool isVerified,
  ) {
    final profilePictureUrl = _getProfilePictureUrl();

    return Column(
      children: [
        Stack(
          children: [
            // Profile Picture
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200.withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 65,
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
                        _getInitials(),
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
            // Verification Badge
            if (isVerified)
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // User Name
        Text(
          fullName.isNotEmpty ? fullName : 'User',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // User Type / Role Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                userType == 'farmer' ? Icons.agriculture : Icons.work,
                size: 16,
                color: Colors.green.shade800,
              ),
              const SizedBox(width: 6),
              Text(
                userType == 'farmer'
                    ? AppStrings.farmer
                    : AppStrings.extensionWorker,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFarmerDetails() {
    final farmerProfile = _getFarmerProfile();
    if (farmerProfile == null) {
      return [
        _buildSectionHeader(AppStrings.farmingProfile),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              AppStrings.noFarmingProfileAvailable,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      ];
    }

    final String location = farmerProfile['location'] ?? 'N/A';
    final String region = farmerProfile['region'] ?? 'N/A';
    final String farmName = farmerProfile['farm_name'] ?? 'N/A';
    final String farmSize = farmerProfile['farm_size'] != null
        ? '${farmerProfile['farm_size']} ${AppStrings.acres}'
        : 'N/A';
    final String cropsGrown = farmerProfile['crops_grown'] ?? 'N/A';
    final String farmingMethod = farmerProfile['farming_method'] ?? 'N/A';
    final String yearsOfExperience =
        farmerProfile['years_of_experience'] != null
        ? '${farmerProfile['years_of_experience']} ${AppStrings.years}'
        : 'N/A';

    return [
      _buildSectionHeader(AppStrings.farmingProfile),

      // Farm Identity
      if (farmName != 'N/A')
        _buildDetailCard(Icons.agriculture, AppStrings.farmName, farmName),
      if (farmSize != 'N/A')
        _buildDetailCard(Icons.landscape, AppStrings.farmSize, farmSize),

      // Location
      if (location != 'N/A')
        _buildDetailCard(Icons.location_on, AppStrings.location, location),
      if (region != 'N/A')
        _buildDetailCard(Icons.map, AppStrings.region, region),

      // Farming Practices
      if (cropsGrown != 'N/A')
        _buildDetailCard(Icons.grass, AppStrings.cropsGrownLabel, cropsGrown),
      if (farmingMethod != 'N/A')
        _buildDetailCard(Icons.eco, AppStrings.farmingMethod, farmingMethod),
      if (yearsOfExperience != 'N/A')
        _buildDetailCard(
          Icons.trending_up,
          AppStrings.yearsOfExperience,
          yearsOfExperience,
        ),

      const SizedBox(height: 10),
    ];
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
