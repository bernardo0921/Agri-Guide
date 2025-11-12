// lib/services/farming_tip_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FarmingTipService {
  static const String baseUrl = 'http://192.168.100.7:5000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  // static const String baseUrl = 'https://your-production-url.com'; // Production

  static const String _cacheKey = 'cached_farming_tip';
  static const String _cacheDateKey = 'cached_tip_date';

  /// Fetch daily farming tip from backend
  Future<Map<String, dynamic>> getDailyFarmingTip(String token) async {
    try {
      // Check cache first
      final cachedTip = await _getCachedTip();
      if (cachedTip != null) {
        return cachedTip;
      }

      // Fetch from API
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/farming-tip/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the tip
        await _cacheTip(data);

        return {
          'success': true,
          'tip': data['tip'],
          'cached': data['cached'] ?? false,
          'fallback': data['fallback'] ?? false,
          'date': data['date'],
        };
      } else {
        throw Exception('Failed to load farming tip: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached tip if available, otherwise return default
      final cachedTip = await _getCachedTip();
      if (cachedTip != null) {
        return {...cachedTip, 'error': true, 'errorMessage': e.toString()};
      }

      // Return default fallback tip
      return {
        'success': false,
        'tip': _getDefaultFallbackTip(),
        'fallback': true,
        'error': true,
        'errorMessage': e.toString(),
      };
    }
  }

  /// Get cached tip from local storage
  Future<Map<String, dynamic>?> _getCachedTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTip = prefs.getString(_cacheKey);
      final cachedDate = prefs.getString(_cacheDateKey);

      if (cachedTip != null && cachedDate != null) {
        final today = DateTime.now().toIso8601String().split('T')[0];

        // Check if cache is from today or yesterday (within 2 days)
        final cacheDateTime = DateTime.parse(cachedDate);
        final todayDateTime = DateTime.now();
        final difference = todayDateTime.difference(cacheDateTime).inDays;

        if (difference <= 1) {
          return {
            'success': true,
            'tip': cachedTip,
            'cached': true,
            'date': cachedDate,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cache tip to local storage
  Future<void> _cacheTip(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, data['tip']);
      await prefs.setString(_cacheDateKey, data['date']);
    } catch (e) {
      // Silently fail - caching is not critical
    }
  }

  /// Get default fallback tip
  String _getDefaultFallbackTip() {
    final tips = [
      "Water your plants early in the morning to reduce water loss through evaporation. This also helps prevent fungal diseases that thrive in moist conditions during cooler evening hours.",
      "Rotate your crops each season to prevent soil nutrient depletion and reduce pest buildup. For example, follow nitrogen-fixing legumes with heavy feeders like corn or tomatoes.",
      "Apply mulch around your plants to reta soil moisture, regulate temperature, and suppress weeds. Organic mulches also improve soil health as they decompose.",
      "Monitor your crops regularly for early signs of pests or diseases. Early detection allows for quicker intervention and prevents widespread damage to your harvest.",
      "Test your soil pH annually to ensure optimal nutrient availability. Most crops thrive in slightly acidic to neutral soil (pH 6.0-7.0).",
    ];

    // Return random tip
    return tips[DateTime.now().day % tips.length];
  }

  /// Clear cached tip (useful for testing)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheDateKey);
    } catch (e) {
      // Silently fail
    }
  }
}
