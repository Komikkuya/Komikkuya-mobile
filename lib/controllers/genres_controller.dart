import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/manga_service.dart';

/// Controller for Genres screen
class GenresController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // Genres list state
  bool _isLoadingGenres = false;
  List<String> _genres = [];
  String? _genresError;

  // Selected genre manga state
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<Manga> _mangaList = [];
  int _currentPage = 1;
  bool _hasNextPage = true;

  // Filters
  String? _selectedGenre;
  String _category = 'manga';

  // Getters
  bool get isLoadingGenres => _isLoadingGenres;
  List<String> get genres => _genres;
  String? get genresError => _genresError;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<Manga> get mangaList => _mangaList;
  bool get hasNextPage => _hasNextPage;
  String? get selectedGenre => _selectedGenre;
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

  /// Format genre for display (capitalize, replace dashes)
  String formatGenre(String genre) {
    return genre
        .split('-')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  /// Initialize screen
  Future<void> initialize() async {
    if (_genres.isEmpty && !_isLoadingGenres) {
      await loadGenres();
    }
  }

  /// Load all genres
  Future<void> loadGenres() async {
    _isLoadingGenres = true;
    _genresError = null;
    notifyListeners();

    try {
      _genres = await _mangaService.fetchGenres();
      // Auto-select first genre if available
      if (_genres.isNotEmpty && _selectedGenre == null) {
        _selectedGenre = _genres.first;
        await loadMangaByGenre();
      }
    } catch (e) {
      _genresError = e.toString();
      debugPrint('GenresController.loadGenres error: $e');
    } finally {
      _isLoadingGenres = false;
      notifyListeners();
    }
  }

  /// Load manga by selected genre
  Future<void> loadMangaByGenre() async {
    if (_selectedGenre == null) return;

    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _mangaList = [];
    notifyListeners();

    try {
      final response = await _mangaService.fetchMangaByGenre(
        genre: _selectedGenre!,
        category: _category,
        page: _currentPage,
      );
      _mangaList = response.mangaList;
      _hasNextPage = response.hasNextPage || response.mangaList.length >= 10;
      debugPrint(
        'GenresController.loadMangaByGenre: genre=$_selectedGenre, page=$_currentPage, items=${response.mangaList.length}',
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('GenresController.loadMangaByGenre error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasNextPage || _selectedGenre == null) {
      debugPrint('GenresController.loadMore: skipped');
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      debugPrint('GenresController.loadMore: loading page $_currentPage');
      final response = await _mangaService.fetchMangaByGenre(
        genre: _selectedGenre!,
        category: _category,
        page: _currentPage,
      );
      _mangaList.addAll(response.mangaList);
      _hasNextPage = response.mangaList.isNotEmpty;
      debugPrint(
        'GenresController.loadMore: got ${response.mangaList.length} items',
      );
    } catch (e) {
      _currentPage--;
      _error = e.toString();
      debugPrint('GenresController.loadMore error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Select a genre
  Future<void> setGenre(String genre) async {
    if (_selectedGenre == genre) return;
    _selectedGenre = genre;
    await loadMangaByGenre();
  }

  /// Change category
  Future<void> setCategory(String category) async {
    if (_category == category) return;
    _category = category;
    if (_selectedGenre != null) {
      await loadMangaByGenre();
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    if (_selectedGenre != null) {
      await loadMangaByGenre();
    }
  }
}
