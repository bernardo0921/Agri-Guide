// lib/screens/auth_wrapper.dart
import 'package:agri_guide/screens/home/home_screen.dart';
import 'package:agri_guide/screens/auth_screens/login_screen.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Check the auth status
    switch (authService.status) {
      case AuthStatus.unknown:
        // While checking token, show a branded loading screen
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7CB342), Color(0xFF8BC34A)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo or Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      size: 60,
                      color: Color(0xFF7CB342),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'AgriGuide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );

      case AuthStatus.authenticated:
        // User is logged in, show HomeScreen
        return const HomeScreen();

      case AuthStatus.unauthenticated:
        // User is not logged in, show LoginScreen
        return const LoginScreen();
    }
  }
}
