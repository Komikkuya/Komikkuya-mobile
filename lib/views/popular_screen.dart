import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../controllers/popular_controller.dart';
import '../widgets/manga_grid_card.dart';
import '../widgets/shimmer_loading.dart';
import 'manga_detail_screen.dart';

/// Popular screen with Netflix/Crunchyroll-style grid layout
class PopularScreen extends StatefulWidget {
  const PopularScreen({super.key});

  @override
  State<PopularScreen> createState() => _PopularScreenState();
}

class _PopularScreenState extends State<PopularScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PopularController>().initialize();
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
      context.read<PopularController>().loadMore();
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
    return Consumer<PopularController>(
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
              // Filter section
              SliverToBoxAdapter(child: _buildFilterSection(controller)),

              // Content
              if (controller.isLoading && controller.mangaList.isEmpty)
                const SliverToBoxAdapter(child: _PopularGridShimmer())
              else if (controller.hasError && controller.mangaList.isEmpty)
                SliverToBoxAdapter(child: _buildErrorWidget(controller))
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

  Widget _buildFilterSection(PopularController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sort time chips
          const Text(
            'Time Period',
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
              children: PopularSortTime.values.map((sortTime) {
                final isSelected = controller.sortTime == sortTime;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _FilterChip(
                    icon: sortTime.icon,
                    label: sortTime.label,
                    isSelected: isSelected,
                    onTap: () => controller.setSortTime(sortTime),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Category chips
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
              children: MangaCategory.values.map((category) {
                final isSelected = controller.category == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: _FilterChip(
                    label: category.label,
                    isSelected: isSelected,
                    onTap: () => controller.setCategory(category),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(PopularController controller) {
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
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    this.icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textGrey,
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textGreyLight,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading for grid
class _PopularGridShimmer extends StatelessWidget {
  const _PopularGridShimmer();

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
