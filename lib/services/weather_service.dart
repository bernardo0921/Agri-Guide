// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  // Get API key from .env file
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Fetch current weather for a city
  Future<Map<String, dynamic>?> getCurrentWeather({
    String city = 'Accra',
    String countryCode = 'GH',
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?q=$city,$countryCode&appid=$_apiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load weather: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return null;
    }
  }

  /// Get weather icon based on OpenWeather condition code
  String getWeatherIcon(int conditionCode) {
    // OpenWeather condition codes: https://openweathermap.org/weather-conditions
    if (conditionCode >= 200 && conditionCode < 300) {
      return 'thunderstorm';
    } else if (conditionCode >= 300 && conditionCode < 400) {
      return 'drizzle';
    } else if (conditionCode >= 500 && conditionCode < 600) {
      return 'rain';
    } else if (conditionCode >= 600 && conditionCode < 700) {
      return 'snow';
    } else if (conditionCode >= 700 && conditionCode < 800) {
      return 'atmosphere';
    } else if (conditionCode == 800) {
      return 'clear';
    } else if (conditionCode > 800) {
      return 'clouds';
    }
    return 'clear';
  }

  /// Format temperature
  String formatTemperature(double temp) {
    return '${temp.round()}°';
  }
}
