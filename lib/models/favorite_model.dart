/// Favorite item model
class FavoriteItem {
  final String id;
  final String slug;
  final String title;
  final String? url; // Full URL for navigation
  final String? cover;
  final String? type;
  final String? source;
  final DateTime? createdAt;

  FavoriteItem({
    required this.id,
    required this.slug,
    required this.title,
    this.url,
    this.cover,
    this.type,
    this.source,
    this.createdAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      url: json['url'] as String?,
      cover: json['cover'] as String?,
      type: json['type'] as String?,
      source: json['source'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'url': url,
    'cover': cover,
    'type': type,
    'source': source,
  };
}
