import 'package:dio/dio.dart';
import 'dart:io';
import '../models/tutorial.dart';

class LMSApiService {
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';
  final Dio _dio;

  LMSApiService(String token)
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

  /// Fetch all tutorials with optional search and category filter
  Future<List<Tutorial>> getTutorials({
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (category != null && category.isNotEmpty && category != 'All') {
        queryParams['category'] = category;
      }

      final response = await _dio.get(
        '/api/tutorials/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => Tutorial.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load tutorials');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Fetch a single tutorial by ID
  Future<Tutorial> getTutorial(int id) async {
    try {
      final response = await _dio.get('/api/tutorials/$id/');

      if (response.statusCode == 200) {
        return Tutorial.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load tutorial');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Increment view count for a tutorial
  Future<void> incrementViews(int id) async {
    // try {
    await _dio.post('/api/tutorials/$id/increment_views/');
    // } on DioException catch (ie) {
    //   // Don't throw error for view count increment failure
    //  // print('Failed to increment views: ${e.message}');
    // }
  }

  /// Upload a new tutorial
  Future<Tutorial> uploadTutorial({
    required String title,
    required String description,
    required String category,
    required File videoFile,
    File? thumbnailFile,
    Function(int, int)? onProgress,
  }) async {
    try {
      // Create FormData for multipart upload
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'category': category,
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
        if (thumbnailFile != null)
          'thumbnail': await MultipartFile.fromFile(
            thumbnailFile.path,
            filename: thumbnailFile.path.split('/').last,
          ),
      });

      final response = await _dio.post(
        '/api/tutorials/',
        data: formData,
        onSendProgress: onProgress,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 201) {
        return Tutorial.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to upload tutorial');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get current user's tutorials
  Future<List<Tutorial>> getMyTutorials() async {
    try {
      final response = await _dio.get('/api/tutorials/my_tutorials/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => Tutorial.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load my tutorials');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete a tutorial
  Future<void> deleteTutorial(int id) async {
    try {
      final response = await _dio.delete('/api/tutorials/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete tutorial');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio errors
  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 401) {
        return 'Authentication failed. Please login again.';
      } else if (statusCode == 403) {
        return 'You do not have permission to perform this action.';
      } else if (statusCode == 404) {
        return 'Tutorial not found.';
      } else if (statusCode == 400) {
        // Try to extract error message from response
        if (data is Map<String, dynamic>) {
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            } else {
              errors.add(value.toString());
            }
          });
          return errors.isNotEmpty ? errors.join(', ') : 'Invalid request.';
        }
        return 'Invalid request.';
      } else if (statusCode! >= 500) {
        return 'Server error. Please try again later.';
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timeout. Please check your internet connection.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Connection error. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get list of available categories
  static List<String> getCategories() {
    return [
      'All',
      'Crops',
      'Livestock',
      'Irrigation',
      'Pest Control',
      'Soil Management',
      'Harvesting',
      'Post-Harvest',
      'Farm Equipment',
      'Marketing',
      'Other',
    ];
  }
}
