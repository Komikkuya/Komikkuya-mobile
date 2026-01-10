/// Source types for manga content
enum MangaSource {
  /// Komiku Indonesia (default)
  komiku,

  /// Asia/WestManga
  asia,

  /// International/WeebCentral
  international,

  /// Doujin (hidden feature)
  doujin,
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
      case MangaSource.doujin:
        return 'Doujin';
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
      case MangaSource.doujin:
        return '18+';
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
      case MangaSource.doujin:
        return '🔞';
    }
  }

  /// Detect source from URL
  static MangaSource fromUrl(String url) {
    if (url.contains('komikdewasa.id')) {
      return MangaSource.doujin;
    } else if (url.contains('westmanga.me') || url.contains('westmanga.blog')) {
      return MangaSource.asia;
    } else if (url.contains('weebcentral.com') ||
        url.contains('internationalbackup')) {
      return MangaSource.international;
    }
    return MangaSource.komiku;
  }

  /// Get source from type string
  static MangaSource fromTypeString(String? type) {
    switch (type?.toLowerCase()) {
      case 'doujin':
        return MangaSource.doujin;
      case 'asia':
        return MangaSource.asia;
      case 'international':
        return MangaSource.international;
      default:
        return MangaSource.komiku;
    }
  }
}
