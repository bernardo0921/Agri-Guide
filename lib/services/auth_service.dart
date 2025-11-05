// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService with ChangeNotifier {
  // Replace with your Django server's URL
  final String _baseUrl = 'http://192.168.100.7:5000';

  String? _token;
  Map<String, dynamic>? _user;
  AuthStatus _status = AuthStatus.unknown;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  AuthService() {
    // Don't block constructor - run async initialization
    _initialize();
  }

  // Separate initialization method
  Future<void> _initialize() async {
    // Add small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 100));
    await _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey('token')) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final storedToken = prefs.getString('token');
      if (storedToken == null || storedToken.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Validate token with server
      final url = Uri.parse('$_baseUrl/api/auth/profile/');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $storedToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return http.Response('{"error": "timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        // Token is valid
        _token = storedToken;
        final responseData = json.decode(response.body);
        _user = responseData;

        // Refresh the user data in storage
        await prefs.setString('user', response.body);
        
        _status = AuthStatus.authenticated;
        print('✅ Auto-login successful');
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        print('⚠️ Token invalid, clearing storage');
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      } else {
        // Other error, still clear storage to be safe
        print('⚠️ Server error (${response.statusCode}), clearing storage');
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // Network error or other exception
      print('❌ Auto-login error: $e');
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  Future<void> _clearStorage(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
  }

  Future<void> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/api/auth/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['token'];
        _user = responseData['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        // Extract error message from response
        String errorMessage = 'Login failed';
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData.containsKey('non_field_errors')) {
            errorMessage = responseData['non_field_errors'][0];
          } else {
            errorMessage = responseData.values.first.toString();
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> registerFarmer(Map<String, dynamic> registrationData) async {
    final url = Uri.parse('$_baseUrl/api/auth/register/farmer/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registrationData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = responseData['token'];
        _user = responseData['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        // Extract error message
        String errorMessage = "Registration failed";
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData.isNotEmpty) {
            final firstError = responseData.values.first;
            errorMessage = firstError is List ? firstError[0].toString() : firstError.toString();
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$_baseUrl/api/auth/logout/');
    
    if (_token != null) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
        ).timeout(const Duration(seconds: 5));
        
        print('🔐 Logout response: ${response.statusCode}');
        
        if (response.statusCode != 200) {
          print('⚠️ Logout failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
        }
      } catch (e) {
        print("❌ Error logging out from server: $e");
      }
    }

    // Always clear local data even if server request fails
    final prefs = await SharedPreferences.getInstance();
    await _clearStorage(prefs);

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    
    print('✅ Local logout completed');
  }

  // Optional: Method to refresh user profile
  Future<void> refreshUserProfile() async {
    if (_token == null) return;
    
    final url = Uri.parse('$_baseUrl/api/auth/profile/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user = responseData;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', response.body);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing profile: $e');
    }
  }
}