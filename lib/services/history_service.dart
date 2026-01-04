import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/auth_config.dart';
import '../models/history_model.dart';
import 'storage_service.dart';

/// Service for reading history API calls
class HistoryService {
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

  // ==================== GET HISTORY ====================

  /// Get reading history
  Future<List<HistoryItem>> getHistory({int limit = 50}) async {
    try {
      final response = await http
          .get(
            Uri.parse('${AuthConfig.readingHistoryUrl}?limit=$limit'),
            headers: _authHeaders(),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true && json['data'] != null) {
          final List<dynamic> data = json['data'] as List<dynamic>;
          return data
              .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      debugPrint('HistoryService.getHistory: Status ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('HistoryService.getHistory error: $e');
      return [];
    }
  }

  // ==================== ADD/UPDATE HISTORY ====================

  /// Add or update reading history
  Future<bool> saveHistory(HistoryItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse(AuthConfig.readingHistoryUrl),
            headers: _authHeaders(),
            body: jsonEncode(item.toJson()),
          )
          .timeout(_timeout);

      debugPrint('HistoryService.saveHistory: Status ${response.statusCode}');
      debugPrint('HistoryService.saveHistory: Body ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('HistoryService.saveHistory error: $e');
      return false;
    }
  }

  // ==================== UPDATE HISTORY ====================

  /// Update existing history entry
  Future<bool> updateHistory({
    required String url,
    String? chapterTitle,
    DateTime? time,
  }) async {
    try {
      final body = <String, dynamic>{'url': url};
      if (chapterTitle != null) body['chapterTitle'] = chapterTitle;
      if (time != null) body['time'] = time.toIso8601String();

      final response = await http
          .put(
            Uri.parse(AuthConfig.readingHistoryUrl),
            headers: _authHeaders(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      debugPrint('HistoryService.updateHistory: Status ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HistoryService.updateHistory error: $e');
      return false;
    }
  }

  // ==================== DELETE HISTORY ====================

  /// Delete single history entry
  Future<bool> deleteHistory(String url) async {
    try {
      final response = await http
          .delete(
            Uri.parse(AuthConfig.readingHistoryUrl),
            headers: _authHeaders(),
            body: jsonEncode({'url': url}),
          )
          .timeout(_timeout);

      debugPrint('HistoryService.deleteHistory: Status ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HistoryService.deleteHistory error: $e');
      return false;
    }
  }

  /// Clear all history
  Future<bool> clearAllHistory() async {
    try {
      final response = await http
          .delete(
            Uri.parse(AuthConfig.readingHistoryAllUrl),
            headers: _authHeaders(),
          )
          .timeout(_timeout);

      debugPrint(
        'HistoryService.clearAllHistory: Status ${response.statusCode}',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HistoryService.clearAllHistory error: $e');
      return false;
    }
  }
}
