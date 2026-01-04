import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/auth_config.dart';
import '../models/favorite_model.dart';
import 'storage_service.dart';

/// Service for favorites API calls
class FavoritesService {
  static const Duration _timeout = Duration(seconds: 15);

  /// Get auth headers
  static Map<String, String> _authHeaders() {
    final token = StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== GET ALL FAVORITES ====================

  /// Get all favorites
  Future<List<FavoriteItem>> getFavorites() async {
    try {
      final response = await http
          .get(Uri.parse(AuthConfig.favoritesUrl), headers: _authHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final List<dynamic> data = json['data'] as List<dynamic>;
          return data
              .map(
                (item) => FavoriteItem.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('FavoritesService.getFavorites error: $e');
      return [];
    }
  }

  // ==================== ADD FAVORITE ====================

  /// Add to favorites
  Future<bool> addFavorite(FavoriteItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse(AuthConfig.favoritesUrl),
            headers: _authHeaders(),
            body: jsonEncode(item.toJson()),
          )
          .timeout(_timeout);

      debugPrint('FavoritesService.addFavorite: Status ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('FavoritesService.addFavorite error: $e');
      return false;
    }
  }

  // ==================== REMOVE FAVORITE ====================

  /// Remove from favorites
  Future<bool> removeFavorite(String id) async {
    try {
      // URL-encode the ID to handle slashes and special characters
      final encodedId = Uri.encodeComponent(id);
      final url = '${AuthConfig.favoritesUrl}/$encodedId';

      debugPrint('FavoritesService.removeFavorite: URL = $url');

      final response = await http
          .delete(Uri.parse(url), headers: _authHeaders())
          .timeout(_timeout);

      debugPrint(
        'FavoritesService.removeFavorite: Status ${response.statusCode}',
      );
      debugPrint('FavoritesService.removeFavorite: Body ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('FavoritesService.removeFavorite error: $e');
      return false;
    }
  }

  // ==================== CHECK IF FAVORITED ====================

  /// Check if item is in favorites
  Future<bool> isFavorite(String id) async {
    try {
      // URL-encode the ID to handle slashes and special characters
      final encodedId = Uri.encodeComponent(id);
      final url = '${AuthConfig.favoritesUrl}/check/$encodedId';

      final response = await http
          .get(Uri.parse(url), headers: _authHeaders())
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['data']?['isFavorite'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('FavoritesService.isFavorite error: $e');
      return false;
    }
  }
}
