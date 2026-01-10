import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import '../config/app_theme.dart';
import '../controllers/favorites_controller.dart';
import '../models/favorite_model.dart';
import 'manga_detail_screen.dart';
import 'doujin_detail_screen.dart';

/// Premium favorites screen with Netflix/Crunchyroll style
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesController>().loadFavorites();
    });
  }

  Future<void> _navigateToDetail(FavoriteItem item) async {
    // Check if this is a doujin type
    final type = item.type?.toLowerCase() ?? '';

    if (type == 'doujin') {
      // Navigate to DoujinDetailScreen
      String doujinUrl;
      if (item.url != null &&
          item.url!.isNotEmpty &&
          item.url!.startsWith('http')) {
        doujinUrl = item.url!;
      } else {
        // Reconstruct URL from slug
        doujinUrl = 'https://komikdewasa.id/komik/${item.slug}';
      }

      debugPrint('FavoritesScreen._navigateToDetail: Doujin - $doujinUrl');

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoujinDetailScreen(doujinUrl: doujinUrl),
        ),
      );
      return;
    }

    // Regular manga navigation
    String navUrl;
    final source = item.source?.toLowerCase() ?? '';

    if (item.url != null &&
        item.url!.isNotEmpty &&
        item.url!.startsWith('http')) {
      navUrl = item.url!;
    } else if (source == 'komiku') {
      navUrl = 'https://komiku.org/manga/${item.slug}/';
    } else if (source == 'westmanga') {
      navUrl = 'https://westmanga.me/comic/${item.slug}/';
    } else if (source == 'international' || source == 'weebcentral') {
      navUrl = 'https://weebcentral.com/series/${item.slug}';
    } else {
      navUrl = await _findWorkingUrl(item.slug);
    }

    debugPrint('FavoritesScreen._navigateToDetail: id=${item.id}');
    debugPrint('FavoritesScreen._navigateToDetail: slug=${item.slug}');
    debugPrint('FavoritesScreen._navigateToDetail: url=${item.url}');
    debugPrint('FavoritesScreen._navigateToDetail: source=${item.source}');
    debugPrint('FavoritesScreen._navigateToDetail: navUrl=$navUrl');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MangaDetailScreen(mangaUrl: navUrl, coverImage: item.cover),
      ),
    );
  }

  /// Try each source URL until one works
  Future<String> _findWorkingUrl(String slug) async {
    final urls = [
      'https://komiku.org/manga/$slug/',
      'https://westmanga.me/comic/$slug/',
      'https://weebcentral.com/series/$slug/',
    ];

    for (final url in urls) {
      try {
        debugPrint('FavoritesScreen._findWorkingUrl: Trying $url');
        final response = await http
            .head(Uri.parse(url))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200 ||
            response.statusCode == 301 ||
            response.statusCode == 302) {
          debugPrint('FavoritesScreen._findWorkingUrl: Found working URL $url');
          return url;
        }
      } catch (e) {
        debugPrint('FavoritesScreen._findWorkingUrl: Failed $url - $e');
      }
    }

    // Default fallback
    debugPrint(
      'FavoritesScreen._findWorkingUrl: No working URL found, using komiku',
    );
    return urls.first;
  }

  Future<void> _removeFavorite(FavoriteItem item) async {
    final controller = context.read<FavoritesController>();
    final success = await controller.removeFavorite(item.id);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Removed "${item.title}"',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppTheme.accentPurple,
            onPressed: () {
              controller.addFavorite(
                id: item.id,
                slug: item.slug,
                title: item.title,
                cover: item.cover,
                type: item.type,
                source: item.source,
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.favorites.isEmpty) {
          return _buildLoadingState();
        }

        if (controller.favorites.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadFavorites,
          color: AppTheme.accentPurple,
          backgroundColor: AppTheme.surfaceBlack,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Stats header
              SliverToBoxAdapter(child: _buildStatsHeader(controller)),
              // Grid of favorites
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = controller.favorites[index];
                    return _buildFavoriteCard(item, index);
                  }, childCount: controller.favorites.length),
                ),
              ),
              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(FavoritesController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPurple.withAlpha(40),
            AppTheme.accentPurple.withAlpha(15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentPurple.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite,
              color: AppTheme.accentPurple,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.count} Manga',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'in your collection',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          // Sort button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.sort, color: AppTheme.textGrey),
              tooltip: 'Sort',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover image
              item.cover != null
                  ? CachedNetworkImage(
                      imageUrl: item.cover!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppTheme.cardBlack,
                        child: Shimmer.fromColors(
                          baseColor: AppTheme.cardBlack,
                          highlightColor: AppTheme.surfaceBlack,
                          child: Container(color: Colors.white),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.cardBlack,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: AppTheme.textGrey,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.cardBlack,
                      child: Center(
                        child: Icon(
                          Icons.menu_book,
                          color: AppTheme.textGrey.withAlpha(100),
                          size: 50,
                        ),
                      ),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                      Colors.black.withAlpha(240),
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),
              // Top actions
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showRemoveDialog(item),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(180),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(100),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Type badge
              if (item.type != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(item.type!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _getTypeColor(item.type!).withAlpha(100),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      item.type!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              // Bottom content
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Source tag
                    if (item.source != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.source!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withAlpha(200),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return const Color(0xFFE91E63);
      case 'manhwa':
        return const Color(0xFF2196F3);
      case 'manhua':
        return const Color(0xFFFF9800);
      default:
        return AppTheme.accentPurple;
    }
  }

  void _showRemoveDialog(FavoriteItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Remove Favorite',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Remove "${item.title}" from your favorites?',
          style: const TextStyle(color: AppTheme.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textGrey.withAlpha(180)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFavorite(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated heart icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withAlpha(40),
                    AppTheme.accentPurple.withAlpha(20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withAlpha(30),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 60,
                color: AppTheme.accentPurple,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your collection!\nTap the heart icon on any manga\nto add it to your favorites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textGrey.withAlpha(180),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // CTA Button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple,
                    AppTheme.accentPurple.withAlpha(180),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPurple.withAlpha(60),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Could navigate to home or popular
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Explore Manga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // Stats header shimmer
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: AppTheme.cardBlack,
              highlightColor: AppTheme.surfaceBlack,
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        // Grid shimmer
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              return Shimmer.fromColors(
                baseColor: AppTheme.cardBlack,
                highlightColor: AppTheme.surfaceBlack,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            }, childCount: 6),
          ),
        ),
      ],
    );
  }
}
