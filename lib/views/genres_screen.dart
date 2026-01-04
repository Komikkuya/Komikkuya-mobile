import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../controllers/genres_controller.dart';
import '../widgets/manga_grid_card.dart';
import '../widgets/shimmer_loading.dart';
import 'manga_detail_screen.dart';

/// Genres screen with filterable genre chips and manga grid
class GenresScreen extends StatefulWidget {
  final String? initialGenre;

  const GenresScreen({super.key, this.initialGenre});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<GenresController>();
      if (widget.initialGenre != null) {
        controller.setGenre(widget.initialGenre!);
      } else {
        controller.initialize();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<GenresController>().loadMore();
    }
  }

  void _navigateToDetail(String url, String title, String imageUrl) {
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
    return Consumer<GenresController>(
      builder: (context, controller, child) {
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
              // Genre chips section
              SliverToBoxAdapter(child: _buildGenreChips(controller)),

              // Category filter
              SliverToBoxAdapter(child: _buildCategoryFilter(controller)),

              // Content
              if (controller.isLoadingGenres)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXL),
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ),
                )
              else if (controller.isLoading && controller.mangaList.isEmpty)
                const SliverToBoxAdapter(child: _GenresGridShimmer())
              else if (controller.hasError && controller.mangaList.isEmpty)
                SliverToBoxAdapter(child: _buildErrorWidget(controller))
              else if (controller.mangaList.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyWidget(controller))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: AppTheme.spacingM,
                          mainAxisSpacing: AppTheme.spacingM,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final manga = controller.mangaList[index];
                      return MangaGridCard(
                        manga: manga,
                        rank: index + 1,
                        onTap: () => _navigateToDetail(
                          manga.url,
                          manga.title,
                          manga.imageUrl,
                        ),
                      );
                    }, childCount: controller.mangaList.length),
                  ),
                ),

              // Loading more indicator
              if (controller.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accentPurple,
                      ),
                    ),
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingXL),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenreChips(GenresController controller) {
    if (controller.genres.isEmpty && !controller.isLoadingGenres) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingS,
          ),
          child: Text(
            'Genres',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
            itemCount: controller.genres.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingS),
            itemBuilder: (context, index) {
              final genre = controller.genres[index];
              final isSelected = controller.selectedGenre == genre;
              return _GenreChip(
                label: controller.formatGenre(genre),
                isSelected: isSelected,
                onTap: () => controller.setGenre(genre),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(GenresController controller) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GenresController.categories.map((cat) {
                final isSelected = controller.category == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _CategoryChip(
                    label: controller.getCategoryLabel(cat),
                    isSelected: isSelected,
                    onTap: () => controller.setCategory(cat),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(GenresController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentPurple,
              size: 64,
            ),
            const SizedBox(height: AppTheme.spacingL),
            const Text(
              'Failed to load',
              style: TextStyle(
                color: AppTheme.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              controller.error ?? 'Please try again',
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton.icon(
              onPressed: controller.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(GenresController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category, color: AppTheme.textGrey, size: 64),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              controller.selectedGenre != null
                  ? 'No manga found for "${controller.formatGenre(controller.selectedGenre!)}"'
                  : 'Select a genre to browse',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Genre chip widget
class _GenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.accentPurple,
                    AppTheme.accentPurple.withAlpha(180),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.accentPurple : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textGreyLight,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Category chip widget
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple : AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.accentPurple : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textGreyLight,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for grid
class _GenresGridShimmer extends StatelessWidget {
  const _GenresGridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: AppTheme.spacingM,
          mainAxisSpacing: AppTheme.spacingM,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const MangaCardShimmer(),
      ),
    );
  }
}
