import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../models/custom_manga_model.dart';
import '../services/manga_service.dart';

/// Home page state management controller
class HomeController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // Loading states
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  // Individual loading states for graceful degradation
  bool _isLoadingCustom = true;
  bool _isLoadingGenres = true;
  bool _isLoadingHot = true;
  bool _isLoadingLatest = true;
  bool _isLoadingPopular = true;

  // Data holders
  List<CustomManga> _customManga = [];
  List<String> _genres = [];
  List<Manga> _hotManga = [];
  List<Manga> _latestManga = [];
  List<Manga> _latestManhwa = [];
  List<Manga> _latestManhua = [];
  List<Manga> _popularDaily = [];
  List<Manga> _popularWeekly = [];
  List<Manga> _popularAllTime = [];

  // Getters
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  bool get hasError =>
      _error != null && _customManga.isEmpty && _hotManga.isEmpty;

  bool get isLoadingCustom => _isLoadingCustom;
  bool get isLoadingGenres => _isLoadingGenres;
  bool get isLoadingHot => _isLoadingHot;
  bool get isLoadingLatest => _isLoadingLatest;
  bool get isLoadingPopular => _isLoadingPopular;

  List<CustomManga> get customManga => _customManga;
  List<String> get genres => _genres;
  List<Manga> get hotManga => _hotManga;
  List<Manga> get latestManga => _latestManga;
  List<Manga> get latestManhwa => _latestManhwa;
  List<Manga> get latestManhua => _latestManhua;
  List<Manga> get popularDaily => _popularDaily;
  List<Manga> get popularWeekly => _popularWeekly;
  List<Manga> get popularAllTime => _popularAllTime;

  /// Initialize and load all data
  Future<void> initialize() async {
    if (_customManga.isNotEmpty || _hotManga.isNotEmpty)
      return; // Already loaded
    await loadAllData();
  }

  /// Load all homepage data - each section loads independently for graceful degradation
  Future<void> loadAllData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Load all sections in parallel, but handle errors independently
    await Future.wait([
      _loadCustomManga(),
      _loadGenres(),
      _loadHotManga(),
      _loadLatestManga(),
      _loadLatestManhwa(),
      _loadLatestManhua(),
      _loadPopularDaily(),
      _loadPopularWeekly(),
      _loadPopularAllTime(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCustomManga() async {
    _isLoadingCustom = true;
    try {
      _customManga = await _mangaService.fetchCustomManga();
      debugPrint('✅ Loaded ${_customManga.length} custom manga');
    } catch (e) {
      debugPrint('❌ Error loading custom manga: $e');
      _error = e.toString();
    }
    _isLoadingCustom = false;
    notifyListeners();
  }

  Future<void> _loadGenres() async {
    _isLoadingGenres = true;
    try {
      _genres = await _mangaService.fetchGenres();
      debugPrint('✅ Loaded ${_genres.length} genres');
    } catch (e) {
      debugPrint('❌ Error loading genres: $e');
    }
    _isLoadingGenres = false;
    notifyListeners();
  }

  Future<void> _loadHotManga() async {
    _isLoadingHot = true;
    try {
      final response = await _mangaService.fetchHotManga();
      _hotManga = response.mangaList;
      debugPrint('✅ Loaded ${_hotManga.length} hot manga');
    } catch (e) {
      debugPrint('❌ Error loading hot manga: $e');
      _error = e.toString();
    }
    _isLoadingHot = false;
    notifyListeners();
  }

  Future<void> _loadLatestManga() async {
    _isLoadingLatest = true;
    try {
      final response = await _mangaService.fetchLatestManga(category: 'manga');
      _latestManga = response.mangaList;
      debugPrint('✅ Loaded ${_latestManga.length} latest manga');
    } catch (e) {
      debugPrint('❌ Error loading latest manga: $e');
    }
    _isLoadingLatest = false;
    notifyListeners();
  }

  Future<void> _loadLatestManhwa() async {
    try {
      final response = await _mangaService.fetchLatestManga(category: 'manhwa');
      _latestManhwa = response.mangaList;
      debugPrint('✅ Loaded ${_latestManhwa.length} latest manhwa');
    } catch (e) {
      debugPrint('❌ Error loading latest manhwa: $e');
    }
    notifyListeners();
  }

  Future<void> _loadLatestManhua() async {
    try {
      final response = await _mangaService.fetchLatestManga(category: 'manhua');
      _latestManhua = response.mangaList;
      debugPrint('✅ Loaded ${_latestManhua.length} latest manhua');
    } catch (e) {
      debugPrint('❌ Error loading latest manhua: $e');
    }
    notifyListeners();
  }

  Future<void> _loadPopularDaily() async {
    _isLoadingPopular = true;
    try {
      final response = await _mangaService.fetchPopularManga(sortTime: 'daily');
      _popularDaily = response.mangaList;
      debugPrint('✅ Loaded ${_popularDaily.length} popular daily');
    } catch (e) {
      debugPrint('❌ Error loading popular daily: $e');
    }
    _isLoadingPopular = false;
    notifyListeners();
  }

  Future<void> _loadPopularWeekly() async {
    try {
      final response = await _mangaService.fetchPopularManga(
        sortTime: 'weekly',
      );
      _popularWeekly = response.mangaList;
      debugPrint('✅ Loaded ${_popularWeekly.length} popular weekly');
    } catch (e) {
      debugPrint('❌ Error loading popular weekly: $e');
    }
    notifyListeners();
  }

  Future<void> _loadPopularAllTime() async {
    try {
      final response = await _mangaService.fetchPopularManga(sortTime: 'all');
      _popularAllTime = response.mangaList;
      debugPrint('✅ Loaded ${_popularAllTime.length} popular all time');
    } catch (e) {
      debugPrint('❌ Error loading popular all time: $e');
    }
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isRefreshing = true;
    _error = null;
    notifyListeners();

    // Clear existing data
    _customManga = [];
    _genres = [];
    _hotManga = [];
    _latestManga = [];
    _latestManhwa = [];
    _latestManhua = [];
    _popularDaily = [];
    _popularWeekly = [];
    _popularAllTime = [];

    await loadAllData();

    _isRefreshing = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
