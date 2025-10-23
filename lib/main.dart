import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';

void main() {
  runApp(const HarvestAnalyticsApp());
}

class HarvestAnalyticsApp extends StatelessWidget {
  const HarvestAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvest Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routes: AppRoutes.getRoutes(),
      initialRoute: AppRoutes.splash,
    );
  }
}

// Temporary HomeScreen - will be replaced with actual screens