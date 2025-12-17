import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/providers/theme_provider.dart';
import 'package:agri_guide/core/notifiers/app_notifiers.dart';
import 'package:agri_guide/core/language/app_strings.dart';
import 'package:agri_guide/core/language/app_language.dart';
import 'package:agri_guide/config/theme.dart';
import 'package:agri_guide/config/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Helper to construct URLs
  String _makeUrl(String path) {
    // Remove /api if it exists in baseUrl to construct frontend/landing page URLs
    // Assuming landing pages are at the root or under specific paths relative to domain
    // If your backend and frontend are same domain:
    final baseUrl = ApiConfig.baseUrl.endsWith('/') 
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1) 
        : ApiConfig.baseUrl;
    
    // Ensure path starts with /
    final cleanPath = path.startsWith('/') ? path : '/$path';
    
    return '$baseUrl$cleanPath';
  }

  Future<void> _launchUrl(String path) async {
    final urlString = _makeUrl(path);
    final Uri url = Uri.parse(urlString);
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $urlString'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching URL: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final currentLanguage = AppNotifiers.languageNotifier.value;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppStrings.selectLanguage),
          content: SingleChildScrollView(
            child: Column(
              children: AppLanguage.supportedLanguages.map((language) {
                final isSelected = language.code == currentLanguage.code;
                return ListTile(
                  title: Text(language.displayName),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!isSelected) {
                      // Update language preference
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('language_code', language.code);

                      // Update the language notifier
                      AppNotifiers.languageNotifier.value = language;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.languageChangedTo(language.displayName)),
                          backgroundColor: AppColors.successGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: AppNotifiers.languageNotifier,
          builder: (context, language, child) {
            return Text(AppStrings.settings);
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: AppNotifiers.languageNotifier,
        builder: (context, language, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appearance Section
                _buildSectionHeader(AppStrings.appearance, isDark),
                _buildThemeSettingTile(isDark),
                const SizedBox(height: 8),
                _buildLanguageTile(isDark),
                const Divider(height: 1),

                // Notifications Section
                _buildSectionHeader(AppStrings.notifications, isDark),
                _buildComingSoonTile(
                  AppStrings.pushNotifications,
                  Icons.notifications,
                  isDark,
                ),
                _buildComingSoonTile(
                  AppStrings.emailNotifications,
                  Icons.email,
                  isDark,
                ),
                const Divider(height: 1),

                // Privacy & Security Section
                _buildSectionHeader(AppStrings.privacySecurity, isDark),
                _buildComingSoonTile(
                  AppStrings.privacySettings,
                  Icons.lock,
                  isDark,
                ),
                _buildComingSoonTile(
                  AppStrings.changePassword,
                  Icons.vpn_key,
                  isDark,
                ),
                const Divider(height: 1),

                // Account Section
                _buildSectionHeader(AppStrings.account, isDark),
                _buildComingSoonTile(
                  AppStrings.manageProfile,
                  Icons.person,
                  isDark,
                ),
                _buildComingSoonTile(
                  AppStrings.connectedApps,
                  Icons.apps,
                  isDark,
                ),
                const Divider(height: 1),

                // Support Section
                _buildSectionHeader(AppStrings.support, isDark),
                _buildUrlTile(
                  AppStrings.helpFeedback,
                  Icons.help,
                  isDark,
                  'help-and-feedback/',
                ),
                _buildComingSoonTile(
                  AppStrings.reportBug,
                  Icons.bug_report,
                  isDark,
                ),
                const Divider(height: 1),

                // About Section
                _buildSectionHeader(AppStrings.about, isDark),
                _buildUrlTile(
                  AppStrings.termsOfService,
                  Icons.description,
                  isDark,
                  'terms-of-service/',
                ),
                _buildUrlTile(
                  AppStrings.privacyPolicy,
                  Icons.shield,
                  isDark,
                  'privacy-policy/',
                ),
                _buildVersionInfo(isDark),
                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: Text(AppStrings.logout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRed,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildThemeSettingTile(bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryGreen.withValues(alpha: 0.2)
                      : AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.dark_mode, color: AppColors.primaryGreen),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.darkMode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textWhite
                            : AppColors.textDark,
                      ),
                    ),
                    Text(
                      themeProvider.isDarkMode
                          ? AppStrings.enabled
                          : AppStrings.disabled,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? AppStrings.darkModeEnabled
                            : AppStrings.lightModeEnabled,
                      ),
                      backgroundColor: AppColors.successGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                activeThumbColor: AppColors.primaryGreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageTile(bool isDark) {
    return GestureDetector(
      onTap: () => _selectLanguage(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.language, color: AppColors.textMedium),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.language,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: AppNotifiers.languageNotifier,
                    builder: (context, AppLanguage currentLang, child) {
                      return Text(
                        currentLang.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTile(String title, IconData icon, bool isDark, String path) {
    return GestureDetector(
      onTap: () => _launchUrl(path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textMedium),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonTile(String title, IconData icon, bool isDark) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.comingSoonFor(title)),
            backgroundColor: AppColors.accentOrange,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.textMedium),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
                Text(
                  AppStrings.comingSoon,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primaryGreen.withValues(alpha: 0.2)
                  : AppColors.paleGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appVersion,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
                Text(
                  AppStrings.version,
                  style: TextStyle(fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.logout),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  void _performLogout() {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.logout(context);
  }
}
