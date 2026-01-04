/// Chapter info model
class ChapterInfo {
  final String title;
  final String url;

  ChapterInfo({required this.title, required this.url});

  factory ChapterInfo.fromJson(Map<String, dynamic> json) {
    return ChapterInfo(title: json['title'] ?? '', url: json['url'] ?? '');
  }

  Map<String, dynamic> toJson() => {'title': title, 'url': url};
}

/// Manga stats model
class MangaStats {
  final String views;
  final String timeAgo;
  final bool? isColored;

  MangaStats({required this.views, required this.timeAgo, this.isColored});

  factory MangaStats.fromJson(Map<String, dynamic> json) {
    return MangaStats(
      views: json['views'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
      isColored: json['isColored'],
    );
  }

  Map<String, dynamic> toJson() => {
    'views': views,
    'timeAgo': timeAgo,
    'isColored': isColored,
  };
}

/// Main manga model for hot, last-update, and popular endpoints
class Manga {
  final String title;
  final String url;
  final String imageUrl;
  final String type;
  final String genre;
  final String? description;
  final ChapterInfo? firstChapter;
  final ChapterInfo? latestChapter;
  final MangaStats? stats;
  final String? updateStatus;

  Manga({
    required this.title,
    required this.url,
    required this.imageUrl,
    required this.type,
    required this.genre,
    this.description,
    this.firstChapter,
    this.latestChapter,
    this.stats,
    this.updateStatus,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? '',
      genre: json['genre'] ?? '',
      description: json['description'],
      firstChapter: json['firstChapter'] != null
          ? ChapterInfo.fromJson(json['firstChapter'])
          : null,
      latestChapter: json['latestChapter'] != null
          ? ChapterInfo.fromJson(json['latestChapter'])
          : null,
      stats: json['stats'] != null ? MangaStats.fromJson(json['stats']) : null,
      updateStatus: json['updateStatus'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'imageUrl': imageUrl,
    'type': type,
    'genre': genre,
    'description': description,
    'firstChapter': firstChapter?.toJson(),
    'latestChapter': latestChapter?.toJson(),
    'stats': stats?.toJson(),
    'updateStatus': updateStatus,
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
