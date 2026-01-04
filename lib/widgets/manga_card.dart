import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/manga_model.dart';

/// Netflix/Crunchyroll style manga poster card
class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const MangaCard({
    super.key,
    required this.manga,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? AppTheme.mangaCardWidth;
    final cardHeight = height ?? AppTheme.mangaCardHeight;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image container
            Stack(
              children: [
                // Poster image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: CachedNetworkImage(
                    imageUrl: manga.imageUrl,
                    width: cardWidth,
                    height: cardHeight,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: cardWidth,
                      height: cardHeight,
                      color: AppTheme.cardBlack,
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accentPurple,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: cardWidth,
                      height: cardHeight,
                      color: AppTheme.cardBlack,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textGrey,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                // Type badge (Manga, Manhwa, Manhua)
                if (manga.type.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(manga.type),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        manga.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Update status badge
                if (manga.updateStatus != null &&
                    manga.updateStatus!.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPurple,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      child: Text(
                        manga.updateStatus!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.radiusMedium),
                        bottomRight: Radius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                // Chapter info at bottom
                if (manga.latestChapter != null &&
                    manga.latestChapter!.title.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      manga.latestChapter!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingS),
            // Title - constrained to 2 lines max
            SizedBox(
              height: 36, // Fixed height for 2 lines of text
              child: Text(
                manga.title,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Genre
            Text(
              manga.genre,
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return const Color(0xFF2196F3); // Blue
      case 'manhwa':
        return const Color(0xFF4CAF50); // Green
      case 'manhua':
        return const Color(0xFFFF9800); // Orange
      default:
        return AppTheme.accentPurple;
    }
  }
}
