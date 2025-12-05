// lib/screens/home/profile/profile_page.dart
// 🎨 SUPERB ENHANCED VERSION - Beautiful, Modern, Premium UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'edit_profile_page.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fetchProfileData();
    AppNotifiers.languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    AppNotifiers.languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.fetchProfile();
      final user = authService.user;

      setState(() {
        _profileData = user;
      });
      _animationController.forward();
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

  String _getInitials() {
    if (_profileData != null) {
      final firstName = _profileData!['first_name'] as String? ?? '';
      final lastName = _profileData!['last_name'] as String? ?? '';

      String initials = '';
      if (firstName.isNotEmpty) initials += firstName[0];
      if (lastName.isNotEmpty) initials += lastName[0];

      if (initials.isEmpty) {
        final username = _profileData!['username'] as String? ?? '';
        if (username.isNotEmpty) initials = username[0];
      }

      return initials.toUpperCase();
    }
    return 'U';
  }

  String? _getProfilePictureUrl() {
    final profilePicture = _profileData?['profile_picture'] as String?;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (profilePicture.startsWith('http')) {
        return profilePicture;
      }
      return '$baseUrl$profilePicture';
    }
    return null;
  }

  Future<void> _handleLogout() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: colorScheme.error),
              const SizedBox(width: 12),
              Text(
                AppStrings.logoutTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            AppStrings.logoutConfirm,
            style: theme.textTheme.bodyLarge,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(AppStrings.logout),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.logout(context);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    final String userType = _profileData?['user_type'] ?? 'user';
    final String firstName = _profileData?['first_name'] ?? 'Guest';
    final String lastName = _profileData?['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final bool isFarmer = userType == 'farmer';

    return ValueListenableBuilder(
      valueListenable: AppNotifiers.languageNotifier,
      builder: (context, language, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              AppStrings.myProfile,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  if (_profileData != null) {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfilePage(initialData: _profileData!),
                          ),
                        )
                        .then((_) => _fetchProfileData());
                  }
                },
              ),
            ],
          ),
          body: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading profile...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : _error != null
              ? _buildErrorState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      // 🎨 STUNNING HEADER WITH GRADIENT
                      SliverToBoxAdapter(
                        child: _buildStunningHeader(
                          fullName,
                          userType,
                          _profileData?['is_verified'] ?? false,
                          isDarkMode,
                          colorScheme,
                        ),
                      ),

                      // 🌟 QUICK STATS (Optional - looks cool!)
                      if (isFarmer)
                        SliverToBoxAdapter(child: _buildQuickStats()),

                      // 📋 ACCOUNT DETAILS CARD
                      SliverToBoxAdapter(
                        child: _buildModernSection(
                          'Account Details',
                          Icons.account_circle,
                          [
                            _buildModernInfoTile(
                              Icons.person_outline,
                              'Username',
                              _profileData?['username'] ?? 'N/A',
                              colorScheme,
                            ),
                            _buildModernInfoTile(
                              Icons.email_outlined,
                              'Email Address',
                              _profileData?['email'] ?? 'N/A',
                              colorScheme,
                            ),
                            _buildModernInfoTile(
                              Icons.phone_outlined,
                              'Phone Number',
                              _profileData?['phone_number'] ?? 'N/A',
                              colorScheme,
                            ),
                          ],
                        ),
                      ),

                      // 🌾 FARMER WELCOME CARD
                      if (isFarmer)
                        SliverToBoxAdapter(
                          child: _buildPremiumFarmerCard(colorScheme),
                        ),

                      // 👨‍🏫 EXTENSION WORKER DETAILS
                      if (!isFarmer)
                        SliverToBoxAdapter(
                          child: _buildModernSection(
                            'Professional Details',
                            Icons.work,
                            [
                              _buildModernInfoTile(
                                Icons.business_outlined,
                                'Organization',
                                _profileData?['extension_worker_profile']?['organization'] ??
                                    'N/A',
                                colorScheme,
                              ),
                              _buildModernInfoTile(
                                Icons.badge_outlined,
                                'Employee ID',
                                _profileData?['extension_worker_profile']?['employee_id'] ??
                                    'N/A',
                                colorScheme,
                              ),
                              _buildModernInfoTile(
                                Icons.school_outlined,
                                'Specialization',
                                _profileData?['extension_worker_profile']?['specialization'] ??
                                    'N/A',
                                colorScheme,
                              ),
                            ],
                          ),
                        ),

                      // 🚀 ACTION BUTTONS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Edit Profile Button
                              _buildModernButton(
                                icon: Icons.edit_rounded,
                                label: 'Edit Profile',
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                onPressed: () {
                                  if (_profileData != null) {
                                    Navigator.of(context)
                                        .push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditProfilePage(
                                                  initialData: _profileData!,
                                                ),
                                          ),
                                        )
                                        .then((_) => _fetchProfileData());
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              // Logout Button
                              _buildModernButton(
                                icon: Icons.logout_rounded,
                                label: 'Logout',
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.error,
                                    colorScheme.error.withValues(alpha: 0.7),
                                  ],
                                ),
                                onPressed: _handleLogout,
                                isOutlined: true,
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // 🎨 STUNNING GRADIENT HEADER
  Widget _buildStunningHeader(
    String fullName,
    String userType,
    bool isVerified,
    bool isDarkMode,
    ColorScheme colorScheme,
  ) {
    final profilePictureUrl = _getProfilePictureUrl();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.secondary.withValues(alpha: 0.2),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
          child: Column(
            children: [
              // Profile Picture with Glow Effect
              Hero(
                tag: 'profile_picture',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          backgroundImage: profilePictureUrl != null
                              ? NetworkImage(profilePictureUrl)
                              : null,
                          onBackgroundImageError: profilePictureUrl != null
                              ? (exception, stackTrace) {
                                  debugPrint('Error loading image: $exception');
                                }
                              : null,
                          child: profilePictureUrl == null
                              ? Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    fontSize: 52,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              Text(
                fullName.isNotEmpty ? fullName : 'User',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // User Type Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      userType == 'farmer' ? Icons.agriculture : Icons.work,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userType == 'farmer' ? 'Farmer' : 'Extension Worker',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 QUICK STATS SECTION
  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.article,
              label: 'Posts',
              value: '12',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.favorite,
              label: 'Likes',
              value: '48',
              color: Colors.pink,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.comment,
              label: 'Comments',
              value: '23',
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 📋 MODERN SECTION
  Widget _buildModernSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // 📝 MODERN INFO TILE
  Widget _buildModernInfoTile(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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

  // 🌾 PREMIUM FARMER CARD
  Widget _buildPremiumFarmerCard(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade400, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.agriculture,
                size: 150,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.emoji_nature, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome, Farmer! 🌾',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect with the community, share your experiences, and learn from fellow farmers!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildFarmerFeature(Icons.forum, 'Community'),
                      const SizedBox(width: 20),
                      _buildFarmerFeature(Icons.tips_and_updates, 'AI Tips'),
                      const SizedBox(width: 20),
                      _buildFarmerFeature(Icons.school, 'Learn'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerFeature(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // 🎯 MODERN BUTTON
  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isOutlined ? null : gradient,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined
            ? Border.all(color: Theme.of(context).colorScheme.error, width: 2)
            : null,
        boxShadow: isOutlined
            ? null
            : [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isOutlined
                      ? Theme.of(context).colorScheme.error
                      : Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOutlined
                        ? Theme.of(context).colorScheme.error
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ⚠️ ERROR STATE
  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load profile',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _fetchProfileData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
