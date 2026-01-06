import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../config/api_config.dart';
import 'notification_service.dart';

/// Keys for SharedPreferences
const String _kLastSeenMangaUrl = 'notification_last_seen_manga_url';
const String _kLastSeenChapterUrl = 'notification_last_seen_chapter_url';
const String _kNotificationsEnabled = 'notification_enabled';

/// Unique task name for Workmanager
const String backgroundTaskName = 'mangaUpdateCheck';

/// Categories to check for updates
const List<String> _categories = ['manga', 'manhwa', 'manhua'];

/// Callback dispatcher for Workmanager (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('BackgroundService: Task started - $task');

    try {
      // Check for updates
      final hasUpdate = await BackgroundService._checkForUpdates();
      debugPrint(
        'BackgroundService: Update check complete - hasUpdate=$hasUpdate',
      );
      return true;
    } catch (e) {
      debugPrint('BackgroundService: Error - $e');
      return false;
    }
  });
}

/// Service for background tasks and update checking
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;

  /// Initialize Workmanager
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    _isInitialized = true;
    debugPrint('BackgroundService: Initialized');
  }

  /// Start periodic background task (every 15 minutes minimum on Android)
  Future<void> startPeriodicTask() async {
    // Cancel any existing task first
    await Workmanager().cancelByUniqueName(backgroundTaskName);

    // Register periodic task
    await Workmanager().registerPeriodicTask(
      backgroundTaskName,
      backgroundTaskName,
      frequency: const Duration(minutes: 15), // Minimum on Android
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );

    // Save enabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, true);

    debugPrint('BackgroundService: Periodic task started');
  }

  /// Stop periodic background task
  Future<void> stopPeriodicTask() async {
    await Workmanager().cancelByUniqueName(backgroundTaskName);

    // Save disabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabled, false);

    debugPrint('BackgroundService: Periodic task stopped');
  }

  /// Check if notifications are enabled
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotificationsEnabled) ?? false;
  }

  /// Check for manga updates across all categories (called from background)
  static Future<bool> _checkForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      bool hasAnyUpdate = false;
      String? updateTitle;
      String? updateChapter;
      String? updateUrl;
      String? updateImageUrl;

      // Check all 3 categories: manga, manhwa, manhua
      for (final category in _categories) {
        debugPrint('BackgroundService: Checking category - $category');

        // Fetch latest for this category
        final url = ApiConfig.lastUpdateUrl(category: category, page: 1);
        final response = await http.get(Uri.parse(url));

        if (response.statusCode != 200) {
          debugPrint(
            'BackgroundService: API error for $category - ${response.statusCode}',
          );
          continue; // Try next category
        }

        final json = jsonDecode(response.body);
        if (json['success'] != true || json['data'] == null) {
          debugPrint('BackgroundService: Invalid API response for $category');
          continue;
        }

        final data = json['data'] as Map<String, dynamic>;
        final mangaList = data['mangaList'] as List<dynamic>?;

        if (mangaList == null || mangaList.isEmpty) {
          debugPrint('BackgroundService: No manga in $category response');
          continue;
        }

        // Get the first (latest) manga
        final latestManga = mangaList.first as Map<String, dynamic>;
        final mangaTitle = latestManga['title'] as String? ?? 'Unknown';
        final mangaUrl = latestManga['url'] as String? ?? '';
        final mangaImageUrl = latestManga['imageUrl'] as String? ?? '';

        // Get latest chapter info
        final latestChapter =
            latestManga['latestChapter'] as Map<String, dynamic>?;
        final chapterTitle = latestChapter?['title'] as String? ?? '';
        final chapterUrl = latestChapter?['url'] as String? ?? '';

        // Keys unique to this category
        final mangaUrlKey = '${_kLastSeenMangaUrl}_$category';
        final chapterUrlKey = '${_kLastSeenChapterUrl}_$category';

        // Compare with stored values
        final lastSeenMangaUrl = prefs.getString(mangaUrlKey) ?? '';
        final lastSeenChapterUrl = prefs.getString(chapterUrlKey) ?? '';

        // First run for this category - just save current state
        if (lastSeenMangaUrl.isEmpty) {
          await prefs.setString(mangaUrlKey, mangaUrl);
          await prefs.setString(chapterUrlKey, chapterUrl);
          debugPrint(
            'BackgroundService: First run for $category, saved initial state',
          );
          continue;
        }

        // Check if there's a new update for this category
        final hasNewUpdate =
            (mangaUrl != lastSeenMangaUrl) ||
            (chapterUrl != lastSeenChapterUrl);

        if (hasNewUpdate) {
          hasAnyUpdate = true;
          updateTitle = mangaTitle;
          updateChapter = chapterTitle;
          updateUrl = mangaUrl;
          updateImageUrl = mangaImageUrl;

          // Save new state for this category
          await prefs.setString(mangaUrlKey, mangaUrl);
          await prefs.setString(chapterUrlKey, chapterUrl);

          debugPrint(
            'BackgroundService: New update found in $category - $mangaTitle',
          );
          // Don't break - continue checking other categories and update state
        }
      }

      // If any update was found, show notification
      if (hasAnyUpdate && updateTitle != null) {
        // Initialize notification service
        final notificationService = NotificationService();
        await notificationService.initialize();

        // Show notification with image
        await notificationService.showUpdateNotification(
          title: 'Update Baru!',
          body: '$updateTitle - $updateChapter',
          payload: updateUrl,
          imageUrl: updateImageUrl,
        );

        debugPrint('BackgroundService: Notification sent for $updateTitle');
        return true;
      }

      debugPrint('BackgroundService: No new updates in any category');
      return false;
    } catch (e) {
      debugPrint('BackgroundService: _checkForUpdates error - $e');
      return false;
    }
  }

  /// Manually trigger update check (for testing)
  Future<bool> checkNow() async {
    return await _checkForUpdates();
  }

  /// Clear stored state for all categories (on logout)
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear state for all categories
    for (final category in _categories) {
      await prefs.remove('${_kLastSeenMangaUrl}_$category');
      await prefs.remove('${_kLastSeenChapterUrl}_$category');
    }

    // Also clear legacy keys (if any)
    await prefs.remove(_kLastSeenMangaUrl);
    await prefs.remove(_kLastSeenChapterUrl);

    debugPrint('BackgroundService: State cleared for all categories');
  }
}
