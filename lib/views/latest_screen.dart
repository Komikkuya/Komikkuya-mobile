import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../controllers/latest_controller.dart';
import '../widgets/manga_list_tile.dart';
import 'manga_detail_screen.dart';

/// Latest screen with Webtoon/Crunchyroll-style tabbed layout
class LatestScreen extends StatefulWidget {
  const LatestScreen({super.key});

  @override
  State<LatestScreen> createState() => _LatestScreenState();
}

class _LatestScreenState extends State<LatestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LatestController.categories.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LatestController>().initialize();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final controller = context.read<LatestController>();
    final category = LatestController.categories[_tabController.index];
    controller.setCategory(category);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<LatestController>().loadMore();
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
    return Consumer<LatestController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            // Tab bar
            _buildTabBar(controller),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                color: AppTheme.accentPurple,
                backgroundColor: AppTheme.surfaceBlack,
                child: _buildContent(controller),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(LatestController controller) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlack,
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.accentPurple,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppTheme.textWhite,
        unselectedLabelColor: AppTheme.textGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        tabs: LatestController.categories.map((cat) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(cat), size: 18),
                const SizedBox(width: 6),
                Text(controller.getCategoryLabel(cat)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'manga':
        return Icons.auto_stories;
      case 'manhwa':
        return Icons.menu_book;
      case 'manhua':
        return Icons.book;
      default:
        return Icons.library_books;
    }
  }

  Widget _buildContent(LatestController controller) {
    if (controller.isLoading && controller.mangaList.isEmpty) {
      return const _LatestListShimmer();
    }

    if (controller.hasError && controller.mangaList.isEmpty) {
      return _buildErrorWidget(controller);
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount:
          controller.mangaList.length + (controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= controller.mangaList.length) {
          return const Padding(
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.accentPurple),
            ),
          );
        }

        final manga = controller.mangaList[index];
        return MangaListTile(
          manga: manga,
          onTap: () =>
              _navigateToDetail(manga.url, manga.title, manga.imageUrl),
        );
      },
    );
  }

  Widget _buildErrorWidget(LatestController controller) {
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

/// Shimmer loading for list
class _LatestListShimmer extends StatelessWidget {
  const _LatestListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: 6,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppTheme.spacingM),
        child: ListShimmer(),
      ),
    );
  }
}

/// List shimmer placeholder
class ListShimmer extends StatelessWidget {
  const ListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            width: 85,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlack,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceBlack,
                      borderRadius: BorderRadius.circular(4),
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
}
