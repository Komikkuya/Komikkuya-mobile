/// API configuration constants
class ApiConfig {
  static const String baseUrl = 'https://komiku-api-self.vercel.app';
  static const String internationalBaseUrl =
      'https://internationalbackup.komikkuya.my.id';

  // Komiku Endpoints
  static const String custom = '/api/custom';
  static const String genres = '/api/genres';
  static const String hot = '/api/hot';
  static const String lastUpdate = '/api/last-update';
  static const String popular = '/api/popular';
  static const String manga = '/api/manga';
  static const String chapter = '/api/chapter';
  static const String search = '/api/search';

  // Asia Endpoints
  static const String asiaSearch = '/api/asia/search';
  static const String asiaDetail = '/api/asia/detail';
  static const String asiaChapter = '/api/asia/chapter';

  // International Endpoints
  static const String internationalSearch = '/api/international/search';
  static const String internationalDetail = '/api/international/detail';
  static const String internationalChapter = '/api/international/chapter';

  // Doujin Endpoints (Hidden Feature)
  static const String doujinBaseUrl =
      'https://internationalbackup.komikkuya.my.id';
  static const String doujinLastUpdate = '/api/doujin/last-update';
  static const String doujinDetail = '/api/doujin/detail';

  // Full URLs
  static String get customUrl => '$baseUrl$custom';
  static String get genresUrl => '$baseUrl$genres';
  static String hotUrl({int page = 1}) => '$baseUrl$hot?page=$page';
  static String lastUpdateUrl({required String category, int page = 1}) =>
      '$baseUrl$lastUpdate?category=$category&page=$page';
  static String popularUrl({
    required String category,
    required String sortTime,
    int page = 1,
  }) => '$baseUrl$popular?category=$category&page=$page&sorttime=$sortTime';

  static String genreUrl({
    required String genre,
    required String category,
    int page = 1,
  }) => '$baseUrl/api/genre?genre=$genre&category=$category&page=$page';

  // Search URLs
  static String searchUrl(String query) =>
      '$baseUrl$search?query=${Uri.encodeComponent(query)}';

  static String asiaSearchUrl(String query) =>
      '$baseUrl$asiaSearch?q=${Uri.encodeComponent(query)}';

  static String internationalSearchUrl(String query) =>
      '$internationalBaseUrl$internationalSearch?q=${Uri.encodeComponent(query)}';

  /// Manga detail endpoint - handles double URL issue
  static String mangaDetailUrl(String mangaUrl) {
    // Clean the URL first - remove double domain if present
    final cleanedUrl = cleanUrl(mangaUrl);
    return '$baseUrl$manga?url=$cleanedUrl';
  }

  /// Asia detail endpoint
  static String asiaDetailUrl(String detailUrl) {
    return '$baseUrl$asiaDetail?url=${Uri.encodeComponent(detailUrl)}';
  }

  /// International detail endpoint
  static String internationalDetailUrl(String detailUrl) {
    return '$internationalBaseUrl$internationalDetail?url=${Uri.encodeComponent(detailUrl)}';
  }

  /// Chapter content endpoint - handles double URL issue
  static String chapterUrl(String chapterUrl) {
    final cleanedUrl = cleanUrl(chapterUrl);
    return '$baseUrl$chapter?url=$cleanedUrl';
  }

  /// Asia chapter endpoint
  static String asiaChapterUrl(String chapterUrl) {
    return '$baseUrl$asiaChapter?url=${Uri.encodeComponent(chapterUrl)}';
  }

  /// International chapter endpoint
  static String internationalChapterUrl(String chapterUrl) {
    return '$internationalBaseUrl$internationalChapter?url=${Uri.encodeComponent(chapterUrl)}';
  }

  /// Doujin last update endpoint
  static String doujinLastUpdateUrl({int page = 1}) =>
      '$doujinBaseUrl$doujinLastUpdate?page=$page';

  /// Doujin detail endpoint
  static String doujinDetailUrl(String detailUrl) =>
      '$doujinBaseUrl$doujinDetail?url=${Uri.encodeComponent(detailUrl)}';

  /// Doujin chapter endpoint
  static String doujinChapterUrl(String chapterUrl) =>
      '$doujinBaseUrl/api/doujin/chapter?url=${Uri.encodeComponent(chapterUrl)}';

  /// Clean URL by removing double domain prefix
  /// Handles: https://komiku.org/https://komiku.org/manga/xxx -> https://komiku.org/manga/xxx
  static String cleanUrl(String url) {
    const domain = 'https://komiku.org/';

    // Handle double domain issue
    if (url.startsWith('$domain$domain')) {
      return url.replaceFirst(domain, '');
    }

    // Handle triple forward slash
    if (url.contains('///')) {
      url = url.replaceAll('///', '/');
    }

    // Handle double forward slash in path (not http://)
    final httpIndex = url.indexOf('://');
    if (httpIndex >= 0) {
      final afterHttp = url.substring(httpIndex + 3);
      final cleanedPath = afterHttp.replaceAll('//', '/');
      url = '${url.substring(0, httpIndex + 3)}$cleanedPath';
    }

    return url;
  }
}
