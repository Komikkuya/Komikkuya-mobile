import 'package:flutter/material.dart';
import '../models/manga_detail_model.dart';
import '../services/manga_service.dart';

/// Controller for manga detail page state management
class MangaDetailController extends ChangeNotifier {
  final MangaService _mangaService = MangaService();

  // State
  bool _isLoading = true;
  String? _error;
  MangaDetail? _mangaDetail;
  bool _isDescriptionExpanded = false;
  bool _isChapterListReversed = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  MangaDetail? get mangaDetail => _mangaDetail;
  bool get isDescriptionExpanded => _isDescriptionExpanded;
  bool get isChapterListReversed => _isChapterListReversed;

  /// Get chapters in the correct order based on sort preference
  List<ChapterItem> get sortedChapters {
    if (_mangaDetail == null) return [];
    if (_isChapterListReversed) {
      return _mangaDetail!.chapters.reversed.toList();
    }
    return _mangaDetail!.chapters;
  }

  /// Load manga detail
  Future<void> loadMangaDetail(String mangaUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mangaDetail = await _mangaService.fetchMangaDetail(mangaUrl);
      debugPrint('✅ Loaded manga: ${_mangaDetail?.title}');
      debugPrint('   Chapters: ${_mangaDetail?.totalChapters}');
    } catch (e) {
      debugPrint('❌ Error loading manga detail: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle description expansion
  void toggleDescription() {
    _isDescriptionExpanded = !_isDescriptionExpanded;
    notifyListeners();
  }

  /// Toggle chapter list order (newest first / oldest first)
  void toggleChapterOrder() {
    _isChapterListReversed = !_isChapterListReversed;
    notifyListeners();
  }

  /// Clear state
  void clear() {
    _isLoading = true;
    _error = null;
    _mangaDetail = null;
    _isDescriptionExpanded = false;
    _isChapterListReversed = false;
    notifyListeners();
  }
}
