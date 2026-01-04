import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';

/// Shimmer loading placeholder for hero carousel
class HeroShimmer extends StatelessWidget {
  const HeroShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBlack,
      highlightColor: AppTheme.surfaceBlack,
      child: Container(
        height: AppTheme.heroHeight,
        width: double.infinity,
        color: AppTheme.cardBlack,
      ),
    );
  }
}

/// Shimmer loading placeholder for manga card
class MangaCardShimmer extends StatelessWidget {
  const MangaCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBlack,
      highlightColor: AppTheme.surfaceBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.mangaCardWidth,
            height: AppTheme.mangaCardHeight,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Container(
            width: AppTheme.mangaCardWidth * 0.8,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Container(
            width: AppTheme.mangaCardWidth * 0.5,
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder for horizontal manga list
class HorizontalListShimmer extends StatelessWidget {
  const HorizontalListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header shimmer
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingM,
          ),
          child: Shimmer.fromColors(
            baseColor: AppTheme.cardBlack,
            highlightColor: AppTheme.surfaceBlack,
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
          ),
        ),
        // Cards shimmer
        SizedBox(
          height: AppTheme.mangaCardHeight + 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            itemCount: 5,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingM),
            itemBuilder: (_, __) => const MangaCardShimmer(),
          ),
        ),
      ],
    );
  }
}

/// Shimmer loading placeholder for genre chips
class GenreChipsShimmer extends StatelessWidget {
  const GenreChipsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingS),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppTheme.cardBlack,
          highlightColor: AppTheme.surfaceBlack,
          child: Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        ),
      ),
    );
  }
}
