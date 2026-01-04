import 'manga_model.dart';

/// Custom manga model for /api/custom endpoint (Hero section)
class CustomManga {
  final String title;
  final String url;
  final String imageUrl;
  final String genre;
  final ChapterInfo? latestChapter;
  final bool isHot;
  final String tentang; // description in Indonesian

  CustomManga({
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.genre,
    this.latestChapter,
    required this.isHot,
    required this.tentang,
  });

  factory CustomManga.fromJson(Map<String, dynamic> json) {
    return CustomManga(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      genre: json['genre'] ?? '',
      latestChapter: json['latestChapter'] != null
          ? ChapterInfo.fromJson(json['latestChapter'])
          : null,
      isHot: json['isHot'] ?? false,
      tentang: json['tentang'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'imageUrl': imageUrl,
    'genre': genre,
    'latestChapter': latestChapter?.toJson(),
    'isHot': isHot,
    'tentang': tentang,
  };

  /// Get a clean slug from URL for navigation
  String get slug {
    final uri = Uri.parse(url);
    final path = uri.path;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty && segments.first == 'manga') {
      return segments.length > 1 ? segments[1] : segments.first;
    }
    return segments.isNotEmpty ? segments.last : '';
  }
}
