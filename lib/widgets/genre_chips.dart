import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'shimmer_loading.dart';

/// Horizontal scrolling genre chips
class GenreChips extends StatelessWidget {
  final List<String> genres;
  final bool isLoading;
  final String? selectedGenre;
  final Function(String)? onGenreTap;

  const GenreChips({
    super.key,
    required this.genres,
    this.isLoading = false,
    this.selectedGenre,
    this.onGenreTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const GenreChipsShimmer();
    }

    if (genres.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        physics: const BouncingScrollPhysics(),
        itemCount: genres.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingS),
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = genre == selectedGenre;

          return GestureDetector(
            onTap: onGenreTap != null ? () => onGenreTap!(genre) : null,
            child: AnimatedContainer(
              duration: AppTheme.animationFast,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentPurple : AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentPurple
                      : AppTheme.dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                _formatGenreName(genre),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textGreyLight,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatGenreName(String genre) {
    // Convert kebab-case to Title Case
    return genre
        .split('-')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}
