import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/auth_config.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Service for authentication API calls
class AuthService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Get headers with JWT token
  static Map<String, String> _authHeaders() {
    final token = StorageService.getToken();
    return {
      ..._jsonHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== REGISTER ====================

  /// Register new user
  Future<AuthResponse> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AuthConfig.registerUrl),
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': email,
              'username': username,
              'password': password,
            }),
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } catch (e) {
      debugPrint('AuthService.register error: $e');
      return AuthResponse(success: false, message: e.toString());
    }
  }

  // ==================== LOGIN ====================

  /// Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(AuthConfig.loginUrl),
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } catch (e) {
      debugPrint('AuthService.login error: $e');
      return AuthResponse(success: false, message: e.toString());
    }
  }

  // ==================== GET PROFILE ====================

  /// Get current user profile (protected)
  Future<AuthResponse> getProfile() async {
    try {
      final response = await http
          .get(Uri.parse(AuthConfig.meUrl), headers: _authHeaders())
          .timeout(_timeout);

      if (response.statusCode == 401) {
        return AuthResponse(success: false, message: 'Unauthorized');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } catch (e) {
      debugPrint('AuthService.getProfile error: $e');
      return AuthResponse(success: false, message: e.toString());
    }
  }

  // ==================== UPDATE PROFILE ====================

  /// Update user profile (protected)
  Future<AuthResponse> updateProfile({required String username}) async {
    try {
      final response = await http
          .put(
            Uri.parse(AuthConfig.profileUrl),
            headers: _authHeaders(),
            body: jsonEncode({'username': username}),
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthResponse.fromJson(json);
    } catch (e) {
      debugPrint('AuthService.updateProfile error: $e');
      return AuthResponse(success: false, message: e.toString());
    }
  }

  // ==================== UPLOAD PROFILE PICTURE ====================

  /// Upload profile picture (protected)
  Future<Map<String, dynamic>> uploadProfilePicture(File image) async {
    try {
      final token = StorageService.getToken();
      debugPrint('AuthService.uploadProfilePicture: Starting upload...');
      debugPrint('AuthService.uploadProfilePicture: File path: ${image.path}');
      debugPrint(
        'AuthService.uploadProfilePicture: Token exists: ${token != null}',
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AuthConfig.profilePictureUrl),
      );

      // Only add Authorization header for multipart (not Content-Type)
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add the image file with explicit content type
      final extension = image.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg'; // default
      if (extension == 'png') {
        mimeType = 'image/png';
      } else if (extension == 'gif') {
        mimeType = 'image/gif';
      } else if (extension == 'webp') {
        mimeType = 'image/webp';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        mimeType = 'image/jpeg';
      }
      debugPrint(
        'AuthService.uploadProfilePicture: Extension: $extension, MimeType: $mimeType',
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      debugPrint('AuthService.uploadProfilePicture: Sending request...');
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'AuthService.uploadProfilePicture: Status: ${response.statusCode}',
      );
      debugPrint('AuthService.uploadProfilePicture: Body: ${response.body}');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('AuthService.uploadProfilePicture error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
