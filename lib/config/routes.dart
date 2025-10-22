import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/language_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String language = '/language';
  static const String home = '/home';
  static const String marketplace = '/marketplace';
  static const String profile = '/profile';
  static const String orders = '/orders';
  static const String settings = '/settings';

  // Route map
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      language: (context) => const LanguageScreen(),
      home: (context) => const HomeScreen(),
      // marketplace: (context) => const MarketplaceScreen(),
      // profile: (context) => const ProfileScreen(),
      // orders: (context) => const OrdersScreen(),
      // settings: (context) => const SettingsScreen(),
    };
  }
}