import 'package:flutter/foundation.dart';
import 'package:lms_platform/core/routing/app_router.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  String? _pendingDeepLink;
  String? _initialDeepLink;
  bool _initialLinkProcessed = false;

  /// Get pending deep link (for after login)
  String? get pendingDeepLink => _pendingDeepLink;

  /// Check if there's an initial deep link waiting to be processed
  bool get hasInitialDeepLink =>
      _initialDeepLink != null && !_initialLinkProcessed;

  /// Clear pending deep link
  void clearPendingDeepLink() {
    _pendingDeepLink = null;
  }

  /// Save initial deep link to process after splash screen
  void saveInitialDeepLink(Uri uri) {
    if (!_initialLinkProcessed) {
      final path = _uriToPath(uri);
      if (path != null && path != '/home') {
        _initialDeepLink = path;
        debugPrint('Deep Link: Saved initial link for later: $path');
      }
    }
  }

  /// Process initial deep link after splash screen navigation
  void processInitialDeepLink() {
    if (_initialDeepLink != null && !_initialLinkProcessed) {
      _initialLinkProcessed = true;
      final path = _initialDeepLink!;
      _initialDeepLink = null;
      debugPrint('Deep Link: Processing initial link: $path');
      // Use push to add on top of home screen
      AppRouter.router.push(path);
    }
  }

  /// Handle incoming deep link URI (for links while app is running)
  void handleDeepLink(Uri uri) {
    debugPrint('Deep Link received: $uri');

    final path = _uriToPath(uri);
    if (path != null) {
      _navigateToPath(path);
    }
  }

  /// Convert URI to app path
  String? _uriToPath(Uri uri) {
    debugPrint('Deep Link parsing URI: $uri');
    debugPrint('  - scheme: ${uri.scheme}');
    debugPrint('  - host: ${uri.host}');
    debugPrint('  - path: ${uri.path}');
    debugPrint('  - pathSegments: ${uri.pathSegments}');
    debugPrint('  - queryParameters: ${uri.queryParameters}');

    List<String> segments = uri.pathSegments;

    // Always check query parameters first (for ?id= format)
    final queryId = uri.queryParameters['id'];

    if (segments.isEmpty) {
      // No path segments, check if we have query params in the full path
      if (queryId != null && queryId.isNotEmpty) {
        // Determine type from path
        if (uri.path.contains('product')) {
          return '/product/$queryId';
        } else if (uri.path.contains('store')) {
          return '/store/$queryId';
        }
      }
      return '/home';
    }

    switch (segments.first) {
      case 'product':
        // Handle /product/123 format
        if (segments.length > 1) {
          return '/product/${segments[1]}';
        }
        // Handle /product?id=123 format
        if (queryId != null && queryId.isNotEmpty) {
          return '/product/$queryId';
        }
        debugPrint('Product link missing ID, redirecting to home');
        return '/home';

      case 'store':
        // Handle /store/456 or /store?id=456
        if (segments.length > 1) {
          final name = uri.queryParameters['name'];
          return '/store/${segments[1]}${name != null ? '?name=$name' : ''}';
        }
        // Check query parameter
        final storeId = uri.queryParameters['id'];
        if (storeId != null) {
          final name = uri.queryParameters['name'];
          return '/store/$storeId${name != null ? '?name=$name' : ''}';
        }
        return '/home';

      case 'category':
        if (segments.length > 1) {
          return '/home';
        }
        return '/home';

      case 'cart':
        return '/cart';

      case 'orders':
        return '/orders';

      case 'favorites':
        return '/favorites';

      default:
        // Handle short paths like /p123 for products, /s456 for stores
        final firstSegment = segments.first;
        if (firstSegment.startsWith('p') && firstSegment.length > 1) {
          final productId = firstSegment.substring(1);
          return '/product/$productId';
        }
        if (firstSegment.startsWith('s') && firstSegment.length > 1) {
          final storeId = firstSegment.substring(1);
          return '/store/$storeId';
        }
        return '/home';
    }
  }

  /// Navigate to path using go (replaces current route)
  void _navigateToPath(String path) {
    try {
      // Use push to add on top of current screen
      // This way back button returns to previous screen
      AppRouter.router.push(path);
    } catch (e) {
      debugPrint('Deep Link navigation error: $e');
      // Save for later if navigation fails (e.g., not logged in)
      _pendingDeepLink = path;
    }
  }

  /// Navigate to pending deep link (call after login)
  void navigateToPendingDeepLink() {
    if (_pendingDeepLink != null) {
      final path = _pendingDeepLink!;
      _pendingDeepLink = null;
      // Use push to add on top of home
      AppRouter.router.push(path);
    }
  }

  /// Check if there's a pending deep link
  bool get hasPendingDeepLink => _pendingDeepLink != null;

  /// Save deep link for after authentication
  void savePendingDeepLink(String path) {
    _pendingDeepLink = path;
  }
}
