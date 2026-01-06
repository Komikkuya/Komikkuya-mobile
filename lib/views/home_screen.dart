import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../controllers/home_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/genres_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/favorites_controller.dart';
import '../models/history_model.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/horizontal_manga_list.dart';
import '../widgets/genre_chips.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loading.dart';
import 'manga_detail_screen.dart';
import 'chapter_reader_screen.dart';

/// Main home screen with Netflix/Crunchyroll style layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    // Load data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().initialize();
      // Load history for Continue Reading widget
      context.read<HistoryController>().loadHistory(limit: 1);
      // Load favorites to sync status app-wide
      context.read<FavoritesController>().loadFavorites();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      context.read<NavigationController>().setHomeScrollOffset(
        _scrollController.offset,
      );
    }
  }

  /// Navigate to manga detail screen
  void _navigateToMangaDetail({
    required String url,
    required String title,
    required String imageUrl,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MangaDetailScreen(
              mangaUrl: ApiConfig.cleanUrl(url),
              heroTag: title,
              coverImage: imageUrl,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        // Show full-screen error only if ALL data failed to load
        if (controller.hasError && !controller.isLoading) {
          return _buildErrorScreen(controller);
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.accentPurple,
          backgroundColor: AppTheme.surfaceBlack,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child:
                    controller.isLoadingCustom && controller.customManga.isEmpty
                    ? const HeroShimmer()
                    : HeroCarousel(
                        mangaList: controller.customManga,
                        isLoading: false,
                        onMangaTap: (manga) {
                          _navigateToMangaDetail(
                            url: manga.url,
                            title: manga.title,
                            imageUrl: manga.imageUrl,
                          );
                        },
                      ),
              ),

              // Continue Reading Section
              Consumer<HistoryController>(
                builder: (context, historyController, child) {
                  if (historyController.history.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: _buildContinueReading(
                      historyController.history.first,
                    ),
                  );
                },
              ),

              // Genres Section (only show if we have genres or still loading)
              if (controller.isLoadingGenres || controller.genres.isNotEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppTheme.spacingL),
                      const SectionHeader(
                        title: 'Browse by Genre',
                        icon: Icons.category_outlined,
                      ),
                      GenreChips(
                        genres: controller.genres.take(15).toList(),
                        isLoading: controller.isLoadingGenres,
                        onGenreTap: (genre) {
                          // Set genre in GenresController
                          context.read<GenresController>().setGenre(genre);
                          // Navigate to Genres tab (index 2)
                          context.read<NavigationController>().setIndex(2);
                        },
                      ),
                    ],
                  ),
                ),

              // Hot Manga Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingL),
                  child: HorizontalMangaList(
                    title: 'Hot & Trending 🔥',
                    mangaList: controller.hotManga,
                    isLoading: controller.isLoadingHot,
                    icon: Icons.local_fire_department,
                    onMangaTap: (manga) {
                      _navigateToMangaDetail(
                        url: manga.url,
                        title: manga.title,
                        imageUrl: manga.imageUrl,
                      );
                    },
                  ),
                ),
              ),

              // Latest Manga Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingM),
                  child: HorizontalMangaList(
                    title: 'Latest Manga',
                    mangaList: controller.latestManga,
                    isLoading: controller.isLoadingLatest,
                    icon: Icons.auto_stories,
                    onMangaTap: (manga) {
                      _navigateToMangaDetail(
                        url: manga.url,
                        title: manga.title,
                        imageUrl: manga.imageUrl,
                      );
                    },
                  ),
                ),
              ),

              // Latest Manhwa Section
              if (controller.isLoadingLatest ||
                  controller.latestManhwa.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: HorizontalMangaList(
                      title: 'Latest Manhwa',
                      mangaList: controller.latestManhwa,
                      isLoading:
                          controller.isLoadingLatest &&
                          controller.latestManhwa.isEmpty,
                      icon: Icons.menu_book,
                      onMangaTap: (manga) {
                        _navigateToMangaDetail(
                          url: manga.url,
                          title: manga.title,
                          imageUrl: manga.imageUrl,
                        );
                      },
                    ),
                  ),
                ),

              // Latest Manhua Section
              if (controller.isLoadingLatest ||
                  controller.latestManhua.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: HorizontalMangaList(
                      title: 'Latest Manhua',
                      mangaList: controller.latestManhua,
                      isLoading:
                          controller.isLoadingLatest &&
                          controller.latestManhua.isEmpty,
                      icon: Icons.book,
                      onMangaTap: (manga) {
                        _navigateToMangaDetail(
                          url: manga.url,
                          title: manga.title,
                          imageUrl: manga.imageUrl,
                        );
                      },
                    ),
                  ),
                ),

              // Popular Daily Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spacingM),
                  child: HorizontalMangaList(
                    title: 'Popular Today',
                    mangaList: controller.popularDaily,
                    isLoading: controller.isLoadingPopular,
                    icon: Icons.trending_up,
                    onMangaTap: (manga) {
                      _navigateToMangaDetail(
                        url: manga.url,
                        title: manga.title,
                        imageUrl: manga.imageUrl,
                      );
                    },
                  ),
                ),
              ),

              // Popular Weekly Section
              if (controller.isLoadingPopular ||
                  controller.popularWeekly.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: HorizontalMangaList(
                      title: 'Popular This Week',
                      mangaList: controller.popularWeekly,
                      isLoading:
                          controller.isLoadingPopular &&
                          controller.popularWeekly.isEmpty,
                      icon: Icons.calendar_view_week,
                      onMangaTap: (manga) {
                        _navigateToMangaDetail(
                          url: manga.url,
                          title: manga.title,
                          imageUrl: manga.imageUrl,
                        );
                      },
                    ),
                  ),
                ),

              // Popular All Time Section
              if (controller.isLoadingPopular ||
                  controller.popularAllTime.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacingM),
                    child: HorizontalMangaList(
                      title: 'All Time Favorites',
                      mangaList: controller.popularAllTime,
                      isLoading:
                          controller.isLoadingPopular &&
                          controller.popularAllTime.isEmpty,
                      icon: Icons.star,
                      onMangaTap: (manga) {
                        _navigateToMangaDetail(
                          url: manga.url,
                          title: manga.title,
                          imageUrl: manga.imageUrl,
                        );
                      },
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingXXL),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToReading(HistoryItem item) {
    // Reconstruct full URL from relative history path
    String fullUrl = item.url;

    if (item.url.startsWith('/chapter/')) {
      final path = item.url.replaceFirst('/chapter/', '/');

      if (path.contains('/view/')) {
        // Westmanga
        fullUrl = 'https://westmanga.me$path';
      } else if (path.contains('/chapters/')) {
        // Weebcentral
        fullUrl = 'https://weebcentral.com$path';
      } else {
        // Komiku
        fullUrl = 'https://komiku.org$path';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterReaderScreen(
          chapterUrl: fullUrl,
          mangaTitle: item.title,
          coverImage: item.image,
        ),
      ),
    );
  }

  Widget _buildContinueReading(HistoryItem item) {
    final timeAgo = _formatTimeAgo(item.time);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingL,
        AppTheme.spacingM,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Continue Reading',
            icon: Icons.play_circle_outline,
          ),
          const SizedBox(height: AppTheme.spacingS),
          GestureDetector(
            onTap: () => _navigateToReading(item),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withAlpha(40),
                    AppTheme.cardBlack,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentPurple.withAlpha(60)),
              ),
              child: Row(
                children: [
                  // Cover image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: SizedBox(
                      width: 80,
                      height: 100,
                      child: item.image != null
                          ? CachedNetworkImage(
                              imageUrl: item.image!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppTheme.surfaceBlack,
                                child: const Icon(
                                  Icons.book,
                                  color: AppTheme.accentPurple,
                                  size: 32,
                                ),
                              ),
                            )
                          : Container(
                              color: AppTheme.surfaceBlack,
                              child: const Icon(
                                Icons.book,
                                color: AppTheme.accentPurple,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.chapterTitle} • $timeAgo',
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _buildErrorScreen(HomeController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.accentPurple, size: 80),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Failed to Load',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              controller.error ??
                  'Please check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: controller.loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
