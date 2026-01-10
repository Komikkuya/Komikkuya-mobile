import '../config/api_config.dart';
import '../models/custom_manga_model.dart';
import '../models/api_response.dart';
import '../models/manga_detail_model.dart';
import '../models/chapter_content_model.dart';
import '../models/search_result_model.dart';
import '../models/source_type.dart';
import 'api_service.dart';

/// Service for manga-related API calls
class MangaService {
  final ApiService _apiService = ApiService();

  /// Fetch custom/featured manga for hero section
  Future<List<CustomManga>> fetchCustomManga() async {
    try {
      final response = await _apiService.get(ApiConfig.customUrl);
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List<dynamic>)
            .map((e) => CustomManga.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch all genres
  Future<List<String>> fetchGenres() async {
    try {
      final response = await _apiService.get(ApiConfig.genresUrl);
      if (response['success'] == true && response['data'] != null) {
        return (response['data'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch hot/trending manga
  Future<MangaListResponse> fetchHotManga({int page = 1}) async {
    try {
      final response = await _apiService.get(ApiConfig.hotUrl(page: page));
      if (response['success'] == true && response['data'] != null) {
        return MangaListResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }
      return MangaListResponse(page: page, hasNextPage: false, mangaList: []);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch latest manga by category (manga, manhwa, manhua)
  Future<MangaListResponse> fetchLatestManga({
    required String category,
    int page = 1,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.lastUpdateUrl(category: category, page: page),
      );
      if (response['success'] == true && response['data'] != null) {
        return MangaListResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }
      return MangaListResponse(
        category: category,
        page: page,
        hasNextPage: false,
        mangaList: [],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch popular manga by sort time (daily, weekly, all)
  Future<MangaListResponse> fetchPopularManga({
    String category = 'manga',
    required String sortTime,
    int page = 1,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.popularUrl(
          category: category,
          sortTime: sortTime,
          page: page,
        ),
      );
      if (response['success'] == true && response['data'] != null) {
        return MangaListResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }
      return MangaListResponse(
        category: category,
        page: page,
        hasNextPage: false,
        mangaList: [],
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch manga by genre
  Future<MangaListResponse> fetchMangaByGenre({
    required String genre,
    String category = 'manga',
    int page = 1,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConfig.genreUrl(genre: genre, category: category, page: page),
      );
      if (response['success'] == true && response['data'] != null) {
        return MangaListResponse.fromJson(
          response['data'] as Map<String, dynamic>,
        );
      }
      return MangaListResponse(
        category: category,
        page: page,
        hasNextPage: false,
        mangaList: [],
      );
    } catch (e) {
      rethrow;
    }
  }

  // ==================== SEARCH ====================

  /// Search all sources and combine results
  Future<List<SearchResult>> searchAll(String query) async {
    final results = <SearchResult>[];

    // Fetch from all 3 sources in parallel
    final futures = await Future.wait([
      _searchKomiku(query).catchError((_) => <SearchResult>[]),
      _searchAsia(query).catchError((_) => <SearchResult>[]),
      _searchInternational(query).catchError((_) => <SearchResult>[]),
    ]);

    for (final list in futures) {
      results.addAll(list);
    }

    return results;
  }

  /// Search Komiku (Indonesia)
  Future<List<SearchResult>> _searchKomiku(String query) async {
    final response = await _apiService.get(ApiConfig.searchUrl(query));
    if (response['success'] == true && response['data'] != null) {
      return (response['data'] as List<dynamic>)
          .map((e) => SearchResult.fromKomikuJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Search Asia (WestManga)
  Future<List<SearchResult>> _searchAsia(String query) async {
    final response = await _apiService.get(ApiConfig.asiaSearchUrl(query));
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map((e) => SearchResult.fromAsiaJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Search International (WeebCentral)
  Future<List<SearchResult>> _searchInternational(String query) async {
    final response = await _apiService.get(
      ApiConfig.internationalSearchUrl(query),
    );
    if (response['success'] == true && response['data'] != null) {
      final data = response['data'] as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      return results
          .map(
            (e) =>
                SearchResult.fromInternationalJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  // ==================== DETAIL ====================

  /// Fetch manga detail by URL (auto-detects source)
  Future<MangaDetail> fetchMangaDetail(String mangaUrl) async {
    final source = MangaSourceExtension.fromUrl(mangaUrl);
    switch (source) {
      case MangaSource.asia:
        return fetchAsiaDetail(mangaUrl);
      case MangaSource.international:
        return fetchInternationalDetail(mangaUrl);
      case MangaSource.komiku:
        return fetchKomikuDetail(mangaUrl);
      case MangaSource.doujin:
        // Doujin has its own separate flow via DoujinController
        throw UnsupportedError('Use DoujinController for doujin content');
    }
  }

  /// Fetch Komiku detail
  Future<MangaDetail> fetchKomikuDetail(String mangaUrl) async {
    final response = await _apiService.get(ApiConfig.mangaDetailUrl(mangaUrl));
    return MangaDetail.fromJson(response);
  }

  /// Fetch Asia (WestManga) detail
  Future<MangaDetail> fetchAsiaDetail(String mangaUrl) async {
    final response = await _apiService.get(ApiConfig.asiaDetailUrl(mangaUrl));
    if (response['success'] == true && response['data'] != null) {
      return MangaDetail.fromAsiaJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load Asia manga detail');
  }

  /// Fetch International (WeebCentral) detail
  Future<MangaDetail> fetchInternationalDetail(String mangaUrl) async {
    final response = await _apiService.get(
      ApiConfig.internationalDetailUrl(mangaUrl),
    );
    if (response['success'] == true && response['data'] != null) {
      return MangaDetail.fromInternationalJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load International manga detail');
  }

  // ==================== CHAPTER ====================

  /// Fetch chapter content by URL (auto-detects source)
  Future<ChapterContent> fetchChapter(String chapterUrl) async {
    final source = MangaSourceExtension.fromUrl(chapterUrl);
    switch (source) {
      case MangaSource.asia:
        return fetchAsiaChapter(chapterUrl);
      case MangaSource.international:
        return fetchInternationalChapter(chapterUrl);
      case MangaSource.komiku:
        return fetchKomikuChapter(chapterUrl);
      case MangaSource.doujin:
        // Doujin has its own separate flow via DoujinController
        throw UnsupportedError('Use DoujinReaderScreen for doujin content');
    }
  }

  /// Fetch Komiku chapter
  Future<ChapterContent> fetchKomikuChapter(String chapterUrl) async {
    final response = await _apiService.get(ApiConfig.chapterUrl(chapterUrl));
    return ChapterContent.fromJson(response);
  }

  /// Fetch Asia (WestManga) chapter
  Future<ChapterContent> fetchAsiaChapter(String chapterUrl) async {
    final response = await _apiService.get(
      ApiConfig.asiaChapterUrl(chapterUrl),
    );
    if (response['success'] == true && response['data'] != null) {
      return ChapterContent.fromAsiaJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load Asia chapter');
  }

  /// Fetch International (WeebCentral) chapter
  Future<ChapterContent> fetchInternationalChapter(String chapterUrl) async {
    final response = await _apiService.get(
      ApiConfig.internationalChapterUrl(chapterUrl),
    );
    if (response['success'] == true && response['data'] != null) {
      return ChapterContent.fromInternationalJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    throw Exception('Failed to load International chapter');
  }
}
