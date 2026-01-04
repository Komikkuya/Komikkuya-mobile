import 'package:flutter/material.dart';
import '../models/search_result_model.dart';
import '../models/source_type.dart';
import '../services/manga_service.dart';

/// Controller for search functionality
class SearchController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  bool _isLoading = false;
  String? _error;
  List<SearchResult> _results = [];
  String _query = '';
  MangaSource? _filterSource;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SearchResult> get results => _filterSource == null
      ? _results
      : _results.where((r) => r.source == _filterSource).toList();
  String get query => _query;
  MangaSource? get filterSource => _filterSource;
  bool get hasResults => _results.isNotEmpty;

  /// Get results count by source
  int getCountBySource(MangaSource source) =>
      _results.where((r) => r.source == source).length;

  /// Set source filter
  void setFilter(MangaSource? source) {
    _filterSource = source;
    notifyListeners();
  }

  /// Search all sources
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _results = [];
      _query = '';
      _error = null;
      notifyListeners();
      return;
    }

    _query = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _results = await _mangaService.searchAll(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search
  void clear() {
    _results = [];
    _query = '';
    _error = null;
    _filterSource = null;
    _isLoading = false;
    notifyListeners();
  }
}
