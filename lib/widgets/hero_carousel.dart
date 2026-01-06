import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/custom_manga_model.dart';
import '../controllers/favorites_controller.dart';
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

class _HeroCarouselState extends State<HeroCarousel>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  late AnimationController _progressController;
  static const int _slideDurationSeconds = 5;

  @override
  void initState() {
    super.initState();
    _progressController =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: _slideDurationSeconds),
        )..addListener(() {
          setState(() {});
        });
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  /// Toggle favorite status for hero manga
  Future<void> _toggleFavorite(CustomManga manga) async {
    final favController = context.read<FavoritesController>();

    // Detect source from URL
    String source = 'westmanga';
    if (manga.url.contains('komiku.org')) {
      source = 'komiku';
    } else if (manga.url.contains('weebcentral.com')) {
      source = 'international';
    } else if (manga.url.contains('westmanga')) {
      source = 'westmanga';
    }

    await favController.toggleFavorite(
      id: manga.url,
      slug: manga.url,
      title: manga.title,
      url: manga.url,
      cover: manga.imageUrl,
      type: 'manga',
      source: source,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const HeroShimmer();
    }

    if (widget.mangaList.isEmpty) {
      return const SizedBox.shrink();
    }

    // Watch favorites to rebuild on any change
    final favController = context.watch<FavoritesController>();
    final currentManga = widget.mangaList[_currentIndex];
    final isFav = favController.isFavorited(currentManga.url);

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
            autoPlayInterval: const Duration(seconds: _slideDurationSeconds),
            autoPlayAnimationDuration: const Duration(milliseconds: 1200),
            autoPlayCurve: Curves.easeInOutQuart,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
                _progressController.reset();
                _progressController.forward();
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
            height: 700, // Even smoother fade to black
            decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
          ),
        ),
        // Content overlay
        Positioned(
          bottom: 60,
          left: AppTheme.spacingL,
          right: AppTheme.spacingL,
          child: _buildContentOverlay(currentManga, isFav),
        ),
        // Indicator dots
        Positioned(
          bottom: 20,
          left: AppTheme.spacingL,
          right: AppTheme.spacingL,
          child: _buildIndicators(),
        ),
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

  Widget _buildContentOverlay(CustomManga manga, bool isFav) {
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
                      'REKOMENDASI ADMIN',
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
            Expanded(
              flex: 4,
              child: ElevatedButton.icon(
                onPressed: widget.onMangaTap != null
                    ? () => widget.onMangaTap!(manga)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow, size: 28),
                label: Text(
                  'READ NOW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Favorite button (Bookmark style ala Crunchyroll)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFav
                      ? AppTheme.accentPurple
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                color: isFav
                    ? AppTheme.accentPurple.withOpacity(0.15)
                    : Colors.white.withOpacity(0.05),
              ),
              child: IconButton(
                onPressed: () => _toggleFavorite(manga),
                icon: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_outline,
                  color: isFav ? AppTheme.accentPurple : Colors.white,
                  size: 28,
                ),
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
        final isPassed = entry.key < _currentIndex;

        return Expanded(
          child: GestureDetector(
            onTap: () => _carouselController.animateToPage(entry.key),
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.white.withOpacity(0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: isActive
                      ? _progressController.value
                      : (isPassed ? 1.0 : 0.0),
                  child: Container(color: AppTheme.accentPurple),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
