import 'source_type.dart';

/// Unified search result model for all sources
class SearchResult {
  final String title;
  final String url;
  final String imageUrl;
  final String? type;
  final String? status;
  final String? genre;
  final double? rating;
  final String? latestChapter;
  final MangaSource source;

  const SearchResult({
    required this.title,
    required this.url,
    required this.imageUrl,
    this.type,
    this.status,
    this.genre,
    this.rating,
    this.latestChapter,
    required this.source,
  });

  /// Factory for Komiku (Indonesia) search results
  factory SearchResult.fromKomikuJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      url: json['mangaUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'],
      status: null,
      genre: json['genre'],
      rating: null,
      latestChapter: json['latestChapter']?['title'],
      source: MangaSource.komiku,
    );
  }

  /// Factory for Asia (WestManga) search results
  factory SearchResult.fromAsiaJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: null,
      status: json['status'],
      genre: null,
      rating: (json['rating'] as num?)?.toDouble(),
      latestChapter: null,
      source: MangaSource.asia,
    );
  }

  /// Factory for International (WeebCentral) search results
  factory SearchResult.fromInternationalJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['cover'] ?? '',
      type: null,
      status: null,
      genre: null,
      rating: null,
      latestChapter: null,
      source: MangaSource.international,
    );
  }
}

/// Response wrapper for search results
class SearchResponse {
  final List<SearchResult> results;
  final String? query;
  final bool success;

  const SearchResponse({
    required this.results,
    this.query,
    this.success = true,
  });
}
