/// Auth API configuration
class AuthConfig {
  static const String baseUrl = 'https://auth.komikkuya.my.id';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String profile = '/auth/profile';
  static const String profilePicture = '/auth/profile-picture';

  // Favorites endpoints
  static const String favorites = '/favorites';

  // Full URLs
  static String get registerUrl => '$baseUrl$register';
  static String get loginUrl => '$baseUrl$login';
  static String get meUrl => '$baseUrl$me';
  static String get profileUrl => '$baseUrl$profile';
  static String get profilePictureUrl => '$baseUrl$profilePicture';

  // Favorites URLs
  static String get favoritesUrl => '$baseUrl$favorites';
  static String favoriteByIdUrl(String id) => '$baseUrl$favorites/$id';
  static String checkFavoriteUrl(String id) => '$baseUrl$favorites/check/$id';
}
