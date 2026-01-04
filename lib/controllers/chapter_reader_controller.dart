import 'package:flutter/material.dart';
import '../models/chapter_content_model.dart';
import '../services/manga_service.dart';

/// Controller for chapter reader state management
class ChapterReaderController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // State
  bool _isLoading = true;
  String? _error;
  ChapterContent? _chapterContent;

  // UI state
  bool _isControlsVisible = true;
  double _scrollProgress = 0.0;
  int _currentImageIndex = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  ChapterContent? get chapterContent => _chapterContent;
  bool get isControlsVisible => _isControlsVisible;
  double get scrollProgress => _scrollProgress;
  int get currentImageIndex => _currentImageIndex;

  /// Load chapter content
  Future<void> loadChapter(String chapterUrl) async {
    _isLoading = true;
    _error = null;
    _scrollProgress = 0.0;
    _currentImageIndex = 0;
    notifyListeners();

    try {
      _chapterContent = await _mangaService.fetchChapter(chapterUrl);
      debugPrint('✅ Loaded chapter: ${_chapterContent?.title}');
      debugPrint('   Images: ${_chapterContent?.totalImages}');
    } catch (e) {
      debugPrint('❌ Error loading chapter: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle controls visibility
  void toggleControls() {
    _isControlsVisible = !_isControlsVisible;
    notifyListeners();
  }

  /// Show controls
  void showControls() {
    if (!_isControlsVisible) {
      _isControlsVisible = true;
      notifyListeners();
    }
  }

  /// Hide controls
  void hideControls() {
    if (_isControlsVisible) {
      _isControlsVisible = false;
      notifyListeners();
    }
  }

  /// Update scroll progress
  void updateScrollProgress(double progress) {
    _scrollProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Update current image index
  void updateCurrentImageIndex(int index) {
    if (index != _currentImageIndex) {
      _currentImageIndex = index;
      notifyListeners();
    }
  }

  /// Check if has previous chapter
  bool get hasPrevChapter => _chapterContent?.navigation.hasPrev ?? false;

  /// Check if has next chapter
  bool get hasNextChapter => _chapterContent?.navigation.hasNext ?? false;

  /// Get previous chapter URL
  String? get prevChapterUrl => _chapterContent?.navigation.prev?.url;

  /// Get next chapter URL
  String? get nextChapterUrl => _chapterContent?.navigation.next?.url;

  /// Get manga detail URL
  String? get mangaDetailUrl => _chapterContent?.navigation.chapterListUrl;

  /// Clear state
  void clear() {
    _isLoading = true;
    _error = null;
    _chapterContent = null;
    _isControlsVisible = true;
    _scrollProgress = 0.0;
    _currentImageIndex = 0;
    notifyListeners();
  }
}
