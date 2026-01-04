import 'package:flutter/foundation.dart';
import '../models/history_model.dart';
import '../services/history_service.dart';

/// Controller for reading history state management
class HistoryController extends ChangeNotifier {
  final HistoryService _service = HistoryService();

  // State
  bool _isLoading = false;
  List<HistoryItem> _history = [];
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  List<HistoryItem> get history => _history;
  String? get error => _error;
  bool get hasError => _error != null;
  int get count => _history.length;

  // ==================== LOAD HISTORY ====================

  /// Load reading history from server
  Future<void> loadHistory({int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _history = await _service.getHistory(limit: limit);
      debugPrint('HistoryController: Loaded ${_history.length} items');
    } catch (e) {
      _error = e.toString();
      debugPrint('HistoryController.loadHistory error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== SAVE HISTORY ====================

  /// Save reading history (add or update)
  Future<bool> saveHistory({
    required String title,
    required String chapterTitle,
    required String url,
    String? image,
    String? type,
  }) async {
    final item = HistoryItem(
      title: title,
      chapterTitle: chapterTitle,
      url: url,
      image: image,
      type: type,
      time: DateTime.now(),
    );

    // Optimistic update - add to front or update existing
    final existingIndex = _history.indexWhere((h) => h.url == url);
    if (existingIndex >= 0) {
      _history.removeAt(existingIndex);
    }
    _history.insert(0, item);
    notifyListeners();

    final success = await _service.saveHistory(item);

    if (!success) {
      // Rollback on failure
      _history.removeWhere((h) => h.url == url);
      if (existingIndex >= 0) {
        // Restore old item at original position
        await loadHistory();
      }
      notifyListeners();
    }

    debugPrint('HistoryController.saveHistory: $url -> $success');
    return success;
  }

  // ==================== DELETE HISTORY ====================

  /// Delete single history entry
  Future<bool> deleteHistory(String url) async {
    final index = _history.indexWhere((h) => h.url == url);
    if (index < 0) return true;

    final item = _history[index];

    // Optimistic update
    _history.removeAt(index);
    notifyListeners();

    final success = await _service.deleteHistory(url);

    if (!success) {
      // Rollback
      _history.insert(index, item);
      notifyListeners();
    }

    debugPrint('HistoryController.deleteHistory: $url -> $success');
    return success;
  }

  /// Clear all history
  Future<bool> clearAllHistory() async {
    final backup = List<HistoryItem>.from(_history);

    // Optimistic update
    _history.clear();
    notifyListeners();

    final success = await _service.clearAllHistory();

    if (!success) {
      // Rollback
      _history = backup;
      notifyListeners();
    }

    debugPrint('HistoryController.clearAllHistory -> $success');
    return success;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all (on logout)
  void clear() {
    _history.clear();
    _error = null;
    notifyListeners();
  }
}
