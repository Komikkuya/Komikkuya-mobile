import 'package:flutter/foundation.dart';
import '../models/favorite_model.dart';
import '../services/favorites_service.dart';

/// Controller for favorites state management
class FavoritesController extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();

  // State
  bool _isLoading = false;
  List<FavoriteItem> _favorites = [];
  String? _error;

  // Cache for quick lookup
  final Set<String> _favoriteIds = {};

  // Getters
  bool get isLoading => _isLoading;
  List<FavoriteItem> get favorites => _favorites;
  String? get error => _error;
  bool get hasError => _error != null;
  int get count => _favorites.length;

  /// Extract slug from full URL
  /// e.g., "https://komiku.org/manga/one-piece/" -> "one-piece"
  static String extractSlug(String urlOrSlug) {
    // If already a slug (no slashes except trailing), return as-is
    if (!urlOrSlug.contains('://')) {
      return urlOrSlug.replaceAll(RegExp(r'^/|/$'), '');
    }
    // Extract last path segment
    final uri = Uri.tryParse(urlOrSlug);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      // Get last non-empty segment
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }
    // Fallback: remove trailing slash and get everything after last /
    final cleaned = urlOrSlug.replaceAll(RegExp(r'/$'), '');
    final lastSlash = cleaned.lastIndexOf('/');
    if (lastSlash >= 0) {
      return cleaned.substring(lastSlash + 1);
    }
    return urlOrSlug;
  }

  /// Check if item is favorited (from cache) - supports both URL and slug
  bool isFavorited(String idOrUrl) {
    final slug = extractSlug(idOrUrl);
    return _favoriteIds.contains(slug) || _favoriteIds.contains(idOrUrl);
  }

  // ==================== LOAD FAVORITES ====================

  /// Load all favorites from server
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _favorites = await _service.getFavorites();
      _favoriteIds.clear();
      for (final item in _favorites) {
        _favoriteIds.add(item.id);
      }
      debugPrint('FavoritesController: Loaded ${_favorites.length} favorites');
    } catch (e) {
      _error = e.toString();
      debugPrint('FavoritesController.loadFavorites error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== ADD FAVORITE ====================

  /// Add item to favorites
  /// id and slug will be extracted to just the slug portion
  /// url is kept as-is for navigation purposes
  Future<bool> addFavorite({
    required String id,
    required String slug,
    required String title,
    String? url, // Full URL for navigation
    String? cover,
    String? type,
    String? source,
  }) async {
    // Extract slug from URL if needed
    final cleanId = extractSlug(id);
    final cleanSlug = extractSlug(slug);

    // Already favorited
    if (_favoriteIds.contains(cleanId)) return true;

    final item = FavoriteItem(
      id: cleanId,
      slug: cleanSlug,
      title: title,
      url: url ?? id, // Keep original URL for navigation
      cover: cover,
      type: type,
      source: source,
    );

    // Optimistic update
    _favoriteIds.add(cleanId);
    _favorites.insert(0, item);
    notifyListeners();

    final success = await _service.addFavorite(item);

    if (!success) {
      // Rollback
      _favoriteIds.remove(cleanId);
      _favorites.removeWhere((f) => f.id == cleanId);
      notifyListeners();
    }

    debugPrint('FavoritesController.addFavorite: $cleanId -> $success');
    return success;
  }

  // ==================== REMOVE FAVORITE ====================

  /// Remove item from favorites
  Future<bool> removeFavorite(String id) async {
    // Extract slug from URL if needed
    final cleanId = extractSlug(id);

    if (!_favoriteIds.contains(cleanId)) return true;

    // Store for rollback
    final item = _favorites.firstWhere(
      (f) => f.id == cleanId,
      orElse: () => FavoriteItem(id: cleanId, slug: '', title: ''),
    );
    final index = _favorites.indexWhere((f) => f.id == cleanId);

    // Optimistic update
    _favoriteIds.remove(cleanId);
    _favorites.removeWhere((f) => f.id == cleanId);
    notifyListeners();

    final success = await _service.removeFavorite(cleanId);

    if (!success) {
      // Rollback
      _favoriteIds.add(cleanId);
      if (index >= 0) {
        _favorites.insert(index, item);
      } else {
        _favorites.add(item);
      }
      notifyListeners();
    }

    debugPrint('FavoritesController.removeFavorite: $cleanId -> $success');
    return success;
  }

  // ==================== TOGGLE FAVORITE ====================

  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String id,
    required String slug,
    required String title,
    String? url,
    String? cover,
    String? type,
    String? source,
  }) async {
    if (isFavorited(id)) {
      return removeFavorite(id);
    } else {
      return addFavorite(
        id: id,
        slug: slug,
        title: title,
        url: url,
        cover: cover,
        type: type,
        source: source,
      );
    }
  }

  // ==================== CHECK FROM SERVER ====================

  /// Check if favorited from server (updates cache)
  Future<bool> checkFavorite(String id) async {
    final isFav = await _service.isFavorite(id);
    if (isFav && !_favoriteIds.contains(id)) {
      _favoriteIds.add(id);
      notifyListeners();
    } else if (!isFav && _favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      notifyListeners();
    }
    return isFav;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all (on logout)
  void clear() {
    _favorites.clear();
    _favoriteIds.clear();
    _error = null;
    notifyListeners();
  }
}
