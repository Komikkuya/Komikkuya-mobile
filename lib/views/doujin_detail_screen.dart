import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_theme.dart';
import '../controllers/doujin_controller.dart';
import '../controllers/favorites_controller.dart';
import '../models/doujin_model.dart';
import '../widgets/retry_network_image.dart';
import 'doujin_reader_screen.dart';

/// Doujin Detail Screen - Netflix/Webtoon/Crunchyroll inspired design
class DoujinDetailScreen extends StatefulWidget {
  final String doujinUrl;

  const DoujinDetailScreen({super.key, required this.doujinUrl});

  @override
  State<DoujinDetailScreen> createState() => _DoujinDetailScreenState();
}

class _DoujinDetailScreenState extends State<DoujinDetailScreen> {
  final DoujinController _controller = DoujinController();
  bool _isDescriptionExpanded = false;
  bool _isChapterReversed = false;

  @override
  void initState() {
    super.initState();
    _controller.fetchDetail(widget.doujinUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChapterTap(DoujinChapter chapter) {
    Navigator.push(
      context,
      PageRouteBuilder(
        settings: const RouteSettings(name: 'doujin_reader'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DoujinReaderScreen(
              chapterUrl: chapter.url,
              mangaTitle: _controller.detail?.title,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _startReading() {
    final detail = _controller.detail;
    if (detail != null && detail.chapters.isNotEmpty) {
      _onChapterTap(
        detail.chapters.last,
      ); // First chapter (usually last in list)
    }
  }

  void _shareDoujin(DoujinDetail detail) {
    final shareUrl = 'https://www.komikkuya.my.id/doujin/${detail.slug}';
    final message =
        'Check out "${detail.title}" on Komikkuya!\n\nRead here: $shareUrl';
    SharePlus.instance.share(ShareParams(text: message, subject: detail.title));
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Consumer<DoujinController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return _buildLoadingState();
            }

            if (controller.error != null) {
              return _buildErrorState(controller);
            }

            final detail = controller.detail;
            if (detail == null) {
              return _buildErrorState(controller);
            }

            return _buildContent(detail);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // Shimmer header
        SliverToBoxAdapter(
          child: Shimmer.fromColors(
            baseColor: AppTheme.cardBlack,
            highlightColor: AppTheme.surfaceBlack,
            child: Container(height: 400, color: AppTheme.cardBlack),
          ),
        ),
        // Shimmer content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: AppTheme.cardBlack,
                  highlightColor: AppTheme.surfaceBlack,
                  child: Container(
                    height: 30,
                    width: 250,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Shimmer.fromColors(
                  baseColor: AppTheme.cardBlack,
                  highlightColor: AppTheme.surfaceBlack,
                  child: Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBlack,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                ...List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Shimmer.fromColors(
                      baseColor: AppTheme.cardBlack,
                      highlightColor: AppTheme.surfaceBlack,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(DoujinController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentPurple,
              size: 80,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Failed to load content',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              controller.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textWhite,
                    side: const BorderSide(color: AppTheme.textGrey),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: () => controller.fetchDetail(widget.doujinUrl),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DoujinDetail detail) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero header with cover image
        _buildHeroHeader(detail),

        // Content
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusXLarge),
                topRight: Radius.circular(AppTheme.radiusXLarge),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingL),

                // Title and info
                _buildTitleSection(detail),

                // Action buttons
                _buildActionButtons(detail),

                // Stats row
                _buildStatsRow(detail),

                // Genres
                _buildGenresSection(detail),

                // Description
                _buildDescriptionSection(detail),

                // Chapter list header
                _buildChapterListHeader(detail),
              ],
            ),
          ),
        ),

        // Chapter list
        _buildChapterList(detail),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeroHeader(DoujinDetail detail) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppTheme.primaryBlack,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _shareDoujin(detail),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            RetryNetworkImage(
              imageUrl: detail.cover,
              fit: BoxFit.cover,
              httpHeaders: const {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': 'https://komikdewasa.id/',
              },
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
                    AppTheme.primaryBlack.withAlpha(128),
                    AppTheme.primaryBlack,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(DoujinDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            detail.title,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          // Author and type row
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spacingM,
            runSpacing: AppTheme.spacingS,
            children: [
              if (detail.author.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      color: AppTheme.textGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      detail.author,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  detail.type,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: detail.status.toLowerCase() == 'ongoing'
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  detail.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DoujinDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        children: [
          // Read Now button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _startReading,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'Start Reading',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          // Favorite button
          Consumer<FavoritesController>(
            builder: (context, favController, child) {
              final isFav = favController.isFavorited(detail.slug);
              return Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _toggleFavorite(detail, favController, isFav),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isFav ? Colors.red : AppTheme.accentPurple,
                    side: BorderSide(
                      color: isFav ? Colors.red : AppTheme.accentPurple,
                    ),
                    backgroundColor: isFav ? Colors.red.withAlpha(20) : null,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                    ),
                  ),
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isFav ? Colors.red : AppTheme.accentPurple,
                  ),
                  label: Text(isFav ? 'Saved' : 'Save'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(
    DoujinDetail detail,
    FavoritesController favController,
    bool isFavorited,
  ) {
    if (isFavorited) {
      favController.removeFavorite(detail.slug);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          backgroundColor: AppTheme.cardBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      favController.addFavorite(
        id: detail.slug,
        slug: detail.slug,
        title: detail.title,
        url: detail.url,
        cover: detail.cover,
        type: 'doujin',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to favorites'),
          backgroundColor: AppTheme.cardBlack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStatsRow(DoujinDetail detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.menu_book,
              value: '${detail.totalChapters}',
              label: 'Chapters',
            ),
            Container(width: 1, height: 40, color: AppTheme.dividerColor),
            _buildStatItem(
              icon: Icons.update,
              value: detail.lastUpdate.length > 10
                  ? detail.lastUpdate.substring(0, 10)
                  : detail.lastUpdate,
              label: 'Updated',
            ),
            Container(width: 1, height: 40, color: AppTheme.dividerColor),
            _buildStatItem(
              icon: Icons.category,
              value: '${detail.genres.length}',
              label: 'Genres',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGenresSection(DoujinDetail detail) {
    if (detail.genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Wrap(
        spacing: AppTheme.spacingS,
        runSpacing: AppTheme.spacingS,
        children: detail.genres.map((genre) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Text(
              genre,
              style: const TextStyle(
                color: AppTheme.textGreyLight,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDescriptionSection(DoujinDetail detail) {
    if (detail.description.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Synopsis',
            style: TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          GestureDetector(
            onTap: () => setState(
              () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
            child: AnimatedCrossFade(
              firstChild: Text(
                detail.description,
                style: const TextStyle(
                  color: AppTheme.textGreyLight,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                detail.description,
                style: const TextStyle(
                  color: AppTheme.textGreyLight,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              crossFadeState: _isDescriptionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppTheme.animationFast,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          GestureDetector(
            onTap: () => setState(
              () => _isDescriptionExpanded = !_isDescriptionExpanded,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isDescriptionExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(
                    color: AppTheme.accentPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _isDescriptionExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppTheme.accentPurple,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterListHeader(DoujinDetail detail) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chapters (${detail.totalChapters})',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _isChapterReversed = !_isChapterReversed),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isChapterReversed
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: AppTheme.accentPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isChapterReversed ? 'Oldest' : 'Newest',
                    style: const TextStyle(
                      color: AppTheme.textGreyLight,
                      fontSize: 12,
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

  Widget _buildChapterList(DoujinDetail detail) {
    final chapters = _isChapterReversed
        ? detail.chapters.reversed.toList()
        : detail.chapters;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final chapter = chapters[index];
        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingL,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: ListTile(
            onTap: () => _onChapterTap(chapter),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingXS,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentPurple.withAlpha(60),
                    AppTheme.accentPurple.withAlpha(30),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  chapter.number.isNotEmpty ? chapter.number : '${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.accentPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            title: Text(
              chapter.title,
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.accentPurple,
                size: 14,
              ),
            ),
          ),
        );
      }, childCount: chapters.length),
    );
  }
}
