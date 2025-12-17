import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToHome();
  }

  void _setupAnimations() {
    // Fade animation for entire splash screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Dot animation loop
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  Future<void> _navigateToHome() async {
    // Wait for the splash duration
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // Check whether user has already seen the language selection
    final prefs = await SharedPreferences.getInstance();
    final seenLanguage = prefs.getBool('seen_language') ?? false;

    // Play fade animation then navigate to the appropriate screen
    await _fadeController.forward();

    if (!mounted) return;

    if (seenLanguage) {
      Navigator.of(context).pushReplacementNamed('/auth_wrapper');
    } else {
      Navigator.of(context).pushReplacementNamed('/language');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: AppColors.paleGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 100),
              // Content section with logo, title, and tagline
              Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'HARVEST ANALYTICS',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  Text(
                    'Grow Smarter. Yield More',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMedium,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              // Loading dots at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return AnimatedBuilder(
                      animation: _dotController,
                      builder: (context, child) {
                        // Calculate delay for each dot
                        final delay = index * 0.12;
                        final animValue = (_dotController.value - delay) % 1.0;

                        // Opacity animation
                        final opacity = (animValue < 0.3)
                            ? animValue / 0.3
                            : (animValue > 0.7)
                            ? 1 - (animValue - 0.7) / 0.3
                            : 1.0;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 
                              opacity * 0.8 + 0.2,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
