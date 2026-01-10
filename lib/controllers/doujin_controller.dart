import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/doujin_model.dart';

/// Controller for doujin (hidden feature)
class DoujinController extends ChangeNotifier {
  List<DoujinItem> _items = [];
  DoujinDetail? _detail;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  List<DoujinItem> get items => _items;
  DoujinDetail? get detail => _detail;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Fetch doujin list (first page)
  Future<void> fetchList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _items = [];
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = ApiConfig.doujinLastUpdateUrl(page: _currentPage);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'] as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>?;

          if (results != null) {
            final newItems = results
                .map((e) => DoujinItem.fromJson(e as Map<String, dynamic>))
                .toList();

            _items = newItems;
            _hasMore = newItems.length >= 12; // API returns 12 per page
            _currentPage = 1;
          }
        }
      } else {
        _error = 'Failed to load: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('DoujinController: fetchList error - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more items (next page)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final url = ApiConfig.doujinLastUpdateUrl(page: nextPage);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'] as Map<String, dynamic>;
          final results = data['results'] as List<dynamic>?;

          if (results != null && results.isNotEmpty) {
            final newItems = results
                .map((e) => DoujinItem.fromJson(e as Map<String, dynamic>))
                .toList();

            _items.addAll(newItems);
            _currentPage = nextPage;
            _hasMore = newItems.length >= 12;
          } else {
            _hasMore = false;
          }
        }
      }
    } catch (e) {
      debugPrint('DoujinController: loadMore error - $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch doujin detail
  Future<void> fetchDetail(String url) async {
    _isLoading = true;
    _detail = null;
    _error = null;
    notifyListeners();

    try {
      final apiUrl = ApiConfig.doujinDetailUrl(url);
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          _detail = DoujinDetail.fromJson(json['data'] as Map<String, dynamic>);
        } else {
          _error = 'Invalid response';
        }
      } else {
        _error = 'Failed to load: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
      debugPrint('DoujinController: fetchDetail error - $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear detail
  void clearDetail() {
    _detail = null;
    notifyListeners();
  }
}
