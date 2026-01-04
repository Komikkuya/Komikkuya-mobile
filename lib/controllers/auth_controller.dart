import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Controller for authentication state management
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // State
  bool _isLoading = false;
  bool _isLoggedIn = false;
  User? _user;
  DiscordProfile? _discordProfile;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  DiscordProfile? get discordProfile => _discordProfile;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasDiscord => _discordProfile != null;

  /// Get display name (global name > username)
  String get displayName {
    if (_discordProfile?.globalName != null) {
      return _discordProfile!.globalName!;
    }
    return _user?.username ?? 'User';
  }

  /// Get avatar URL (discord > profile > null)
  String? get avatarUrl {
    if (_discordProfile?.avatar != null) {
      return _discordProfile!.avatar;
    }
    return _user?.profilePicture;
  }

  // ==================== INITIALIZE ====================

  /// Initialize auth - check stored token and validate
  Future<void> initialize() async {
    if (!StorageService.hasToken()) {
      debugPrint('AuthController: No token found');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Validate token with /auth/me
      final response = await _authService.getProfile();

      if (response.success && response.user != null) {
        _user = response.user;
        _discordProfile = response.discord;
        _isLoggedIn = true;
        debugPrint('AuthController: Token valid, user: ${_user?.username}');
      } else {
        // Token invalid, clear storage
        await logout();
        debugPrint('AuthController: Token invalid, logged out');
      }
    } catch (e) {
      debugPrint('AuthController.initialize error: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== LOGIN ====================

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.token != null && response.user != null) {
        // Save token and user
        await StorageService.saveToken(response.token!);
        await StorageService.saveUserData(response.user!.toJson());

        _user = response.user;
        _discordProfile = response.discord;
        _isLoggedIn = true;
        debugPrint('AuthController: Login successful');
        return true;
      } else {
        _error = response.message ?? 'Login failed';
        debugPrint('AuthController: Login failed - ${_error}');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthController.login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== REGISTER ====================

  /// Register new account
  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        email: email,
        username: username,
        password: password,
      );

      if (response.success && response.token != null && response.user != null) {
        // Save token and user
        await StorageService.saveToken(response.token!);
        await StorageService.saveUserData(response.user!.toJson());

        _user = response.user;
        _discordProfile = response.discord;
        _isLoggedIn = true;
        debugPrint('AuthController: Register successful');
        return true;
      } else {
        _error = response.message ?? 'Registration failed';
        debugPrint('AuthController: Register failed - ${_error}');
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthController.register error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== LOGOUT ====================

  /// Logout and clear all stored data
  Future<void> logout() async {
    await StorageService.clearAll();
    _user = null;
    _discordProfile = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
    debugPrint('AuthController: Logged out');
  }

  // ==================== REFRESH PROFILE ====================

  /// Refresh user profile from server
  Future<void> refreshProfile() async {
    if (!_isLoggedIn) return;

    try {
      final response = await _authService.getProfile();

      if (response.success && response.user != null) {
        _user = response.user;
        _discordProfile = response.discord;
        await StorageService.saveUserData(response.user!.toJson());
        notifyListeners();
      } else if (response.message == 'Unauthorized') {
        await logout();
      }
    } catch (e) {
      debugPrint('AuthController.refreshProfile error: $e');
    }
  }

  // ==================== UPDATE PROFILE ====================

  /// Update username
  Future<bool> updateProfile({required String username}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.updateProfile(username: username);

      if (response.success) {
        await refreshProfile();
        return true;
      } else {
        _error = response.message ?? 'Update failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthController.updateProfile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== UPLOAD PROFILE PICTURE ====================

  /// Upload new profile picture
  Future<bool> uploadProfilePicture(File image) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.uploadProfilePicture(image);

      if (result['image_url'] != null) {
        await refreshProfile();
        return true;
      } else {
        _error = result['message'] ?? 'Upload failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('AuthController.uploadProfilePicture error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
