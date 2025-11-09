import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class CommunityApiService {
  static const String baseUrl = 'http://192.168.100.7:5000';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Helper method to build complete image URL
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';

    // If URL already starts with http:// or https://, return as is
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    // Otherwise, prepend the baseUrl
    return '$baseUrl$imageUrl';
  }

  static Future<List<Post>> getPosts({String? search}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '$baseUrl/api/community/posts/',
    ).replace(queryParameters: search != null ? {'search': search} : null);

    print('Fetching posts from: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final decodedBody = json.decode(response.body);

      // Check if response is paginated (has 'results' key) or direct list
      List<dynamic> data;
      if (decodedBody is Map && decodedBody.containsKey('results')) {
        data = decodedBody['results'] as List<dynamic>;
      } else if (decodedBody is List) {
        data = decodedBody;
      } else {
        throw Exception(
          'Unexpected response format: ${decodedBody.runtimeType}',
        );
      }

      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load posts: ${response.statusCode} - ${response.body}',
      );
    }
  }

  static Future<Post> createPost({
    required String content,
    List<String>? tags,
    File? image,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/api/community/posts/');

    http.Response response;

    if (image != null) {
      // Use multipart request for image upload
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Token $token';

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      // Add text fields
      request.fields['content'] = content;
      request.fields['tags'] = json.encode(tags ?? []);

      final streamedResponse = await request.send();
      response = await http.Response.fromStream(streamedResponse);
    } else {
      // Use JSON request for text-only posts
      response = await http.post(
        uri,
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'content': content, 'tags': tags ?? []}),
      );
    }

    if (response.statusCode == 201) {
      return Post.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['content']?[0] ?? 'Failed to create post');
    }
  }

  static Future<void> toggleLike(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/like/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle like');
    }
  }

  static Future<void> deletePost(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/community/posts/$postId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }
}
