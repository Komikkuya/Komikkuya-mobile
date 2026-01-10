/// Doujin item model for list display
class DoujinItem {
  final String title;
  final String slug;
  final String url;
  final String imageUrl;
  final List<String> genres;
  final List<DoujinChapterPreview> chapters;

  DoujinItem({
    required this.title,
    required this.slug,
    required this.url,
    required this.imageUrl,
    required this.genres,
    required this.chapters,
  });

  factory DoujinItem.fromJson(Map<String, dynamic> json) {
    return DoujinItem(
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      url: json['url'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map(
                (e) => DoujinChapterPreview.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

/// Chapter preview in list view
class DoujinChapterPreview {
  final String title;
  final String url;
  final String slug;

  DoujinChapterPreview({
    required this.title,
    required this.url,
    required this.slug,
  });

  factory DoujinChapterPreview.fromJson(Map<String, dynamic> json) {
    return DoujinChapterPreview(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

/// Doujin detail model
class DoujinDetail {
  final String slug;
  final String title;
  final String cover;
  final String type;
  final String status;
  final String author;
  final String lastUpdate;
  final List<String> genres;
  final String description;
  final String url;
  final int totalChapters;
  final List<DoujinChapter> chapters;

  DoujinDetail({
    required this.slug,
    required this.title,
    required this.cover,
    required this.type,
    required this.status,
    required this.author,
    required this.lastUpdate,
    required this.genres,
    required this.description,
    required this.url,
    required this.totalChapters,
    required this.chapters,
  });

  factory DoujinDetail.fromJson(Map<String, dynamic> json) {
    return DoujinDetail(
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      author: json['author'] as String? ?? '',
      lastUpdate: json['lastUpdate'] as String? ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      totalChapters: json['totalChapters'] as int? ?? 0,
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map((e) => DoujinChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Chapter in detail view
class DoujinChapter {
  final String number;
  final String title;
  final String slug;
  final String url;

  DoujinChapter({
    required this.number,
    required this.title,
    required this.slug,
    required this.url,
  });

  factory DoujinChapter.fromJson(Map<String, dynamic> json) {
    return DoujinChapter(
      number: json['number'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

/// Chapter navigation link
class DoujinChapterLink {
  final String slug;
  final String url;

  DoujinChapterLink({required this.slug, required this.url});

  factory DoujinChapterLink.fromJson(Map<String, dynamic> json) {
    return DoujinChapterLink(
      slug: json['slug'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

/// Chapter data for reading
class DoujinChapterData {
  final String slug;
  final String mangaTitle;
  final String mangaSlug;
  final String mangaUrl;
  final String chapterNumber;
  final String url;
  final DoujinChapterLink? prevChapter;
  final DoujinChapterLink? nextChapter;
  final int totalImages;
  final List<DoujinChapterImage> images;

  DoujinChapterData({
    required this.slug,
    required this.mangaTitle,
    required this.mangaSlug,
    required this.mangaUrl,
    required this.chapterNumber,
    required this.url,
    this.prevChapter,
    this.nextChapter,
    required this.totalImages,
    required this.images,
  });

  factory DoujinChapterData.fromJson(Map<String, dynamic> json) {
    return DoujinChapterData(
      slug: json['slug'] as String? ?? '',
      mangaTitle: json['mangaTitle'] as String? ?? '',
      mangaSlug: json['mangaSlug'] as String? ?? '',
      mangaUrl: json['mangaUrl'] as String? ?? '',
      chapterNumber: json['chapterNumber'] as String? ?? '',
      url: json['url'] as String? ?? '',
      prevChapter: json['prevChapter'] != null
          ? DoujinChapterLink.fromJson(
              json['prevChapter'] as Map<String, dynamic>,
            )
          : null,
      nextChapter: json['nextChapter'] != null
          ? DoujinChapterLink.fromJson(
              json['nextChapter'] as Map<String, dynamic>,
            )
          : null,
      totalImages: json['totalImages'] as int? ?? 0,
      images:
          (json['images'] as List<dynamic>?)
              ?.map(
                (e) => DoujinChapterImage.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

/// Image in chapter
class DoujinChapterImage {
  final int page;
  final String url;
  final String alt;

  DoujinChapterImage({
    required this.page,
    required this.url,
    required this.alt,
  });

  factory DoujinChapterImage.fromJson(Map<String, dynamic> json) {
    return DoujinChapterImage(
      page: json['page'] as int? ?? 0,
      url: json['url'] as String? ?? '',
      alt: json['alt'] as String? ?? '',
    );
  }
}
