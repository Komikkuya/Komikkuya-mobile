import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../config/app_theme.dart';
import '../models/manga_model.dart';
import 'section_header.dart';
import 'manga_card.dart';
import 'shimmer_loading.dart';

/// Horizontal scrolling manga list with section header
class HorizontalMangaList extends StatelessWidget {
  final String title;
  final List<Manga> mangaList;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final Function(Manga)? onMangaTap;
  final IconData? icon;

  const HorizontalMangaList({
    super.key,
    required this.title,
    required this.mangaList,
    this.isLoading = false,
    this.onSeeAll,
    this.onMangaTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const HorizontalListShimmer();
    }

    if (mangaList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAll: onSeeAll, icon: icon),
        SizedBox(
          height: AppTheme.mangaCardHeight + 70,
          child: AnimationLimiter(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingL,
              ),
              physics: const BouncingScrollPhysics(),
              itemCount: mangaList.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spacingM),
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: AppTheme.animationNormal,
                  child: SlideAnimation(
                    horizontalOffset: 50.0,
                    child: FadeInAnimation(
                      child: MangaCard(
                        manga: mangaList[index],
                        onTap: onMangaTap != null
                            ? () => onMangaTap!(mangaList[index])
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
