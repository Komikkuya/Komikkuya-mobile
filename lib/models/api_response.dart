import 'manga_model.dart';

/// API response wrapper for manga list endpoints
class MangaListResponse {
  final String? category;
  final int page;
  final bool hasNextPage;
  final List<Manga> mangaList;
  final int? totalItems;

  MangaListResponse({
    this.category,
    required this.page,
    required this.hasNextPage,
    required this.mangaList,
    this.totalItems,
  });

  factory MangaListResponse.fromJson(Map<String, dynamic> json) {
    return MangaListResponse(
      category: json['category'],
      page: json['page'] ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      mangaList:
          (json['mangaList'] as List<dynamic>?)
              ?.map((e) => Manga.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalItems: json['totalItems'],
    );
  }
}
