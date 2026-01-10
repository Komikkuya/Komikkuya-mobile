import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/api_config.dart';
import '../models/doujin_model.dart';
import '../controllers/history_controller.dart';
import '../widgets/retry_network_image.dart';

/// Doujin Chapter Reader Screen
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

class _DoujinReaderScreenState extends State<DoujinReaderScreen> {
  DoujinChapterData? _chapterData;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchChapter(widget.chapterUrl);

    // Hide system UI for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

          // Scroll to top when loading new chapter (check if attached)
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

      // Clean up double slashes
      while (path.contains('//')) {
        path = path.replaceAll('//', '/');
      }

      // Ensure it starts with /
      if (!path.startsWith('/')) path = '/$path';

      // Transform /baca/slug -> /doujin/chapter/slug
      if (path.startsWith('/baca/')) {
        historyUrl = path.replaceFirst('/baca/', '/doujin/chapter/');
      } else if (!path.startsWith('/doujin/chapter/')) {
        // Fallback: prepend /doujin/chapter
        historyUrl = '/doujin/chapter$path';
      } else {
        historyUrl = path;
      }
    } catch (e) {
      debugPrint('DoujinReaderScreen: Error parsing URL for history: $e');
    }

    // Save to history
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

    debugPrint('DoujinReaderScreen: Saved history: $historyUrl');
  }

  void _precacheAllImages() {
    if (_chapterData == null) return;

    debugPrint(
      'DoujinReaderScreen: Preloading ${_chapterData!.images.length} images...',
    );

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Main content
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              )
            else if (_error != null)
              _buildErrorState()
            else if (_chapterData != null)
              _buildReader(),

            // Top bar
            if (_showControls) _buildTopBar(),

            // Bottom navigation bar
            if (_showControls && _chapterData != null) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _fetchChapter(widget.chapterUrl),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReader() {
    return ListView.builder(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      addAutomaticKeepAlives: true,
      padding: EdgeInsets.only(
        top: _showControls ? 80 : 0,
        bottom: _showControls ? 80 : 0,
      ),
      itemCount: _chapterData!.images.length,
      itemBuilder: (context, index) {
        final image = _chapterData!.images[index];
        return RetryNetworkImage(
          imageUrl: image.url,
          fit: BoxFit.fitWidth,
          httpHeaders: const {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Referer': 'https://komikdewasa.id/',
          },
          placeholder: Container(
            height: 400,
            color: AppTheme.cardBlack,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accentPurple,
              ),
            ),
          ),
          errorWidget: Container(
            height: 200,
            color: AppTheme.cardBlack,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  color: AppTheme.textGrey,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'Page ${image.page}',
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
          left: 4,
          right: 16,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(200), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _chapterData?.mangaTitle ?? widget.mangaTitle ?? 'Reading',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_chapterData != null)
                    Text(
                      _chapterData!.chapterNumber,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (_chapterData != null)
              Text(
                '${_chapterData!.totalImages} pages',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final hasPrev = _chapterData?.prevChapter != null;
    final hasNext = _chapterData?.nextChapter != null;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(220), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Prev button
            Expanded(
              child: GestureDetector(
                onTap: hasPrev ? _navigateToPrevChapter : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hasPrev
                        ? AppTheme.accentPurple.withAlpha(40)
                        : AppTheme.cardBlack.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasPrev
                          ? AppTheme.accentPurple.withAlpha(100)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: hasPrev
                            ? AppTheme.accentPurple
                            : AppTheme.textGrey,
                      ),
                      Text(
                        'Prev',
                        style: TextStyle(
                          color: hasPrev
                              ? AppTheme.accentPurple
                              : AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Chapter indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBlack,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _chapterData?.chapterNumber ?? '',
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Next button
            Expanded(
              child: GestureDetector(
                onTap: hasNext ? _navigateToNextChapter : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hasNext
                        ? AppTheme.accentPurple.withAlpha(40)
                        : AppTheme.cardBlack.withAlpha(100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasNext
                          ? AppTheme.accentPurple.withAlpha(100)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          color: hasNext
                              ? AppTheme.accentPurple
                              : AppTheme.textGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: hasNext
                            ? AppTheme.accentPurple
                            : AppTheme.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
