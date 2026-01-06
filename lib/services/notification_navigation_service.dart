import 'package:flutter/material.dart';

/// Service to handle notification-based navigation
/// Stores pending deep link payloads to be processed after splash screen
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  /// Pending manga URL to navigate to after app init
  String? _pendingMangaUrl;

  /// Global navigator key for navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Clean duplicate base URL from API response
  /// Converts: https://komiku.org/https://komiku.org/manga/xxx/
  /// To: https://komiku.org/manga/xxx/
  String cleanMangaUrl(String url) {
    // Check for duplicate komiku.org pattern
    const baseUrl = 'https://komiku.org/';
    if (url.startsWith(baseUrl)) {
      final afterBase = url.substring(baseUrl.length);
      if (afterBase.startsWith(baseUrl)) {
        // Remove the duplicate
        return afterBase;
      }
    }
    return url;
  }

  /// Set pending manga URL from notification tap
  void setPendingNavigation(String? mangaUrl) {
    if (mangaUrl != null && mangaUrl.isNotEmpty) {
      _pendingMangaUrl = cleanMangaUrl(mangaUrl);
      debugPrint('NotificationNavigation: Pending URL set - $_pendingMangaUrl');
    }
  }

  /// Check if there's a pending navigation
  bool get hasPendingNavigation => _pendingMangaUrl != null;

  /// Get and clear pending navigation
  String? consumePendingNavigation() {
    final url = _pendingMangaUrl;
    _pendingMangaUrl = null;
    return url;
  }

  /// Navigate to manga detail
  /// Returns true if navigation was successful
  Future<bool> navigateToMangaDetail(
    BuildContext context,
    String mangaUrl,
  ) async {
    try {
      debugPrint('NotificationNavigation: Navigating to - $mangaUrl');

      // Import detail screen lazily to avoid circular dependency
      // The mangaUrl format from API is like: https://komiku.org/https://komiku.org/manga/juujika-no-rokunin/
      // We need to navigate to DetailScreen with this URL

      final navigator = Navigator.of(context);

      // Dynamic import of detail screen
      await navigator.pushNamed('/detail', arguments: {'url': mangaUrl});

      return true;
    } catch (e) {
      debugPrint('NotificationNavigation: Error navigating - $e');
      return false;
    }
  }

  /// Process pending navigation if exists
  /// Call this after splash screen and auth check
  Future<void> processPendingNavigation(BuildContext context) async {
    final pendingUrl = consumePendingNavigation();
    if (pendingUrl != null) {
      debugPrint('NotificationNavigation: Processing pending - $pendingUrl');
      await navigateToMangaDetail(context, pendingUrl);
    }
  }
}
