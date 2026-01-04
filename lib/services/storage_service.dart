import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for storing auth data in SharedPreferences
class StorageService {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // ==================== TOKEN ====================

  /// Save JWT token
  static Future<bool> saveToken(String token) async {
    return prefs.setString(_tokenKey, token);
  }

  /// Get JWT token
  static String? getToken() {
    return prefs.getString(_tokenKey);
  }

  /// Check if token exists
  static bool hasToken() {
    return prefs.containsKey(_tokenKey) && getToken()?.isNotEmpty == true;
  }

  /// Delete JWT token
  static Future<bool> deleteToken() async {
    return prefs.remove(_tokenKey);
  }

  // ==================== USER DATA ====================

  /// Save user data as JSON
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    return prefs.setString(_userKey, jsonEncode(userData));
  }

  /// Get user data
  static Map<String, dynamic>? getUserData() {
    final data = prefs.getString(_userKey);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Delete user data
  static Future<bool> deleteUserData() async {
    return prefs.remove(_userKey);
  }

  // ==================== CLEAR ALL ====================

  /// Clear all auth data (logout)
  static Future<void> clearAll() async {
    await deleteToken();
    await deleteUserData();
  }
}
