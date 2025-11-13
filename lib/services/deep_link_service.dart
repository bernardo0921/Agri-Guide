import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Stream controller for deep link events
  final _deepLinkController = StreamController<Uri>.broadcast();
  Stream<Uri> get deepLinkStream => _deepLinkController.stream;

  /// Initialize deep link handling
  Future<void> initialize() async {
    // Handle initial deep link (when app is opened via link from terminated state)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('📱 Initial deep link detected: $initialLink');
        _deepLinkController.add(initialLink);
      }
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }

    // Listen for deep links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        print('📱 Deep link received (warm start): $uri');
        _deepLinkController.add(uri);
      },
      onError: (err) {
        print('❌ Deep link error: $err');
      },
    );
  }

  /// Parse post ID from deep link URI
  /// Expected format: https://my-app-domain.com/post/123
  String? parsePostId(Uri uri) {
    try {
      // Check if the path matches our expected format
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'post') {
        final postId = uri.pathSegments[1];
        print('✅ Parsed post ID: $postId');
        return postId;
      }
    } catch (e) {
      print('❌ Error parsing post ID: $e');
    }
    return null;
  }

  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkController.close();
  }
}