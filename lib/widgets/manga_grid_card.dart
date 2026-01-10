import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/manga_model.dart';
import 'retry_network_image.dart';

/// Grid card widget for Popular screen with rank badge
class MangaGridCard extends StatelessWidget {
  final Manga manga;
  final int? rank;
  final VoidCallback? onTap;

  const MangaGridCard({super.key, required this.manga, this.rank, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              RetryNetworkImage(imageUrl: manga.imageUrl, fit: BoxFit.cover),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha(180),
                      Colors.black.withAlpha(230),
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),

              // Rank badge (top left)
              if (rank != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getRankGradient(rank!),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getRankGradient(rank!).first.withAlpha(100),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '#$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

              // Type badge (top right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(manga.type),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    manga.type.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Content overlay (bottom)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      manga.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Stats row
                    Row(
                      children: [
                        if (manga.stats?.views != null) ...[
                          Icon(
                            Icons.remove_red_eye,
                            color: Colors.white.withAlpha(180),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              manga.stats!.views,
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return [AppTheme.accentPurple, AppTheme.accentPurple.withAlpha(180)];
    }
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
