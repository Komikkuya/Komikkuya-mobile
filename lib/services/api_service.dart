import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Generic API service for HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Use a fresh client per request for mobile compatibility
  http.Client _createClient() => http.Client();

  /// Timeout duration for requests
  static const Duration _timeout = Duration(seconds: 30);

  /// GET request with JSON response
  Future<Map<String, dynamic>> get(String url) async {
    final client = _createClient();
    try {
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'Biji/1.0',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw ApiException(
          'Failed to load data',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException('No internet connection: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }

  /// GET request returning a list
  Future<List<dynamic>> getList(String url) async {
    final client = _createClient();
    try {
      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'User-Agent': 'KomikkuyaMobile/1.0',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        }
        return decoded as List<dynamic>;
      } else {
        throw ApiException(
          'Failed to load data',
          statusCode: response.statusCode,
        );
      }
    } on SocketException catch (e) {
      throw ApiException('No internet connection: ${e.message}');
    } on HttpException catch (e) {
      throw ApiException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      throw ApiException('Invalid response format: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    } finally {
      client.close();
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'ApiException: $message (Status: $statusCode)'
      : 'ApiException: $message';
}
