import 'package:shared_preferences/shared_preferences.dart';

/// Cache settings model for storage management
class CacheSettings {
  final int maxCacheSizeMB;
  final bool autoCleanOldCache;
  final int oldCacheDays;

  const CacheSettings({
    this.maxCacheSizeMB = 500,
    this.autoCleanOldCache = true,
    this.oldCacheDays = 7,
  });

  CacheSettings copyWith({
    int? maxCacheSizeMB,
    bool? autoCleanOldCache,
    int? oldCacheDays,
  }) {
    return CacheSettings(
      maxCacheSizeMB: maxCacheSizeMB ?? this.maxCacheSizeMB,
      autoCleanOldCache: autoCleanOldCache ?? this.autoCleanOldCache,
      oldCacheDays: oldCacheDays ?? this.oldCacheDays,
    );
  }

  /// Load settings from SharedPreferences
  static Future<CacheSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    return CacheSettings(
      maxCacheSizeMB: prefs.getInt('cache_max_size_mb') ?? 500,
      autoCleanOldCache: prefs.getBool('cache_auto_clean') ?? true,
      oldCacheDays: prefs.getInt('cache_old_days') ?? 7,
    );
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('cache_max_size_mb', maxCacheSizeMB);
    await prefs.setBool('cache_auto_clean', autoCleanOldCache);
    await prefs.setInt('cache_old_days', oldCacheDays);
  }

  /// Format cache size for display
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
