import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/manga_model.dart';

/// List tile widget for Latest screen with compact design
class MangaListTile extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onTap;

  const MangaListTile({super.key, required this.manga, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNew = _isNewUpdate(manga.stats?.timeAgo);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: manga.imageUrl,
                    width: 85,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 85,
                      height: 120,
                      color: AppTheme.surfaceBlack,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentPurple,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 85,
                      height: 120,
                      color: AppTheme.surfaceBlack,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                  // Type badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(manga.type),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        manga.type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title row with NEW badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            manga.title,
                            style: const TextStyle(
                              color: AppTheme.textWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNew)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Genre
                    if (manga.genre.isNotEmpty)
                      Text(
                        manga.genre,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Latest chapter + time
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book,
                          color: AppTheme.accentPurple,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            manga.latestChapter?.title ?? 'No chapters',
                            style: const TextStyle(
                              color: AppTheme.textGreyLight,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Time ago
                    if (manga.stats?.timeAgo != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppTheme.textGrey,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            manga.stats!.timeAgo,
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Chevron
            const Padding(
              padding: EdgeInsets.only(right: AppTheme.spacingM),
              child: Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  bool _isNewUpdate(String? timeAgo) {
    if (timeAgo == null) return false;
    final lower = timeAgo.toLowerCase();
    return lower.contains('menit') ||
        lower.contains('jam') ||
        lower.contains('minute') ||
        lower.contains('hour') ||
        lower.contains('just');
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return const Color(0xFF2196F3);
      case 'manhwa':
        return const Color(0xFF4CAF50);
      case 'manhua':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.accentPurple;
    }
  }
}
