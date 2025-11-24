// lib/services/auth_service.dart - UPDATED WITH BETTER 2FA HANDLING
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService with ChangeNotifier {
  final String _baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  String? _token;
  Map<String, dynamic>? _user;
  AuthStatus _status = AuthStatus.unknown;

  // Getters exposed to other services
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  // Helper getters for UI
  String? get userType => _user?['user_type'];
  String? get username => _user?['username'];
  String? get email => _user?['email'];

  AuthService() {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 100));
    await _tryAutoLogin();
  }

  // ==================== AUTO LOGIN & STORAGE ====================

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
      } else if (response.statusCode == 401) {
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      } else {
        await _clearStorage(prefs);
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> _clearStorage(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.remove('user_id');
    await prefs.remove('ai_chat_messages');
    await prefs.remove('current_session_id');
    await prefs.remove('ai_session_id');

    _token = null;
    _user = null;
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    _status = AuthStatus.authenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(user));
    notifyListeners();
  }

  // ==================== 1. NEW 2FA LOGIN FLOW ====================

  /// Step 1: Request Login Verification Code
  Future<void> requestLoginCode(String email) async {
    final url = Uri.parse('$_baseUrl/api/auth/request-verification/');
    
    debugPrint('🔐 Requesting login code for: $email');
    
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'purpose': 'login'}),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException('Request timed out. Server may be starting up.');
            },
          );

      debugPrint('📡 Login code response: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw _parseError(response);
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      throw Exception('Request timed out. Please try again.');
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  /// Step 2: Verify Code and Login
  Future<void> verifyAndLogin(
    String email,
    String code,
    String password,
  ) async {
    final url = Uri.parse('$_baseUrl/api/auth/verify-and-login/');
    
    debugPrint('🔓 Verifying login code for: $email');
    
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'code': code,
              'password': password,
              'purpose': 'login',
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Login verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data['token'], data['user']);
        debugPrint('✅ Login successful');
      } else {
        throw _parseError(response);
      }
    } catch (e) {
      debugPrint('❌ Login verification error: $e');
      rethrow;
    }
  }

  // ==================== 2. NEW 2FA FARMER REGISTRATION ====================

  /// Step 1: Request Registration Code
  Future<void> requestRegistrationCode(
    Map<String, dynamic> registrationData,
  ) async {
    final url = Uri.parse('$_baseUrl/api/auth/request-verification/');

    // Add purpose to the registration data
    final requestData = {
      ...registrationData,
      'purpose': 'registration',
    };

    final body = json.encode(requestData);
    debugPrint('🚀 SENDING TO BACKEND: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Request timed out. Server may be starting up.');
        },
      );

      debugPrint('📡 RESPONSE CODE: ${response.statusCode}');
      debugPrint('📡 RESPONSE BODY: ${response.body}');

      if (response.statusCode != 200) {
        throw _parseError(response);
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout: $e');
      throw Exception('Request timed out. Please try again in a moment.');
    } on SocketException catch (e) {
      debugPrint('❌ Network error: $e');
      throw Exception('Network error. Please check your internet connection.');
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  /// Step 2: Verify Code and Complete Farmer Registration
  Future<void> verifyAndRegister(String email, String code) async {
    final url = Uri.parse('$_baseUrl/api/auth/verify-and-register/');
    
    debugPrint('✅ Verifying registration code for: $email');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': code,
          'purpose': 'registration',
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📡 Registration verification response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data['token'], data['user']);
        debugPrint('✅ Registration successful');
      } else {
        throw _parseError(response);
      }
    } catch (e) {
      debugPrint('❌ Registration verification error: $e');
      rethrow;
    }
  }

  // ==================== 3. NEW 2FA EXTENSION WORKER FLOW ====================

  /// Step 1: Initiate Extension Worker Registration
  Future<void> initiateExtensionWorkerRegistration(
    Map<String, dynamic> data,
  ) async {
    // Reuses the standard request code endpoint
    await requestRegistrationCode(data);
  }

  /// Step 2: Complete Extension Worker Registration with File Upload
  Future<void> completeExtensionWorkerRegistration({
    required Map<String, dynamic> registrationData,
    required String verificationCode,
    File? verificationDocument,
  }) async {
    final url = Uri.parse('$_baseUrl/api/auth/complete-extension-worker-registration/');

    debugPrint('👨‍🏫 Completing extension worker registration');

    try {
      var request = http.MultipartRequest('POST', url);

      // Add email and code
      request.fields['email'] = registrationData['email'];
      request.fields['code'] = verificationCode;

      // Add verification document if provided
      if (verificationDocument != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'verification_document',
            verificationDocument.path,
          ),
        );
        debugPrint('📄 Verification document attached');
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Upload timed out');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📡 Extension worker response: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveAuthData(data['token'], data['user']);
        debugPrint('✅ Extension worker registration successful');
      } else {
        throw _parseError(response);
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Upload timeout: $e');
      throw Exception('Upload timed out. Please try again.');
    } catch (e) {
      debugPrint('❌ Extension worker registration error: $e');
      if (e is Exception) rethrow;
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // ==================== 4. GENERAL UTILITIES ====================

  Future<void> resendVerificationCode(String email, String purpose) async {
    final url = Uri.parse('$_baseUrl/api/auth/resend-code/');
    
    debugPrint('🔄 Resending code for: $email');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'purpose': purpose}),
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('📡 Resend response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw _parseError(response);
      }
    } catch (e) {
      debugPrint('❌ Resend error: $e');
      rethrow;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        await http
            .post(
              Uri.parse('$_baseUrl/api/auth/logout/'),
              headers: {
                'Authorization': 'Token $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 5))
            .catchError((_) => http.Response('', 400));
      }

      await _clearStorage(prefs);
      _status = AuthStatus.unauthenticated;
      notifyListeners();

      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  // ==================== 5. PROFILE MANAGEMENT ====================

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
        throw Exception('Failed to load profile (Status: ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
      throw Exception('Could not connect to the server or load profile data.');
    }
  }

  Future<void> updateProfile(
    Map<String, dynamic> updateData, {
    File? profilePicture,
  }) async {
    if (_token == null) throw Exception('User is not authenticated.');
    final url = Uri.parse('$_baseUrl/api/auth/profile/update/');

    try {
      http.Response response;

      if (profilePicture != null) {
        var request = http.MultipartRequest('PATCH', url);
        request.headers['Authorization'] = 'Token $_token';

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
          ),
        );

        updateData.forEach((key, value) {
          if (key != 'farmer_profile') {
            request.fields[key] = value.toString();
          }
        });

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        notifyListeners();
      } else {
        throw _parseError(response);
      }
    } catch (e) {
      debugPrint('❌ Profile update error: $e');
      rethrow;
    }
  }

  /// Helper to parse error messages from backend
  Exception _parseError(http.Response response) {
    try {
      final responseData = json.decode(response.body);
      String errorMessage = 'Request failed';

      if (responseData is Map) {
        if (responseData.containsKey('error')) {
          errorMessage = responseData['error'];
        } else if (responseData.containsKey('non_field_errors')) {
          errorMessage = responseData['non_field_errors'][0];
        } else if (responseData.isNotEmpty) {
          final firstValue = responseData.values.first;
          errorMessage = firstValue is List
              ? firstValue[0].toString()
              : firstValue.toString();
        }
      }
      return Exception(errorMessage);
    } catch (_) {
      return Exception('Request failed with status: ${response.statusCode}');
    }
  }
}