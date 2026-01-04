import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';
import '../controllers/chapter_reader_controller.dart';
import '../controllers/history_controller.dart';
import '../models/chapter_content_model.dart';

/// Chapter reader screen with Webtoon/Netflix style vertical scrolling
class ChapterReaderScreen extends StatefulWidget {
  final String chapterUrl;
  final String? mangaUrl;
  final String? mangaTitle;
  final String? coverImage;

  const ChapterReaderScreen({
    super.key,
    required this.chapterUrl,
    this.mangaUrl,
    this.mangaTitle,
    this.coverImage,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen>
    with SingleTickerProviderStateMixin {
  late ChapterReaderController _controller;
  late ScrollController _scrollController;
  late AnimationController _animationController;

  String? _initialMangaUrl;

  @override
  void initState() {
    super.initState();
    _controller = ChapterReaderController();
    _scrollController = ScrollController();
    _initialMangaUrl = widget.mangaUrl;

    // Animation for controls fade
    _animationController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    _animationController.forward();

    // Set immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Load chapter and save to history when done
    _controller.loadChapter(widget.chapterUrl).then((_) {
      if (_controller.chapterContent != null) {
        _saveToHistory();
      }
    });

    // Listen to scroll
    _scrollController.addListener(_onScroll);
  }

  /// Save reading progress to history
  void _saveToHistory() {
    final chapter = _controller.chapterContent;
    if (chapter == null) return;

    // Convert full URL to relative path for better source detection
    // Example: komiku.org/slug/ -> /chapter/slug/
    // Example: westmanga.me/view/slug/ -> /chapter/view/slug/
    // Example: weebcentral.com/chapters/slug/ -> /chapter/chapters/slug/
    String relativeUrl = widget.chapterUrl;
    try {
      final uri = Uri.parse(widget.chapterUrl);
      String path = uri.path;
      // Clean up double slashes if any
      while (path.contains('//')) {
        path = path.replaceAll('//', '/');
      }
      // Ensure it starts with /
      if (!path.startsWith('/')) path = '/$path';

      relativeUrl = '/chapter$path';
    } catch (e) {
      debugPrint('ChapterReaderScreen: Error parsing URL for history: $e');
    }

    // Use first image from chapter as fallback if coverImage is missing
    String? displayImage = widget.coverImage;
    if (displayImage == null && chapter.images.isNotEmpty) {
      displayImage = chapter.images.first.url;
    }

    final historyController = context.read<HistoryController>();
    historyController.saveHistory(
      title: widget.mangaTitle ?? chapter.title.split(' - ').first,
      chapterTitle: chapter.title,
      url: relativeUrl,
      image: displayImage,
      type: null,
    );
    debugPrint(
      'HistoryController: Saved relative history with image: $relativeUrl',
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _controller.dispose();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final progress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;

    _controller.updateScrollProgress(progress);

    // Calculate current image index based on viewport
    final chapter = _controller.chapterContent;
    if (chapter != null && chapter.images.isNotEmpty) {
      // Estimate image height - this is approximate
      final averageImageHeight = maxScroll / chapter.images.length;
      final estimatedIndex = (currentScroll / averageImageHeight).floor();
      final clampedIndex = estimatedIndex.clamp(0, chapter.images.length - 1);
      _controller.updateCurrentImageIndex(clampedIndex);
    }
  }

  void _navigateToChapter(String chapterUrl) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChapterReaderScreen(
              chapterUrl: chapterUrl,
              mangaUrl: _initialMangaUrl,
              mangaTitle: widget.mangaTitle,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _goBackToMangaDetail() {
    // Simply pop back to manga detail
    // Since we use pushReplacement for chapter-to-chapter navigation,
    // there's only one chapter reader on the stack at a time
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<ChapterReaderController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return _buildLoadingState();
            }

            if (controller.hasError) {
              return _buildErrorState(controller);
            }

            final chapter = controller.chapterContent;
            if (chapter == null || chapter.images.isEmpty) {
              return _buildEmptyState();
            }

            return _buildReader(chapter, controller);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.accentPurple),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Loading chapter...',
            style: TextStyle(color: Colors.white.withAlpha(179)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ChapterReaderController controller) {
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
              'Failed to load chapter',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              controller.error ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _goBackToMangaDetail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.textGrey),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: () => controller.loadChapter(widget.chapterUrl),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported,
            color: AppTheme.textGrey,
            size: 64,
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'No images found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          OutlinedButton.icon(
            onPressed: _goBackToMangaDetail,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.textGrey),
            ),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildReader(
    ChapterContent chapter,
    ChapterReaderController controller,
  ) {
    return GestureDetector(
      onTap: controller.toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image list - Webtoon style vertical scroll
          _buildImageList(chapter),

          // Top controls overlay - positioned at TOP
          if (controller.isControlsVisible)
            _buildTopControls(chapter, controller),

          // Bottom controls overlay - positioned at BOTTOM
          if (controller.isControlsVisible)
            _buildBottomControls(chapter, controller),

          // Progress indicator - always visible at very bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressIndicator(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildImageList(ChapterContent chapter) {
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: chapter.images.length + 1, // +1 for end card
      itemBuilder: (context, index) {
        if (index == chapter.images.length) {
          return _buildEndCard(chapter);
        }
        return _buildImageItem(chapter.images[index], index);
      },
    );
  }

  Widget _buildImageItem(ChapterImage image, int index) {
    return CachedNetworkImage(
      imageUrl: image.url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      placeholder: (context, url) => Container(
        height: 300,
        color: AppTheme.cardBlack,
        child: Shimmer.fromColors(
          baseColor: AppTheme.cardBlack,
          highlightColor: AppTheme.surfaceBlack,
          child: Container(
            height: 300,
            color: AppTheme.cardBlack,
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white.withAlpha(77),
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 200,
        color: AppTheme.cardBlack,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: AppTheme.textGrey,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Image ${index + 1}',
                style: const TextStyle(color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndCard(ChapterContent chapter) {
    final controller = _controller;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      color: AppTheme.primaryBlack,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingXL),
          const Icon(
            Icons.check_circle,
            color: AppTheme.accentPurple,
            size: 64,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'Chapter Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            chapter.title,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.hasPrevChapter)
                OutlinedButton.icon(
                  onPressed: () =>
                      _navigateToChapter(controller.prevChapterUrl!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.accentPurple),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
              const SizedBox(width: AppTheme.spacingM),
              if (controller.hasNextChapter)
                ElevatedButton.icon(
                  onPressed: () =>
                      _navigateToChapter(controller.nextChapterUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next Chapter'),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Back to manga button
          TextButton.icon(
            onPressed: _goBackToMangaDetail,
            icon: const Icon(Icons.menu_book),
            label: const Text('Back to Manga'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textGrey),
          ),
          const SizedBox(height: AppTheme.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildTopControls(
    ChapterContent chapter,
    ChapterReaderController controller,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(220),
              Colors.black.withAlpha(150),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingS,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: _goBackToMangaDetail,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXS),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chapter.mangaTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapter.title,
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                // Page counter badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.currentImageIndex + 1}/${chapter.totalImages}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    ChapterContent chapter,
    ChapterReaderController controller,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(240),
              Colors.black.withAlpha(180),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              AppTheme.spacingXL,
              AppTheme.spacingM,
              AppTheme.spacingS,
            ),
            child: Row(
              children: [
                // Previous chapter
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.skip_previous,
                    label: 'Prev',
                    enabled: controller.hasPrevChapter,
                    onTap: controller.hasPrevChapter
                        ? () => _navigateToChapter(controller.prevChapterUrl!)
                        : null,
                  ),
                ),
                // Chapters
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.list,
                    label: 'Chapters',
                    enabled: true,
                    onTap: _goBackToMangaDetail,
                  ),
                ),
                // Settings
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    enabled: true,
                    onTap: () {},
                  ),
                ),
                // Next chapter
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.skip_next,
                    label: 'Next',
                    enabled: controller.hasNextChapter,
                    onTap: controller.hasNextChapter
                        ? () => _navigateToChapter(controller.nextChapterUrl!)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? AppTheme.accentPurple : AppTheme.textGrey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : AppTheme.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ChapterReaderController controller) {
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      height: 3,
      child: LinearProgressIndicator(
        value: controller.scrollProgress,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
      ),
    );
  }
}
