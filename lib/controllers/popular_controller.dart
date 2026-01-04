import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/manga_service.dart';

/// Sort time options for Popular screen
enum PopularSortTime {
  daily,
  weekly,
  all;

  String get value {
    switch (this) {
      case PopularSortTime.daily:
        return 'daily';
      case PopularSortTime.weekly:
        return 'weekly';
      case PopularSortTime.all:
        return 'all';
    }
  }

  String get label {
    switch (this) {
      case PopularSortTime.daily:
        return 'Today';
      case PopularSortTime.weekly:
        return 'This Week';
      case PopularSortTime.all:
        return 'All Time';
    }
  }

  IconData get icon {
    switch (this) {
      case PopularSortTime.daily:
        return Icons.local_fire_department;
      case PopularSortTime.weekly:
        return Icons.calendar_view_week;
      case PopularSortTime.all:
        return Icons.star;
    }
  }
}

/// Category options
enum MangaCategory {
  manga,
  manhwa,
  manhua;

  String get value {
    switch (this) {
      case MangaCategory.manga:
        return 'manga';
      case MangaCategory.manhwa:
        return 'manhwa';
      case MangaCategory.manhua:
        return 'manhua';
    }
  }

  String get label {
    switch (this) {
      case MangaCategory.manga:
        return 'Manga';
      case MangaCategory.manhwa:
        return 'Manhwa';
      case MangaCategory.manhua:
        return 'Manhua';
    }
  }
}

/// Controller for Popular screen
class PopularController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // State
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<Manga> _mangaList = [];
  int _currentPage = 1;
  bool _hasNextPage = true;

  // Filters
  PopularSortTime _sortTime = PopularSortTime.daily;
  MangaCategory _category = MangaCategory.manga;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<Manga> get mangaList => _mangaList;
  bool get hasNextPage => _hasNextPage;
  PopularSortTime get sortTime => _sortTime;
  MangaCategory get category => _category;
  bool get hasError => _error != null;

  /// Initialize and load data
  Future<void> initialize() async {
    if (_mangaList.isEmpty && !_isLoading) {
      await loadData();
    }
  }

  /// Load data with current filters
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _mangaList = [];
    notifyListeners();

    try {
      final response = await _mangaService.fetchPopularManga(
        category: _category.value,
        sortTime: _sortTime.value,
        page: _currentPage,
      );
      _mangaList = response.mangaList;
      // Assume more pages if we got items (API may not return hasNextPage correctly)
      _hasNextPage = response.hasNextPage || response.mangaList.length >= 10;
      debugPrint(
        'PopularController.loadData: page=$_currentPage, items=${response.mangaList.length}, hasNextPage=$_hasNextPage',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('PopularController.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNextPage) {
      debugPrint(
        'PopularController.loadMore: skipped (isLoadingMore=$_isLoadingMore, hasNextPage=$_hasNextPage)',
      );
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      debugPrint('PopularController.loadMore: loading page $_currentPage');
      final response = await _mangaService.fetchPopularManga(
        category: _category.value,
        sortTime: _sortTime.value,
        page: _currentPage,
      );
      _mangaList.addAll(response.mangaList);
      // Stop pagination if we got no new items
      _hasNextPage = response.mangaList.isNotEmpty;
      debugPrint(
        'PopularController.loadMore: got ${response.mangaList.length} items, total=${_mangaList.length}, hasNextPage=$_hasNextPage',
      );
    } catch (e) {
      _currentPage--; // Revert on error
      _error = e.toString();
      debugPrint('PopularController.loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Change sort time filter
  Future<void> setSortTime(PopularSortTime sortTime) async {
    if (_sortTime == sortTime) return;
    _sortTime = sortTime;
    await loadData();
  }

  /// Change category filter
  Future<void> setCategory(MangaCategory category) async {
    if (_category == category) return;
    _category = category;
    await loadData();
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadData();
  }
}
