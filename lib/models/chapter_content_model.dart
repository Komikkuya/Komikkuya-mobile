import '../config/api_config.dart';
import 'source_type.dart';

/// Model for chapter content from multiple sources
class ChapterContent {
  final String title;
  final String mangaTitle;
  final String releaseDate;
  final String readDirection;
  final List<ChapterImage> images;
  final ChapterNavigation navigation;
  final String mangaUrl;
  final MangaSource source;

  ChapterContent({
    required this.title,
    required this.mangaTitle,
    required this.releaseDate,
    required this.readDirection,
    required this.images,
    required this.navigation,
    required this.mangaUrl,
    required this.source,
  });

  /// Factory for Komiku API
  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      title: json['title'] ?? '',
      mangaTitle: json['mangaTitle'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      readDirection: json['readDirection'] ?? 'vertical',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => ChapterImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      navigation: ChapterNavigation.fromJson(
        json['navigation'] as Map<String, dynamic>? ?? {},
      ),
      mangaUrl: ApiConfig.cleanUrl(json['navigation']?['chapterList'] ?? ''),
      source: MangaSource.komiku,
    );
  }

  /// Factory for Asia (WestManga) API
  /// Images are string array, not objects
  factory ChapterContent.fromAsiaJson(Map<String, dynamic> json) {
    // Parse images (string array)
    final imageList =
        (json['images'] as List<dynamic>?)
            ?.asMap()
            .entries
            .map(
              (e) => ChapterImage(
                url: e.value.toString(),
                alt: 'Page ${e.key + 1}',
                order: e.key,
              ),
            )
            .toList() ??
        [];

    return ChapterContent(
      title: json['title'] ?? '',
      mangaTitle: json['contentTitle'] ?? json['mangaTitle'] ?? '',
      releaseDate: json['createdAt'] ?? '',
      readDirection: 'vertical',
      images: imageList,
      navigation: ChapterNavigation.fromAsiaJson(json),
      mangaUrl: json['comicUrl'] ?? '',
      source: MangaSource.asia,
    );
  }

  /// Factory for International (WeebCentral) API
  /// Images are objects with page, url, width, height
  factory ChapterContent.fromInternationalJson(Map<String, dynamic> json) {
    // Parse images (object array)
    final imageList =
        (json['images'] as List<dynamic>?)?.asMap().entries.map((e) {
          final img = e.value as Map<String, dynamic>;
          return ChapterImage(
            url: img['url'] ?? '',
            alt: img['alt'] ?? 'Page ${e.key + 1}',
            order: img['page'] ?? e.key,
          );
        }).toList() ??
        [];

    return ChapterContent(
      title: json['chapterNumber'] ?? '',
      mangaTitle: json['mangaTitle'] ?? '',
      releaseDate: '',
      readDirection: 'vertical',
      images: imageList,
      navigation: ChapterNavigation.fromInternationalJson(json),
      mangaUrl: json['mangaUrl'] ?? '',
      source: MangaSource.international,
    );
  }

  /// Get total image count
  int get totalImages => images.length;
}

/// Individual image in chapter
class ChapterImage {
  final String url;
  final String alt;
  final int order;

  ChapterImage({required this.url, required this.alt, required this.order});

  factory ChapterImage.fromJson(Map<String, dynamic> json) {
    return ChapterImage(
      url: json['url'] ?? '',
      alt: json['alt'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}

/// Navigation links for chapter (prev/next)
class ChapterNavigation {
  final ChapterLink? prev;
  final ChapterLink? next;
  final String chapterListUrl;
  final MangaSource source;

  ChapterNavigation({
    this.prev,
    this.next,
    required this.chapterListUrl,
    required this.source,
  });

  /// Factory for Komiku API
  factory ChapterNavigation.fromJson(Map<String, dynamic> json) {
    return ChapterNavigation(
      prev: json['prev'] != null
          ? ChapterLink.fromJson(json['prev'] as Map<String, dynamic>)
          : null,
      next: json['next'] != null
          ? ChapterLink.fromJson(json['next'] as Map<String, dynamic>)
          : null,
      chapterListUrl: ApiConfig.cleanUrl(json['chapterList'] ?? ''),
      source: MangaSource.komiku,
    );
  }

  /// Factory for Asia API
  factory ChapterNavigation.fromAsiaJson(Map<String, dynamic> json) {
    return ChapterNavigation(
      prev: json['prevChapter'] != null
          ? ChapterLink(
              url: json['prevChapter']['url'] ?? '',
              title: json['prevChapter']['title'] ?? 'Previous',
            )
          : null,
      next: json['nextChapter'] != null
          ? ChapterLink(
              url: json['nextChapter']['url'] ?? '',
              title: json['nextChapter']['title'] ?? 'Next',
            )
          : null,
      chapterListUrl: json['comicUrl'] ?? '',
      source: MangaSource.asia,
    );
  }

  /// Factory for International API
  factory ChapterNavigation.fromInternationalJson(Map<String, dynamic> json) {
    return ChapterNavigation(
      prev: json['prevChapter'] != null
          ? ChapterLink(
              url: json['prevChapter']['url'] ?? '',
              title: 'Previous',
            )
          : null,
      next: json['nextChapter'] != null
          ? ChapterLink(url: json['nextChapter']['url'] ?? '', title: 'Next')
          : null,
      chapterListUrl: json['mangaUrl'] ?? '',
      source: MangaSource.international,
    );
  }

  bool get hasPrev => prev != null;
  bool get hasNext => next != null;
}

/// Chapter link (for navigation)
class ChapterLink {
  final String url;
  final String title;

  ChapterLink({required this.url, required this.title});

  factory ChapterLink.fromJson(Map<String, dynamic> json) {
    return ChapterLink(
      url: ApiConfig.cleanUrl(json['url'] ?? ''),
      title: json['title'] ?? '',
    );
  }
}
