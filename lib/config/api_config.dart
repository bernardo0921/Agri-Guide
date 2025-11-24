// lib/config/api_config.dart
class ApiConfig {
  // Production backend URL - deployed on Render
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';
  
  // For local development, uncomment one of these:
  
  // For Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000';
  
  // For iOS Simulator:
  // static const String baseUrl = 'http://localhost:8000';
  
  // For Real Device (use your computer's local IP):
  // static const String baseUrl = 'http://192.168.1.100:8000';
}