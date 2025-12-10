import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/post.dart';
import '../../models/comment.dart';

class CommunityApiService {
  static const String baseUrl = 'https://agriguide-backend-79j2.onrender.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
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

  // Get all posts with optional search
  static Future<List<Post>> getPosts({String? search}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse(
      '$baseUrl/api/community/posts/',
    ).replace(queryParameters: search != null ? {'search': search} : null);

    // print('Fetching posts from: $uri');

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');

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

  // Get a single post by ID
  static Future<Post> getPostById(String postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/api/community/posts/$postId/');

    // print('Fetching post from: $uri');

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    // print('Response status: ${response.statusCode}');
    // print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Post.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Post not found');
    } else if (response.statusCode == 401) {
      throw Exception('Not authenticated');
    } else {
      throw Exception(
        'Failed to load post: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Create a new post with optional image and tags
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
        headers: await _getHeaders(),
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

  // Toggle like on a post
  static Future<void> toggleLike(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/like/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to toggle like: ${response.body}');
    }
  }

  // Delete a post
  static Future<void> deletePost(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/community/posts/$postId/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  // Get comments for a post
  static Future<List<Comment>> getComments(int postId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/api/community/posts/$postId/comments/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  // Add a comment to a post
  static Future<Comment> addComment(int postId, String content) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/api/community/posts/$postId/comments/'),
      headers: await _getHeaders(),
      body: json.encode({'content': content}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Comment.fromJson(data);
    } else {
      throw Exception('Failed to add comment: ${response.body}');
    }
  }

  // Delete a comment
  static Future<void> deleteComment(int postId, int commentId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/community/posts/$postId/comments/$commentId/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.body}');
    }
  }
}