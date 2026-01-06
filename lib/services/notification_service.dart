import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'notification_navigation_service.dart';

/// Service for handling local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('NotificationService: Initialized');
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint(
      'NotificationService: Notification tapped - ${response.payload}',
    );

    // Store pending navigation - will be processed after splash screen
    if (response.payload != null && response.payload!.isNotEmpty) {
      NotificationNavigationService().setPendingNavigation(response.payload);
    }
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      debugPrint('NotificationService: Permission status = $status');
      return status.isGranted;
    }
    return true;
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return true;
  }

  /// Download image from URL and return as bytes
  Future<Uint8List?> _downloadImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('NotificationService: Failed to download image - $e');
    }
    return null;
  }

  /// Show a manga update notification with optional image
  Future<void> showUpdateNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    AndroidNotificationDetails androidDetails;

    // Try to load image if URL provided
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final imageBytes = await _downloadImage(imageUrl);

      if (imageBytes != null) {
        // Create BigPicture style notification with image
        final bigPictureStyle = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(imageBytes),
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: false,
        );

        androidDetails = AndroidNotificationDetails(
          'manga_updates',
          'Manga Updates',
          channelDescription: 'Notifications for new manga chapter updates',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'New manga update',
          icon: '@mipmap/ic_launcher',
          largeIcon: ByteArrayAndroidBitmap(imageBytes),
          color: const Color(0xFF8B5CF6),
          enableLights: true,
          ledColor: const Color(0xFF8B5CF6),
          ledOnMs: 1000,
          ledOffMs: 500,
          styleInformation: bigPictureStyle,
        );
      } else {
        // Fallback to simple notification if image download fails
        androidDetails = _createSimpleNotificationDetails();
      }
    } else {
      // No image URL provided
      androidDetails = _createSimpleNotificationDetails();
    }

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    debugPrint('NotificationService: Showed notification - $title');
  }

  /// Create simple notification details without image
  AndroidNotificationDetails _createSimpleNotificationDetails() {
    return const AndroidNotificationDetails(
      'manga_updates',
      'Manga Updates',
      channelDescription: 'Notifications for new manga chapter updates',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'New manga update',
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF8B5CF6),
      enableLights: true,
      ledColor: Color(0xFF8B5CF6),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
