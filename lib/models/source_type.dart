/// Source types for manga content
enum MangaSource {
  /// Komiku Indonesia (default)
  komiku,

  /// Asia/WestManga
  asia,

  /// International/WeebCentral
  international,
}

/// Extension methods for MangaSource
extension MangaSourceExtension on MangaSource {
  /// Display name
  String get displayName {
    switch (this) {
      case MangaSource.komiku:
        return 'Indonesia';
      case MangaSource.asia:
        return 'Asia';
      case MangaSource.international:
        return 'International';
    }
  }

  /// Short label for badges
  String get shortLabel {
    switch (this) {
      case MangaSource.komiku:
        return 'ID';
      case MangaSource.asia:
        return 'ASIA';
      case MangaSource.international:
        return 'INT';
    }
  }

  /// Emoji flag
  String get emoji {
    switch (this) {
      case MangaSource.komiku:
        return '🇮🇩';
      case MangaSource.asia:
        return '🌏';
      case MangaSource.international:
        return '🌐';
    }
  }

  /// Detect source from URL
  static MangaSource fromUrl(String url) {
    if (url.contains('westmanga.me') || url.contains('westmanga.blog')) {
      return MangaSource.asia;
    } else if (url.contains('weebcentral.com') ||
        url.contains('internationalbackup')) {
      return MangaSource.international;
    }
    return MangaSource.komiku;
  }
}
