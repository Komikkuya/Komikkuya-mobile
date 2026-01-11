import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/doujin_model.dart';
import '../controllers/history_controller.dart';
import '../widgets/retry_network_image.dart';

/// Doujin Chapter Reader Screen - Netflix/Webtoon style
class DoujinReaderScreen extends StatefulWidget {
  final String chapterUrl;
  final String? mangaTitle;

  const DoujinReaderScreen({
    super.key,
    required this.chapterUrl,
    this.mangaTitle,
  });

  @override
  State<DoujinReaderScreen> createState() => _DoujinReaderScreenState();
}

class _DoujinReaderScreenState extends State<DoujinReaderScreen>
    with SingleTickerProviderStateMixin {
  DoujinChapterData? _chapterData;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  double _scrollProgress = 0.0;
  int _currentImageIndex = 0;

  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  // Retry keys for forcing image reload
  final Map<int, int> _retryKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      duration: AppTheme.animationFast,
      vsync: this,
    );
    _animationController.forward();

    _fetchChapter(widget.chapterUrl);

    // Hide system UI for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;

    // Update progress without setState - progress indicator will rebuild on its own
    final newProgress = maxScroll > 0 ? currentScroll / maxScroll : 0.0;

    // Only update state if progress changed significantly (every 2%)
    if ((newProgress - _scrollProgress).abs() > 0.02) {
      _scrollProgress = newProgress;
      // Use a post-frame callback to avoid scroll glitch
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    // Calculate current image index
    if (_chapterData != null && _chapterData!.images.isNotEmpty) {
      final averageImageHeight = maxScroll / _chapterData!.images.length;
      final estimatedIndex = (currentScroll / averageImageHeight).floor();
      final clampedIndex = estimatedIndex.clamp(
        0,
        _chapterData!.images.length - 1,
      );
      if (_currentImageIndex != clampedIndex) {
        _currentImageIndex = clampedIndex;
      }
    }
  }

  Future<void> _fetchChapter(String chapterUrl) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = ApiConfig.doujinChapterUrl(chapterUrl);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          setState(() {
            _chapterData = DoujinChapterData.fromJson(
              json['data'] as Map<String, dynamic>,
            );
            _isLoading = false;
          });

          // Precache all images in background
          if (mounted) {
            _precacheAllImages();
          }

          // Scroll to top when loading new chapter
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }

          // Save to history
          _saveToHistory();
        } else {
          setState(() {
            _error = 'Invalid response';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToPrevChapter() {
    if (_chapterData?.prevChapter != null) {
      _fetchChapter(_chapterData!.prevChapter!.url);
    }
  }

  void _navigateToNextChapter() {
    if (_chapterData?.nextChapter != null) {
      _fetchChapter(_chapterData!.nextChapter!.url);
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _saveToHistory() {
    final chapter = _chapterData;
    if (chapter == null) return;

    String historyUrl = widget.chapterUrl;
    try {
      final uri = Uri.parse(widget.chapterUrl);
      String path = uri.path;

      while (path.contains('//')) {
        path = path.replaceAll('//', '/');
      }

      if (!path.startsWith('/')) path = '/$path';

      if (path.startsWith('/baca/')) {
        historyUrl = path.replaceFirst('/baca/', '/doujin/chapter/');
      } else if (!path.startsWith('/doujin/chapter/')) {
        historyUrl = '/doujin/chapter$path';
      } else {
        historyUrl = path;
      }
    } catch (e) {
      debugPrint('DoujinReaderScreen: Error parsing URL for history: $e');
    }

    final historyController = context.read<HistoryController>();
    historyController.saveHistory(
      title:
          widget.mangaTitle ??
          (chapter.mangaTitle.isNotEmpty
              ? chapter.mangaTitle
              : 'Unknown Doujin'),
      chapterTitle: chapter.chapterNumber,
      url: historyUrl,
      image: chapter.images.isNotEmpty ? chapter.images.first.url : null,
      type: 'doujin',
    );
  }

  void _precacheAllImages() {
    if (_chapterData == null) return;

    for (var image in _chapterData!.images) {
      precacheImage(
        CachedNetworkImageProvider(
          image.url,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://komikdewasa.id/',
          },
        ),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_chapterData == null || _chapterData!.images.isEmpty) {
      return _buildEmptyState();
    }

    return _buildReader();
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

  Widget _buildErrorState() {
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
              _error ?? 'Unknown error',
              style: const TextStyle(color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.textGrey),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: AppTheme.spacingM),
                ElevatedButton.icon(
                  onPressed: () => _fetchChapter(widget.chapterUrl),
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
            onPressed: () => Navigator.pop(context),
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

  Widget _buildReader() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image list - Webtoon style vertical scroll
          _buildImageList(),

          // Top controls overlay
          if (_showControls) _buildTopControls(),

          // Bottom controls overlay
          if (_showControls) _buildBottomControls(),

          // Progress indicator - always visible at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      addAutomaticKeepAlives: true,
      padding: EdgeInsets.zero,
      itemCount: _chapterData!.images.length + 1, // +1 for end card
      itemBuilder: (context, index) {
        if (index == _chapterData!.images.length) {
          return _buildEndCard();
        }
        return _buildImageItem(_chapterData!.images[index], index);
      },
    );
  }

  Widget _buildImageItem(DoujinChapterImage image, int index) {
    final retryKey = _retryKeys[index] ?? 0;

    return RetryNetworkImage(
      key: ValueKey('${image.url}-$retryKey'),
      imageUrl: image.url,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      httpHeaders: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': 'https://komikdewasa.id/',
      },
      placeholder: Container(
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
      errorWidget: Container(
        height: 200,
        color: AppTheme.cardBlack,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white.withAlpha(128),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Failed to load page ${index + 1}',
                style: TextStyle(color: Colors.white.withAlpha(128)),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _retryKeys[index] = (_retryKeys[index] ?? 0) + 1;
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPurple,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEndCard() {
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
          const Text(
            'Chapter Complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            _chapterData?.chapterNumber ?? '',
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_chapterData?.prevChapter != null)
                OutlinedButton.icon(
                  onPressed: _navigateToPrevChapter,
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
              if (_chapterData?.nextChapter != null)
                ElevatedButton.icon(
                  onPressed: _navigateToNextChapter,
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

          // Back button
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.menu_book),
            label: const Text('Back to Details'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textGrey),
          ),
          const SizedBox(height: AppTheme.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildTopControls() {
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
                  onPressed: () => Navigator.pop(context),
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
                        _chapterData?.mangaTitle ??
                            widget.mangaTitle ??
                            'Reading',
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
                        _chapterData?.chapterNumber ?? '',
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
                    '${_currentImageIndex + 1}/${_chapterData?.totalImages ?? 0}',
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

  Widget _buildBottomControls() {
    final hasPrev = _chapterData?.prevChapter != null;
    final hasNext = _chapterData?.nextChapter != null;

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
                    enabled: hasPrev,
                    onTap: hasPrev ? _navigateToPrevChapter : null,
                  ),
                ),
                // Chapters (back to detail)
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.list,
                    label: 'Chapters',
                    enabled: true,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                // Scroll to top
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.vertical_align_top,
                    label: 'Top',
                    enabled: true,
                    onTap: () {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
                // Next chapter
                Expanded(
                  child: _buildBottomNavItem(
                    icon: Icons.skip_next,
                    label: 'Next',
                    enabled: hasNext,
                    onTap: hasNext ? _navigateToNextChapter : null,
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

  Widget _buildProgressIndicator() {
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      height: 3,
      child: LinearProgressIndicator(
        value: _scrollProgress,
        backgroundColor: Colors.white24,
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentPurple),
      ),
    );
  }
}
