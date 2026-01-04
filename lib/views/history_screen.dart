import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';
import '../controllers/history_controller.dart';
import '../models/history_model.dart';
import 'chapter_reader_screen.dart';

/// Premium reading history screen with Netflix/Crunchyroll style
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryController>().loadHistory();
    });
  }

  Future<void> _navigateToDetail(HistoryItem item) async {
    // Reconstruct full URL from relative history path
    // Format: /chapter/view/slug/ or /chapter/slug/
    String fullUrl = item.url;

    if (item.url.startsWith('/chapter/')) {
      final path = item.url.replaceFirst('/chapter/', '/');

      if (path.contains('/view/')) {
        // Westmanga
        fullUrl = 'https://westmanga.me$path';
      } else if (path.contains('/chapters/')) {
        // Weebcentral
        fullUrl = 'https://weebcentral.com$path';
      } else {
        // Komiku
        fullUrl = 'https://komiku.org$path';
      }
    }

    debugPrint('HistoryScreen._navigateToDetail: item.url=${item.url}');
    debugPrint('HistoryScreen._navigateToDetail: fullUrl=$fullUrl');

    if (!mounted) return;

    // Navigate straight to reader
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterReaderScreen(
          chapterUrl: fullUrl,
          mangaTitle: item.title,
          coverImage: item.image,
        ),
      ),
    );
  }

  Future<void> _deleteHistory(HistoryItem item) async {
    final controller = context.read<HistoryController>();
    final success = await controller.deleteHistory(item.url);

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
                  'Removed "${item.chapterTitle}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textWhite,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardBlack,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showClearAllDialog() {
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
                Icons.delete_sweep,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear All History',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete all your reading history. Are you sure?',
          style: TextStyle(color: AppTheme.textGrey),
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
            onPressed: () async {
              Navigator.pop(context);
              final controller = context.read<HistoryController>();
              await controller.clearAllHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryController>(
      builder: (context, controller, child) {
        if (controller.isLoading && controller.history.isEmpty) {
          return _buildLoadingState();
        }

        if (controller.history.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.loadHistory,
          color: AppTheme.accentPurple,
          backgroundColor: AppTheme.surfaceBlack,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Stats header
              SliverToBoxAdapter(child: _buildStatsHeader(controller)),
              // History list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = controller.history[index];
                    return _buildHistoryCard(item, index);
                  }, childCount: controller.history.length),
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

  Widget _buildStatsHeader(HistoryController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withAlpha(40), Colors.blue.withAlpha(15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.history, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${controller.count} Chapters',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'in your reading history',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGrey.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
          // Clear all button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: controller.count > 0 ? _showClearAllDialog : null,
              icon: Icon(
                Icons.delete_outline,
                color: controller.count > 0 ? Colors.red : AppTheme.textGrey,
              ),
              tooltip: 'Clear All',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item, int index) {
    final timeAgo = _formatTimeAgo(item.time);

    return Dismissible(
      key: Key(item.url),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteHistory(item),
      child: GestureDetector(
        onTap: () => _navigateToDetail(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: SizedBox(
                  width: 90,
                  height: 120,
                  child: item.image != null
                      ? CachedNetworkImage(
                          imageUrl: item.image!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.surfaceBlack,
                            child: const Center(
                              child: Icon(
                                Icons.menu_book,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.surfaceBlack,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppTheme.surfaceBlack,
                          child: const Center(
                            child: Icon(
                              Icons.menu_book,
                              color: AppTheme.textGrey,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Chapter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(30),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.chapterTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Time and type
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textGrey.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGrey.withAlpha(150),
                            ),
                          ),
                          if (item.type != null) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getTypeColor(item.type!).withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.type!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: _getTypeColor(item.type!),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Continue button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      // Custom month formatting without intl
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[time.month - 1]} ${time.day}';
    }
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withAlpha(40),
                    Colors.blue.withAlpha(20),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(30),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.history, size: 60, color: Colors.blue),
            ),
            const SizedBox(height: 32),
            const Text(
              'No Reading History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start reading some manga!\nYour reading progress will appear here.',
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
                gradient: const LinearGradient(
                  colors: [Colors.blue, Color(0xFF1565C0)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(60),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Navigate to home
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
                          'Start Reading',
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
        // List shimmer
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: AppTheme.cardBlack,
                  highlightColor: AppTheme.surfaceBlack,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            }, childCount: 5),
          ),
        ),
      ],
    );
  }
}
