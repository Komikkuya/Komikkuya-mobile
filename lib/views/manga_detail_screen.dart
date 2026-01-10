import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_theme.dart';
import '../controllers/manga_detail_controller.dart';
import '../controllers/genres_controller.dart';
import '../controllers/navigation_controller.dart';
import '../controllers/favorites_controller.dart';
import '../models/manga_detail_model.dart';
import '../models/source_type.dart';
import '../widgets/retry_network_image.dart';
import 'chapter_reader_screen.dart';

/// Manga detail screen with Crunchyroll/Netflix/Webtoon inspired design
class MangaDetailScreen extends StatefulWidget {
  final String mangaUrl;
  final String? heroTag;
  final String? coverImage;

  const MangaDetailScreen({
    super.key,
    required this.mangaUrl,
    this.heroTag,
    this.coverImage,
  });

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  late MangaDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MangaDetailController();
    _controller.loadMangaDetail(widget.mangaUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Navigate to chapter reader
  void _navigateToChapter(ChapterItem chapter) {
    Navigator.push(
      context,
      PageRouteBuilder(
        settings: const RouteSettings(name: 'chapter_reader'),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChapterReaderScreen(
              chapterUrl: chapter.url,
              mangaUrl: widget.mangaUrl,
              mangaTitle: _controller.mangaDetail?.title,
              coverImage:
                  widget.coverImage ?? _controller.mangaDetail?.coverImage,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Start reading from first chapter
  void _startReading() {
    final firstChapter = _controller.mangaDetail?.firstChapter;
    if (firstChapter != null) {
      _navigateToChapter(firstChapter);
    }
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite(MangaDetail manga) async {
    final favController = context.read<FavoritesController>();

    // Detect source from URL
    String source = 'westmanga';
    if (widget.mangaUrl.contains('komiku.org')) {
      source = 'komiku';
    } else if (widget.mangaUrl.contains('weebcentral.com')) {
      source = 'international';
    } else if (widget.mangaUrl.contains('westmanga')) {
      source = 'westmanga';
    }

    await favController.toggleFavorite(
      id: widget.mangaUrl,
      slug: widget.mangaUrl,
      title: manga.title,
      url: widget.mangaUrl,
      cover: manga.coverImage,
      type: manga.type,
      source: source,
    );
  }

  /// Share manga with custom URL format
  void _shareManga(MangaDetail manga) {
    // Target: https://www.komikkuya.my.id/manga/[slug]
    // Or for Weebcentral: https://www.komikkuya.my.id/manga/series/[slug]

    String slug = '';
    final uri = Uri.tryParse(widget.mangaUrl);

    if (uri != null) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (manga.source == MangaSource.international &&
          segments.contains('series')) {
        // Weebcentral: keeps series/[id]
        final idx = segments.indexOf('series');
        if (idx < segments.length - 1) {
          slug = 'series/${segments[idx + 1]}';
        }
      } else if (segments.isNotEmpty) {
        // Others: just the last segment (the slug)
        slug = segments.last;
      }
    }

    final shareUrl = 'https://www.komikkuya.my.id/manga/$slug';
    final message =
        'Check out "${manga.title}" on Komikkuya!\n\nRead here: $shareUrl';

    SharePlus.instance.share(ShareParams(text: message, subject: manga.title));
    debugPrint('MangaDetailScreen: Sharing URL -> $shareUrl');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        body: Consumer<MangaDetailController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return _buildLoadingState();
            }

            if (controller.hasError) {
              return _buildErrorState(controller);
            }

            final manga = controller.mangaDetail;
            if (manga == null) {
              return _buildErrorState(controller);
            }

            return _buildContent(manga, controller);
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

  Widget _buildErrorState(MangaDetailController controller) {
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
              'Failed to load manga',
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
                  onPressed: () => controller.loadMangaDetail(widget.mangaUrl),
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

  Widget _buildContent(MangaDetail manga, MangaDetailController controller) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Hero header with cover image
        _buildHeroHeader(manga),

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
                _buildTitleSection(manga),

                // Action buttons
                _buildActionButtons(manga),

                // Stats row
                _buildStatsRow(manga),

                // Genres
                _buildGenresSection(manga),

                // Description
                _buildDescriptionSection(manga, controller),

                // Chapter list header
                _buildChapterListHeader(manga, controller),
              ],
            ),
          ),
        ),

        // Chapter list
        _buildChapterList(controller),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeroHeader(MangaDetail manga) {
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
            onPressed: () => _shareManga(manga),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            Hero(
              tag: widget.heroTag ?? manga.title,
              child: RetryNetworkImage(
                imageUrl: widget.coverImage ?? manga.coverImage,
                fit: BoxFit.cover,
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

  Widget _buildTitleSection(MangaDetail manga) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            manga.title,
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          if (manga.alternativeTitle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              manga.alternativeTitle,
              style: const TextStyle(
                color: AppTheme.textGrey,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingM),
          // Author and type row
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spacingM,
            runSpacing: AppTheme.spacingS,
            children: [
              if (manga.author.isNotEmpty)
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
                      manga.author,
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
                  color: _getTypeColor(manga.type),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  manga.type,
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
                  color: manga.status.toLowerCase() == 'ongoing'
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  manga.status,
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

  Widget _buildActionButtons(MangaDetail manga) {
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
              final isFav = favController.isFavorited(widget.mangaUrl);
              return Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () => _toggleFavorite(manga),
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

  Widget _buildStatsRow(MangaDetail manga) {
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
              value: '${manga.totalChapters}',
              label: 'Chapters',
            ),
            Container(width: 1, height: 40, color: AppTheme.dividerColor),
            _buildStatItem(
              icon: Icons.remove_red_eye,
              value: _formatNumber(manga.totalReaders),
              label: 'Readers',
            ),
            Container(width: 1, height: 40, color: AppTheme.dividerColor),
            _buildStatItem(
              icon: Icons.category,
              value: '${manga.genres.length}',
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGenresSection(MangaDetail manga) {
    if (manga.genres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Wrap(
        spacing: AppTheme.spacingS,
        runSpacing: AppTheme.spacingS,
        children: manga.genres.map((genre) {
          return GestureDetector(
            onTap: () => _navigateToGenre(genre),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceBlack,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    genre,
                    style: const TextStyle(
                      color: AppTheme.textGreyLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppTheme.textGrey,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Navigate to genres screen with the selected genre
  void _navigateToGenre(String genre) {
    // Convert display genre to slug format (lowercase, replace spaces with dashes)
    final genreSlug = genre.toLowerCase().replaceAll(' ', '-');

    // Set the genre in GenresController
    final genresController = context.read<GenresController>();
    genresController.setGenre(genreSlug);

    // Navigate to Genres tab (index 2) in the main layout
    final navController = context.read<NavigationController>();
    navController.setIndex(2); // Genres tab

    // Pop back to the main layout
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildDescriptionSection(
    MangaDetail manga,
    MangaDetailController controller,
  ) {
    if (manga.description.isEmpty) return const SizedBox.shrink();

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
            onTap: controller.toggleDescription,
            child: AnimatedCrossFade(
              firstChild: Text(
                manga.description,
                style: const TextStyle(
                  color: AppTheme.textGreyLight,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(
                manga.description,
                style: const TextStyle(
                  color: AppTheme.textGreyLight,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              crossFadeState: controller.isDescriptionExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppTheme.animationFast,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          GestureDetector(
            onTap: controller.toggleDescription,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.isDescriptionExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(
                    color: AppTheme.accentPurple,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  controller.isDescriptionExpanded
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

  Widget _buildChapterListHeader(
    MangaDetail manga,
    MangaDetailController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Chapters (${manga.totalChapters})',
            style: const TextStyle(
              color: AppTheme.textWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: controller.toggleChapterOrder,
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
                    controller.isChapterListReversed
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: AppTheme.accentPurple,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.isChapterListReversed ? 'Oldest' : 'Newest',
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

  Widget _buildChapterList(MangaDetailController controller) {
    final chapters = controller.sortedChapters;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final chapter = chapters[index];
        return _buildChapterItem(chapter, index);
      }, childCount: chapters.length),
    );
  }

  Widget _buildChapterItem(ChapterItem chapter, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingXS,
      ),
      child: Material(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: () => _navigateToChapter(chapter),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Chapter number indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: AppTheme.accentPurple,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                // Chapter info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: AppTheme.spacingM,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: AppTheme.textGrey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                chapter.date,
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                color: AppTheme.textGrey,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                chapter.formattedReaders,
                                style: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Download/read indicator
                const Icon(Icons.chevron_right, color: AppTheme.textGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'manga':
        return const Color(0xFF2196F3); // Blue
      case 'manhwa':
        return const Color(0xFF4CAF50); // Green
      case 'manhua':
        return const Color(0xFFFF9800); // Orange
      default:
        return AppTheme.accentPurple;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
