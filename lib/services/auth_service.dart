// lib/services/auth_service.dart - Complete Authentication Service with 2FA
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Auth Status Enum
enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isAuthenticated = false;
  AuthStatus _authStatus = AuthStatus.unknown;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  AuthStatus get authStatus => _authStatus;
  AuthStatus get status => _authStatus; // Alias for authStatus
  String? get userType => _user?['user_type'];
  String? get username => _user?['username'];
  String? get email => _user?['email'];
  int? get userId => _user?['id'];

  // Production backend URL
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  // ==================== INITIALIZATION ====================

  /// Initialize and check if user is already logged in
  Future<void> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('token')) {
        _isAuthenticated = false;
        _authStatus = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      _token = prefs.getString('token');
      
      if (_token != null) {
        // Try to load cached user data first
        final cachedUser = prefs.getString('user');
        if (cachedUser != null) {
          _user = json.decode(cachedUser);
        }

        // Verify token is still valid
        final isValid = await verifyToken();
        if (isValid) {
          _isAuthenticated = true;
          _authStatus = AuthStatus.authenticated;
          await fetchProfile();
        } else {
          // Token expired, clear it
          await logout();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Auto-login error: $e');
      _authStatus = AuthStatus.unauthenticated;
      await logout();
    }
  }

  // ==================== 2FA REGISTRATION FLOW ====================

  /// Step 1: Request verification code for farmer registration
  Future<void> requestRegistrationCode(Map<String, dynamic> registrationData) async {
    final url = Uri.parse('$baseUrl/api/auth/request-verification/');

    try {
      if (!registrationData.containsKey('email')) {
        throw Exception('Email is required');
      }

      final requestBody = {
        ...registrationData,
        'purpose': 'registration',
      };

      debugPrint('🔐 Requesting registration code for: ${registrationData['email']}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ Verification code sent to ${registrationData['email']}');
        return;
      } else if (response.statusCode == 429) {
        throw Exception(responseData['error'] ?? 'Too many requests. Please wait 15 minutes.');
      } else if (response.statusCode == 400) {
        String errorMessage = 'Registration failed. Please check your information.';
        
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          } else {
            final errors = <String>[];
            responseData.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errors.add('$key: ${value[0]}');
              } else if (value is String) {
                errors.add('$key: $value');
              } else if (value is Map) {
                value.forEach((nestedKey, nestedValue) {
                  if (nestedValue is List && nestedValue.isNotEmpty) {
                    errors.add('$nestedKey: ${nestedValue[0]}');
                  }
                });
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join('\n');
            }
          }
        }
        throw Exception(errorMessage);
      } else {
        throw Exception(responseData['error'] ?? 'Failed to send verification code');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}. Please try again.');
    } on FormatException {
      throw Exception('Invalid response from server. Please try again.');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Request verification error: $e');
      throw Exception('Failed to request verification code. Please try again.');
    }
  }

  /// Step 2: Verify code and complete registration
  Future<void> verifyAndRegister(String email, String code) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-and-register/');

    try {
      debugPrint('🔐 Verifying registration code for: $email');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
          'purpose': 'registration',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      debugPrint('📡 Verify response status: ${response.statusCode}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = responseData['token'];
        _user = responseData['user'];
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
        debugPrint('✅ Registration successful: ${_user!['username']}');
        return;
      } else if (response.statusCode == 400) {
        final error = responseData['error'] ?? 'Invalid verification code';
        throw Exception(error);
      } else if (response.statusCode == 404) {
        throw Exception('Verification code not found. Please request a new one.');
      } else {
        throw Exception(responseData['error'] ?? 'Verification failed. Please try again.');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Verify registration error: $e');
      throw Exception('Verification failed. Please try again.');
    }
  }

  // ==================== 2FA LOGIN FLOW ====================

  /// Step 1: Request verification code for login
  Future<void> requestLoginCode(String email) async {
    final url = Uri.parse('$baseUrl/api/auth/request-verification/');

    try {
      debugPrint('🔐 Requesting login code for: $email');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'purpose': 'login',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ Login code sent to $email');
        return;
      } else if (response.statusCode == 429) {
        throw Exception(responseData['error'] ?? 'Too many requests. Please wait.');
      } else if (response.statusCode == 404) {
        throw Exception('No account found with this email.');
      } else {
        throw Exception(responseData['error'] ?? 'Failed to send login code');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Request login code error: $e');
      throw Exception('Failed to request login code. Please try again.');
    }
  }

  /// Step 2: Verify code and complete login
  Future<void> verifyAndLogin(String email, String code, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/verify-and-login/');

    try {
      debugPrint('🔐 Verifying login code for: $email');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
          'password': password,
          'purpose': 'login',
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['token'];
        _user = responseData['user'];
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
        debugPrint('✅ Login successful: ${_user!['username']}');
        return;
      } else if (response.statusCode == 400) {
        throw Exception(responseData['error'] ?? 'Invalid verification code');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid password');
      } else if (response.statusCode == 404) {
        throw Exception('Account not found');
      } else if (response.statusCode == 403) {
        throw Exception(responseData['error'] ?? 'Account is inactive');
      } else {
        throw Exception(responseData['error'] ?? 'Login failed');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Verify login error: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  // ==================== OLD LOGIN METHOD (FALLBACK) ====================

  /// Traditional login without 2FA (for backwards compatibility)
  Future<void> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login/');

    try {
      debugPrint('🔐 Attempting login for: $username');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _token = responseData['token'];
        _user = responseData['user'];
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
        debugPrint('✅ Login successful: ${_user!['username']}');
        return;
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        throw Exception(responseData['error'] ?? 'Invalid username or password');
      } else {
        throw Exception(responseData['error'] ?? 'Login failed');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Login failed. Please try again.');
    }
  }

  // ==================== RESEND CODE ====================

  /// Resend verification code
  Future<void> resendVerificationCode(String email, String purpose) async {
    final url = Uri.parse('$baseUrl/api/auth/resend-code/');

    try {
      debugPrint('🔄 Resending $purpose code to: $email');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'purpose': purpose,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ Code resent to $email');
        return;
      } else if (response.statusCode == 429) {
        throw Exception(responseData['error'] ?? 'Maximum resend limit reached. Please try again later.');
      } else if (response.statusCode == 404) {
        throw Exception('No pending verification found. Please start over.');
      } else {
        throw Exception(responseData['error'] ?? 'Failed to resend code');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Resend code error: $e');
      throw Exception('Failed to resend code. Please try again.');
    }
  }

  // ==================== FARMER REGISTRATION (OLD METHOD) ====================

  /// Register farmer (old direct method without 2FA)
  /// Kept for backwards compatibility
  Future<void> registerFarmer(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/auth/register/farmer/');

    try {
      debugPrint('🔐 Registering farmer (old method): ${data['email']}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = responseData['token'];
        _user = responseData['user'];
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
        debugPrint('✅ Farmer registered: ${_user!['username']}');
        return;
      } else {
        throw Exception(responseData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration failed. Please try again.');
    }
  }

  // ==================== EXTENSION WORKER REGISTRATION ====================

  /// Register extension worker with file upload
  Future<void> registerExtensionWorker(
    Map<String, dynamic> data, {
    File? verificationDocument,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register/extension-worker/');
    
    try {
      debugPrint('🔐 Registering extension worker: ${data['email']}');

      var request = http.MultipartRequest('POST', url);
      
      data.forEach((key, value) {
        if (value != null) {
          if (value is Map) {
            request.fields[key] = json.encode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });

      if (verificationDocument != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'verification_document',
            verificationDocument.path,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout. Please try again.');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        _token = responseData['token'];
        _user = responseData['user'];
        _isAuthenticated = true;
        _authStatus = AuthStatus.authenticated;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('user', json.encode(_user));

        notifyListeners();
        debugPrint('✅ Extension worker registered: ${_user!['username']}');
        return;
      } else if (response.statusCode == 400) {
        String errorMessage = 'Registration failed.';
        
        if (responseData is Map) {
          if (responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else {
            final errors = <String>[];
            responseData.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errors.add('$key: ${value[0]}');
              }
            });
            if (errors.isNotEmpty) {
              errorMessage = errors.join('\n');
            }
          }
        }
        throw Exception(errorMessage);
      } else {
        throw Exception(responseData['error'] ?? 'Registration failed');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Extension worker registration error: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  // ==================== PROFILE MANAGEMENT ====================

  /// Fetch user profile
  Future<void> fetchProfile() async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$baseUrl/api/auth/profile/');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        _user = json.decode(response.body);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        
        notifyListeners();
        debugPrint('✅ Profile fetched: ${_user!['username']}');
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch profile');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Fetch profile error: $e');
      throw Exception('Failed to fetch profile');
    }
  }

  /// Update profile
  Future<void> updateProfile(
    Map<String, dynamic> data, {
    File? profilePicture,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$baseUrl/api/auth/profile/update/');

    try {
      if (profilePicture != null) {
        var request = http.MultipartRequest('PUT', url);
        request.headers['Authorization'] = 'Token $_token';
        
        data.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });

        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
          ),
        );

        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 60),
        );
        final response = await http.Response.fromStream(streamedResponse);
        
        if (response.statusCode == 200) {
          await fetchProfile();
          debugPrint('✅ Profile updated with picture');
          return;
        } else {
          final responseData = json.decode(response.body);
          throw Exception(responseData['error'] ?? 'Failed to update profile');
        }
      } else {
        final response = await http.put(
          url,
          headers: {
            'Authorization': 'Token $_token',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(data),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          await fetchProfile();
          debugPrint('✅ Profile updated');
          return;
        } else {
          final responseData = json.decode(response.body);
          throw Exception(responseData['error'] ?? 'Failed to update profile');
        }
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  /// Change password
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$baseUrl/api/auth/change-password/');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ Password changed successfully');
        return;
      } else {
        throw Exception(responseData['error'] ?? 'Failed to change password');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      debugPrint('❌ Change password error: $e');
      throw Exception('Failed to change password');
    }
  }

  // ==================== LOGOUT ====================

  /// Logout user
  Future<void> logout() async {
    if (_token != null) {
      try {
        final url = Uri.parse('$baseUrl/api/auth/logout/');
        await http.post(
          url,
          headers: {
            'Authorization': 'Token $_token',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('Logout API error (non-critical): $e');
      }
    }

    _token = null;
    _user = null;
    _isAuthenticated = false;
    _authStatus = AuthStatus.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
    debugPrint('✅ Logged out');
  }

  // ==================== TOKEN VERIFICATION ====================

  /// Verify token validity
  Future<bool> verifyToken() async {
    if (_token == null) return false;

    final url = Uri.parse('$baseUrl/api/auth/verify-token/');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Token verification error: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Check if user is logged in
  bool get isLoggedIn => _isAuthenticated && _token != null;

  /// Get user's full name
  String get fullName {
    if (_user == null) return 'User';
    final firstName = _user!['first_name'] ?? '';
    final lastName = _user!['last_name'] ?? '';
    if (firstName.isEmpty && lastName.isEmpty) {
      return _user!['username'] ?? 'User';
    }
    return '$firstName $lastName'.trim();
  }

  /// Check if user is a farmer
  bool get isFarmer => _user?['user_type'] == 'farmer';

  /// Check if user is an extension worker
  bool get isExtensionWorker => _user?['user_type'] == 'extension_worker';

  /// Get profile picture URL
  String? get profilePictureUrl => _user?['profile_picture'];

  /// Get phone number
  String? get phoneNumber => _user?['phone_number'];

  /// Get first name
  String? get firstName => _user?['first_name'];

  /// Get last name
  String? get lastName => _user?['last_name'];

  /// Set auth token (for use with other services like AIService)
  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    notifyListeners();
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    _token = null;
    _user = null;
    _isAuthenticated = false;
    _authStatus = AuthStatus.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');

    notifyListeners();
  }
}