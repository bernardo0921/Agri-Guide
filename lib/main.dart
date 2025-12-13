// lib/main.dart
import 'package:agri_guide/screens/others/auth_wrapper.dart';
import 'package:agri_guide/services/auth_service.dart';
import 'package:agri_guide/providers/theme_provider.dart';
import 'package:agri_guide/services/notifications_services/local_notification_service.dart';
import 'package:agri_guide/screens/others/post_detail_screen.dart';
import 'package:agri_guide/screens/others/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- IMPORT YOUR APP'S FILES ---
import 'config/theme.dart';
import 'config/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize local notifications
  await LocalNotificationService.initialize();

  // Request notification permissions
  await LocalNotificationService.requestPermissions();

  // Initialize ThemeProvider before running the app
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthService()),
        ChangeNotifierProvider(create: (ctx) => themeProvider),
      ],
      child: const HarvestAnalyticsApp(),
    ),
  );
}

class HarvestAnalyticsApp extends StatelessWidget {
  const HarvestAnalyticsApp({super.key});

  /// Create a global navigator key for notification navigation
  static final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Set the navigator key in LocalNotificationService for notification handling
    LocalNotificationService.navigatorKey = _navigatorKey;

    // 1. Get your existing routes from AppRoutes
    final Map<String, WidgetBuilder> routes = AppRoutes.getRoutes();

    // 2. Add our new AuthWrapper route
    // This is the page that will decide to show Login or Home
    routes['/auth_wrapper'] = (ctx) => const AuthWrapper();

    // 3. Add post detail route with argument handling
    routes['/post_detail'] = (ctx) {
      final postId = ModalRoute.of(ctx)?.settings.arguments as String?;
      return PostDetailScreen(postId: postId ?? '');
    };

    // 4. Add notifications route
    routes['/notifications'] = (ctx) => const NotificationsPage();

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Harvest Analytics',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Set the global navigator key
          navigatorKey: _navigatorKey,

          // 3. Restore your original initialRoute
          // This will now correctly show your LanguageScreen first
          initialRoute: AppRoutes.splash,

          // 4. Use the routes map that now includes our new '/auth_wrapper' route
          routes: routes,

          // 'home' is removed, as 'initialRoute' handles the start page
        );
      },
    );
  }
}
