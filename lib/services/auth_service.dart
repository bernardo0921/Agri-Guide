// lib/services/auth_service.dart - UPDATED
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService with ChangeNotifier {
  final String _baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  String? _token;
  Map<String, dynamic>? _user;
  AuthStatus _status = AuthStatus.unknown;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
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

      final url = Uri.parse('$_baseUrl/api/auth/profile/');

      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $storedToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              return http.Response('{"error": "timeout"}', 408);
            },
          );

      if (response.statusCode == 200) {
        _token = storedToken;
        final responseData = json.decode(response.body);
        _user = responseData;

        await prefs.setString('user', response.body);

        _status = AuthStatus.authenticated;
        print('✅ Auto-login successful');
      } else if (response.statusCode == 401) {
        print('⚠️ Token invalid, clearing storage');
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      } else {
        print('⚠️ Server error (${response.statusCode}), clearing storage');
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
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
        body: json.encode({'username': username, 'password': password}),
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
        String errorMessage = "Registration failed";
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData.isNotEmpty) {
            final firstError = responseData.values.first;
            errorMessage = firstError is List
                ? firstError[0].toString()
                : firstError.toString();
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

  /// Register as Extension Worker with optional verification document
  Future<void> registerExtensionWorker(
    Map<String, dynamic> registrationData, {
    File? verificationDocument,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/register/extension-worker/');

    try {
      http.Response response;

      if (verificationDocument != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest('POST', url);

        // Add verification document
        request.files.add(
          await http.MultipartFile.fromPath(
            'extension_worker_profile.verification_document',
            verificationDocument.path,
          ),
        );

        // Add all text fields
        registrationData.forEach((key, value) {
          if (key != 'extension_worker_profile') {
            request.fields[key] = value.toString();
          }
        });

        // Add nested extension_worker_profile fields
        if (registrationData.containsKey('extension_worker_profile')) {
          final profile =
              registrationData['extension_worker_profile'] as Map<String, dynamic>;
          profile.forEach((key, value) {
            if (value != null && key != 'verification_document') {
              request.fields['extension_worker_profile.$key'] = value.toString();
            }
          });
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use JSON request for registration without document
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(registrationData),
        );
      }

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
        String errorMessage = "Registration failed";
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData.isNotEmpty) {
            final firstError = responseData.values.first;
            errorMessage = firstError is List
                ? firstError[0].toString()
                : firstError.toString();
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

  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        debugPrint('No token found. User may already be logged out.');
        return;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/logout/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await prefs.remove('token');
        await prefs.remove('user_id');

        _token = null;
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();

        debugPrint('Logout successful');
      } else {
        debugPrint('Logout failed: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logout failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  Future<void> fetchProfile() async {
    if (_token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

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

        _status = AuthStatus.authenticated;
        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        final prefs = await SharedPreferences.getInstance();
        await _clearStorage(prefs);
        throw Exception('Authentication failed. Please log in again.');
      } else {
        throw Exception(
          'Failed to load profile (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
      throw Exception('Could not connect to the server or load profile data.');
    }
  }

  /// Update profile with optional file upload
  Future<void> updateProfile(
    Map<String, dynamic> updateData, {
    File? profilePicture,
  }) async {
    if (_token == null) {
      throw Exception('User is not authenticated.');
    }

    final url = Uri.parse('$_baseUrl/api/auth/profile/update/');

    try {
      http.Response response;

      if (profilePicture != null) {
        // Use multipart request for file upload
        var request = http.MultipartRequest('PATCH', url);
        request.headers['Authorization'] = 'Token $_token';

        // Add profile picture
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
          ),
        );

        // Add text fields
        updateData.forEach((key, value) {
          if (key != 'farmer_profile') {
            request.fields[key] = value.toString();
          }
        });

        // Add nested farmer_profile fields with dot notation
        if (updateData.containsKey('farmer_profile')) {
          final farmerProfile = updateData['farmer_profile'] as Map<String, dynamic>;
          farmerProfile.forEach((key, value) {
            if (value != null) {
              request.fields['farmer_profile.$key'] = value.toString();
            }
          });
        }

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use JSON request for text-only updates
        response = await http.patch(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $_token',
          },
          body: json.encode(updateData),
        );
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _user = responseData['user'];

        // Update stored user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        String errorMessage = 'Validation Error: ';
        errorData.forEach((key, value) {
          errorMessage += '\n$key: ${value.join(", ")}';
        });
        throw Exception(errorMessage);
      } else {
        throw Exception(
          'Failed to update profile (Status: ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Profile update error: $e');
      rethrow;
    }
  }
}