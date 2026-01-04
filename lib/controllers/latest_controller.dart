import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/manga_service.dart';

/// Controller for Latest screen
class LatestController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<Manga> _mangaList = [];
  int _currentPage = 1;
  bool _hasNextPage = true;

  // Filter
  String _category = 'manga';

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<Manga> get mangaList => _mangaList;
  bool get hasNextPage => _hasNextPage;
  String get category => _category;
  bool get hasError => _error != null;

  // Category options
  static const List<String> categories = ['manga', 'manhwa', 'manhua'];

  String getCategoryLabel(String cat) {
    switch (cat) {
      case 'manga':
        return 'Manga';
      case 'manhwa':
        return 'Manhwa';
      case 'manhua':
        return 'Manhua';
      default:
        return cat;
    }
  }

  /// Initialize and load data
  Future<void> initialize() async {
    if (_mangaList.isEmpty && !_isLoading) {
      await loadData();
    }
  }

  /// Load data with current category
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _mangaList = [];
    notifyListeners();

    try {
      final response = await _mangaService.fetchLatestManga(
        category: _category,
        page: _currentPage,
      );
      _mangaList = response.mangaList;
      // Assume more pages if we got items
      _hasNextPage = response.hasNextPage || response.mangaList.length >= 10;
      debugPrint(
        'LatestController.loadData: page=$_currentPage, items=${response.mangaList.length}, hasNextPage=$_hasNextPage',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('LatestController.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNextPage) {
      debugPrint(
        'LatestController.loadMore: skipped (isLoadingMore=$_isLoadingMore, hasNextPage=$_hasNextPage)',
      );
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      debugPrint('LatestController.loadMore: loading page $_currentPage');
      final response = await _mangaService.fetchLatestManga(
        category: _category,
        page: _currentPage,
      );
      _mangaList.addAll(response.mangaList);
      // Stop pagination if we got no new items
      _hasNextPage = response.mangaList.isNotEmpty;
      debugPrint(
        'LatestController.loadMore: got ${response.mangaList.length} items, total=${_mangaList.length}, hasNextPage=$_hasNextPage',
      );
    } catch (e) {
      _currentPage--; // Revert on error
      _error = e.toString();
      debugPrint('LatestController.loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Change category
  Future<void> setCategory(String category) async {
    if (_category == category) return;
    _category = category;
    await loadData();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadData();
  }
}
