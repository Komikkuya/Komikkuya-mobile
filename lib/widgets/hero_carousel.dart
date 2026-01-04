import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/custom_manga_model.dart';
import 'shimmer_loading.dart';

/// Netflix-style hero carousel for featured manga
class HeroCarousel extends StatefulWidget {
  final List<CustomManga> mangaList;
  final bool isLoading;
  final Function(CustomManga)? onMangaTap;

  const HeroCarousel({
    super.key,
    required this.mangaList,
    this.isLoading = false,
    this.onMangaTap,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const HeroShimmer();
    }

    if (widget.mangaList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Carousel
        CarouselSlider.builder(
          carouselController: _carouselController,
          itemCount: widget.mangaList.length,
          options: CarouselOptions(
            height: AppTheme.heroHeight,
            viewportFraction: 1.0,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          itemBuilder: (context, index, realIndex) {
            final manga = widget.mangaList[index];
            return GestureDetector(
              onTap: widget.onMangaTap != null
                  ? () => widget.onMangaTap!(manga)
                  : null,
              child: _buildHeroItem(manga),
            );
          },
        ),
        // Bottom gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          ),
        ),
        // Content overlay
        Positioned(
          bottom: 60,
          left: AppTheme.spacingL,
          right: AppTheme.spacingL,
          child: _buildContentOverlay(widget.mangaList[_currentIndex]),
        ),
        // Indicator dots
        Positioned(bottom: 20, left: 0, right: 0, child: _buildIndicators()),
      ],
    );
  }

  Widget _buildHeroItem(CustomManga manga) {
    return CachedNetworkImage(
      imageUrl: manga.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: AppTheme.heroHeight,
      placeholder: (context, url) => Container(
        color: AppTheme.cardBlack,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPurple),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppTheme.cardBlack,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppTheme.textGrey,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildContentOverlay(CustomManga manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hot badge and genre
        Row(
          children: [
            if (manga.isHot)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.9),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                manga.genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Title
        Text(
          manga.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingS),
        // Description
        Text(
          manga.tentang,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.4,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black)],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Action buttons
        Row(
          children: [
            // Play/Read button
            ElevatedButton.icon(
              onPressed: widget.onMangaTap != null
                  ? () => widget.onMangaTap!(manga)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                'Read Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            // Info button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            // Bookmark button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_outline, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.mangaList.asMap().entries.map((entry) {
        final isActive = entry.key == _currentIndex;
        return GestureDetector(
          onTap: () => _carouselController.animateToPage(entry.key),
          child: AnimatedContainer(
            duration: AppTheme.animationFast,
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isActive
                  ? AppTheme.accentPurple
                  : Colors.white.withOpacity(0.4),
            ),
          ),
        );
      }).toList(),
    );
  }
}
