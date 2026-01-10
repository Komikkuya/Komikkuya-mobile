import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/doujin_controller.dart';
import '../controllers/favorites_controller.dart';
import '../models/doujin_model.dart';
import '../widgets/retry_network_image.dart';
import 'doujin_reader_screen.dart';

/// Doujin Detail Screen - shows detail and chapter list
class DoujinDetailScreen extends StatefulWidget {
  final String doujinUrl;

  const DoujinDetailScreen({super.key, required this.doujinUrl});

  @override
  State<DoujinDetailScreen> createState() => _DoujinDetailScreenState();
}

class _DoujinDetailScreenState extends State<DoujinDetailScreen> {
  final DoujinController _controller = DoujinController();

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
      MaterialPageRoute(
        builder: (_) => DoujinReaderScreen(
          chapterUrl: chapter.url,
          mangaTitle: _controller.detail?.title,
        ),
      ),
    );
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
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              );
            }

            if (controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      controller.error!,
                      style: const TextStyle(color: AppTheme.textGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => controller.fetchDetail(widget.doujinUrl),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final detail = controller.detail;
            if (detail == null) {
              return const Center(
                child: Text(
                  'No data',
                  style: TextStyle(color: AppTheme.textGrey),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                _buildAppBar(detail),
                _buildInfo(detail),
                _buildChapterList(detail),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(DoujinDetail detail) {
    return Consumer<FavoritesController>(
      builder: (context, favController, _) {
        final isFavorited = favController.isFavorited(detail.slug);

        return SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppTheme.cardBlack,
          actions: [
            IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: () =>
                  _toggleFavorite(detail, favController, isFavorited),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              detail.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                RetryNetworkImage(
                  imageUrl: detail.cover,
                  fit: BoxFit.cover,
                  httpHeaders: const {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Referer': 'https://komikdewasa.id/',
                  },
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(200)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildInfo(DoujinDetail detail) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and type badges
            Row(
              children: [
                _buildBadge(detail.type, AppTheme.accentPurple),
                const SizedBox(width: 8),
                _buildBadge(
                  detail.status,
                  detail.status == 'Ongoing' ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  '${detail.totalChapters} Chapters',
                  AppTheme.textGrey,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Author
            if (detail.author.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: AppTheme.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      detail.author,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Last update
            Row(
              children: [
                const Icon(Icons.update, size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 6),
                Text(
                  'Updated: ${detail.lastUpdate}',
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Genres
            if (detail.genres.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: detail.genres
                    .map(
                      (g) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBlack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentPurple.withAlpha(80),
                          ),
                        ),
                        child: Text(
                          g,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textWhite,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

            // Description
            if (detail.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                detail.description,
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(color: AppTheme.cardBlack, thickness: 1),
            const SizedBox(height: 12),

            // Chapter header
            Row(
              children: [
                const Icon(Icons.list, color: AppTheme.accentPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chapters (${detail.chapters.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList(DoujinDetail detail) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final chapter = detail.chapters[index];
        return ListTile(
          onTap: () => _onChapterTap(chapter),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
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
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
        );
      }, childCount: detail.chapters.length),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
