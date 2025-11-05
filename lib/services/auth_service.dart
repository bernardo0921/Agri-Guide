// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // <-- This is the correct import
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// This enum helps the UI know what state we are in.
enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService with ChangeNotifier {
  // !! Replace with your Django server's URL
  // Use http://10.0.2.2:8000 for Android Emulator
  // Use http://localhost:8000 for iOS Simulator
  final String _baseUrl = 'http://192.168.100.7:5000/';

  String? _token;
  Map<String, dynamic>? _user;
  AuthStatus _status = AuthStatus.unknown;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  AuthService() {
    _tryAutoLogin();
  }

  // --- THIS METHOD IS NOW FIXED ---
  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey('token')) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    final storedToken = prefs.getString('token');
    if (storedToken == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // --- !! NEW VALIDATION LOGIC !! ---
    // We found a token, now we MUST verify it with the server.
    // We'll call the /api/auth/profile/ endpoint.
    final url = Uri.parse('$_baseUrl/api/auth/profile/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $storedToken', // Use the stored token
        },
      );

      if (response.statusCode == 200) {
        // --- Token is VALID ---
        _token = storedToken;
        final responseData = json.decode(response.body);
        _user = responseData; // Your /profile/ endpoint returns user data

        // Refresh the user data in storage
        await prefs.setString('user', response.body);
        
        _status = AuthStatus.authenticated;
      } else {
        // --- Token is INVALID (e.g., 401 Unauthorized) ---
        // Clear the bad token
        await prefs.remove('token');
        await prefs.remove('user');
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // --- Network error, etc. ---
      // We can't log in if we can't reach the server
      _status = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
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
        prefs.setString('token', _token!);
        prefs.setString('user', json.encode(_user));

        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        throw Exception(responseData.values.first.toString());
      }
    } catch (e) {
      throw Exception('Login failed. ${e.toString()}');
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
        prefs.setString('token', _token!);
        prefs.setString('user', json.encode(_user));

        _status = AuthStatus.authenticated;
        notifyListeners();
      } else {
        String errorMessage = "Registration failed.";
        if (responseData is Map) {
          errorMessage = responseData.values.first[0].toString();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Registration failed. ${e.toString()}');
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$_baseUrl/api/auth/logout/');
    
    if (_token != null) {
      try {
        await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
        );
      } catch (e) {
        print("Error logging out from server: $e");
      }
    }

    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('user');

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}