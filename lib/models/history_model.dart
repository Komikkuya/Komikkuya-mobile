/// Reading history item model
class HistoryItem {
  final int? id;
  final String title;
  final String chapterTitle;
  final String url;
  final String? image;
  final String? type;
  final DateTime time;
  final DateTime? createdAt;

  HistoryItem({
    this.id,
    required this.title,
    required this.chapterTitle,
    required this.url,
    this.image,
    this.type,
    required this.time,
    this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    // Robust ID parsing (can be int or string from API)
    int? parsedId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        parsedId = json['id'] as int;
      } else {
        parsedId = int.tryParse(json['id'].toString());
      }
    }

    // Robust time parsing (supports ISO string or Milliseconds Timestamp)
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);

      final stringValue = value.toString();
      final timestamp = int.tryParse(stringValue);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }

      return DateTime.tryParse(stringValue) ?? DateTime.now();
    }

    return HistoryItem(
      id: parsedId,
      title: (json['title'] ?? 'Unknown Manga').toString(),
      chapterTitle: (json['chapter_title'] ?? 'Unknown Chapter').toString(),
      url: (json['url'] ?? '').toString(),
      image: json['image'] as String?,
      type: json['type'] as String?,
      time: parseDateTime(json['time']),
      createdAt: json['created_at'] != null
          ? parseDateTime(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'chapterTitle': chapterTitle,
    'url': url,
    'image': image,
    'type': type,
    'time': time.millisecondsSinceEpoch,
  };

  /// Create a copy with updated fields
  HistoryItem copyWith({
    int? id,
    String? title,
    String? chapterTitle,
    String? url,
    String? image,
    String? type,
    DateTime? time,
    DateTime? createdAt,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      title: title ?? this.title,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      url: url ?? this.url,
      image: image ?? this.image,
      type: type ?? this.type,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
