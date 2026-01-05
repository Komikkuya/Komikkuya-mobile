import 'package:shared_preferences/shared_preferences.dart';

/// Image quality levels for chapter reader
enum ImageQuality {
  low, // 480px width
  medium, // 720px width
  high, // Original size
}

/// Extension for ImageQuality display names
extension ImageQualityExtension on ImageQuality {
  String get displayName {
    switch (this) {
      case ImageQuality.low:
        return 'Low';
      case ImageQuality.medium:
        return 'Medium';
      case ImageQuality.high:
        return 'High';
    }
  }

  String get description {
    switch (this) {
      case ImageQuality.low:
        return '480p - Fastest';
      case ImageQuality.medium:
        return '720p - Balanced';
      case ImageQuality.high:
        return 'Original - Best';
    }
  }

  int? get width {
    switch (this) {
      case ImageQuality.low:
        return 480;
      case ImageQuality.medium:
        return 720;
      case ImageQuality.high:
        return null; // Original
    }
  }
}

/// Reader settings model
class ReaderSettings {
  final ImageQuality quality;
  final bool dataSaverMode;
  final bool preloadImages;
  final bool zoomEnabled;

  const ReaderSettings({
    this.quality = ImageQuality.high,
    this.dataSaverMode = false,
    this.preloadImages = true,
    this.zoomEnabled = true,
  });

  ReaderSettings copyWith({
    ImageQuality? quality,
    bool? dataSaverMode,
    bool? preloadImages,
    bool? zoomEnabled,
  }) {
    return ReaderSettings(
      quality: quality ?? this.quality,
      dataSaverMode: dataSaverMode ?? this.dataSaverMode,
      preloadImages: preloadImages ?? this.preloadImages,
      zoomEnabled: zoomEnabled ?? this.zoomEnabled,
    );
  }

  /// Load settings from SharedPreferences
  static Future<ReaderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();

    final qualityIndex =
        prefs.getInt('reader_quality') ?? ImageQuality.high.index;
    final dataSaver = prefs.getBool('reader_data_saver') ?? false;
    final preload = prefs.getBool('reader_preload') ?? true;
    final zoom = prefs.getBool('reader_zoom') ?? true;

    return ReaderSettings(
      quality: ImageQuality
          .values[qualityIndex.clamp(0, ImageQuality.values.length - 1)],
      dataSaverMode: dataSaver,
      preloadImages: preload,
      zoomEnabled: zoom,
    );
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('reader_quality', quality.index);
    await prefs.setBool('reader_data_saver', dataSaverMode);
    await prefs.setBool('reader_preload', preloadImages);
    await prefs.setBool('reader_zoom', zoomEnabled);
  }
}
