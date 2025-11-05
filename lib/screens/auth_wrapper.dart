// lib/screens/auth_wrapper.dart
import 'package:agri_guide/screens/home/home_screen.dart'; // Your existing home screen
import 'package:agri_guide/screens/auth_screens/login_screen.dart'; // From previous step
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
        // While checking token, show a loading screen.
        // You can replace this with your app's proper splash screen.
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
        
      case AuthStatus.authenticated:
        // User is logged in, show HomeScreen
        // This is your 'home_screen.dart'
        return const HomeScreen(); 
        
      case AuthStatus.unauthenticated:
      // default:
      //   // User is not logged in, show LoginScreen
        return const LoginScreen(); 
    }
  }
}