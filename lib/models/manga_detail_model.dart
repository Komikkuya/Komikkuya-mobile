import 'source_type.dart';

/// Model for manga detail from multiple sources
class MangaDetail {
  final String title;
  final String alternativeTitle;
  final String description;
  final String coverImage;
  final String type;
  final List<String> genres;
  final String status;
  final String author;
  final List<ChapterItem> chapters;
  final String mangaUrl;
  final MangaSource source;

  MangaDetail({
    required this.title,
    required this.alternativeTitle,
    required this.description,
    required this.coverImage,
    required this.type,
    required this.genres,
    required this.status,
    required this.author,
    required this.chapters,
    required this.mangaUrl,
    required this.source,
  });

  /// Factory for Komiku API response
  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    return MangaDetail(
      title: _cleanTitle(json['title'] ?? ''),
      alternativeTitle: json['alternativeTitle'] ?? '',
      description: json['description'] ?? '',
      coverImage: json['coverImage'] ?? '',
      type: json['type'] ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] ?? '',
      author: json['author'] ?? '',
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => ChapterItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mangaUrl: json['mangaUrl'] ?? '',
      source: MangaSource.komiku,
    );
  }

  /// Factory for Asia (WestManga) API response
  factory MangaDetail.fromAsiaJson(Map<String, dynamic> json) {
    return MangaDetail(
      title: json['title'] ?? '',
      alternativeTitle: '',
      description: json['description'] ?? '',
      coverImage: json['cover'] ?? '',
      type: json['type'] ?? 'Manhwa',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: json['status'] ?? '',
      author: '', // Not provided in Asia API
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => ChapterItem.fromAsiaJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mangaUrl: json['url'] ?? '',
      source: MangaSource.asia,
    );
  }

  /// Factory for International (WeebCentral) API response
  factory MangaDetail.fromInternationalJson(Map<String, dynamic> json) {
    // Handle duplicate title issue (e.g., "Solo LevelingSolo Leveling")
    String title = json['title'] ?? '';
    if (title.length > 2) {
      final half = title.length ~/ 2;
      if (title.substring(0, half) == title.substring(half)) {
        title = title.substring(0, half);
      }
    }

    return MangaDetail(
      title: title,
      alternativeTitle: '',
      description: json['description'] ?? '',
      coverImage: json['cover'] ?? '',
      type: json['type'] ?? 'Manga',
      genres:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      status: json['status'] ?? '',
      author: (json['authors'] as List<dynamic>?)?.join(', ') ?? '',
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map(
                (e) => ChapterItem.fromInternationalJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      mangaUrl: json['url'] ?? '',
      source: MangaSource.international,
    );
  }

  /// Clean title by removing "Komik " prefix if present
  static String _cleanTitle(String title) {
    if (title.toLowerCase().startsWith('komik ')) {
      return title.substring(6);
    }
    return title;
  }

  /// Get total chapters count
  int get totalChapters => chapters.length;

  /// Get first chapter
  ChapterItem? get firstChapter => chapters.isNotEmpty ? chapters.last : null;

  /// Get latest chapter
  ChapterItem? get latestChapter => chapters.isNotEmpty ? chapters.first : null;

  /// Get total readers (sum of all chapters)
  int get totalReaders =>
      chapters.fold(0, (sum, chapter) => sum + chapter.readers);
}

/// Individual chapter item
class ChapterItem {
  final String title;
  final String url;
  final int readers;
  final String date;
  final MangaSource source;

  ChapterItem({
    required this.title,
    required this.url,
    required this.readers,
    required this.date,
    required this.source,
  });

  /// Factory for Komiku API
  factory ChapterItem.fromJson(Map<String, dynamic> json) {
    return ChapterItem(
      title: json['title'] ?? '',
      url: _cleanUrl(json['url'] ?? ''),
      readers: json['readers'] ?? 0,
      date: json['date'] ?? '',
      source: MangaSource.komiku,
    );
  }

  /// Factory for Asia API
  factory ChapterItem.fromAsiaJson(Map<String, dynamic> json) {
    return ChapterItem(
      title: json['title'] ?? 'Chapter ${json['number'] ?? ''}',
      url: json['url'] ?? '',
      readers: 0,
      date: json['date'] ?? '',
      source: MangaSource.asia,
    );
  }

  /// Factory for International API
  factory ChapterItem.fromInternationalJson(Map<String, dynamic> json) {
    return ChapterItem(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      readers: 0,
      date: _formatInternationalDate(json['dateTime'] ?? json['date'] ?? ''),
      source: MangaSource.international,
    );
  }

  /// Format international date
  static String _formatInternationalDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Clean URL by removing double domain if present
  static String _cleanUrl(String url) {
    // Handle double https://komiku.org/ issue
    const domain = 'https://komiku.org/';
    if (url.startsWith('$domain$domain')) {
      return url.replaceFirst(domain, '');
    }
    // Handle //chapter-xxx format
    if (url.contains('//') && !url.startsWith('http')) {
      url = url.replaceAll('//', '/');
    }
    return url;
  }

  /// Format readers count (e.g., 12.5K, 1.2M)
  String get formattedReaders {
    if (readers >= 1000000) {
      return '${(readers / 1000000).toStringAsFixed(1)}M';
    } else if (readers >= 1000) {
      return '${(readers / 1000).toStringAsFixed(1)}K';
    }
    return readers.toString();
  }
}
