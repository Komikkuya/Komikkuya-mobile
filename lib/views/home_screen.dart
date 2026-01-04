import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../controllers/home_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/genres_controller.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/horizontal_manga_list.dart';
import '../widgets/genre_chips.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer_loading.dart';
import 'manga_detail_screen.dart';

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
