import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/doujin_controller.dart';
import '../models/doujin_model.dart';
import '../widgets/retry_network_image.dart';
import 'doujin_detail_screen.dart';

/// Hidden Doujin List Screen
class DoujinListScreen extends StatefulWidget {
  const DoujinListScreen({super.key});

  @override
  State<DoujinListScreen> createState() => _DoujinListScreenState();
}

class _DoujinListScreenState extends State<DoujinListScreen> {
  final DoujinController _controller = DoujinController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.fetchList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  void _navigateToDetail(DoujinItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoujinDetailScreen(doujinUrl: item.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.cardBlack,
          title: const Text(
            '🔞 Hidden Collection',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.fetchList(refresh: true),
            ),
          ],
        ),
        body: Consumer<DoujinController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.items.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentPurple),
              );
            }

            if (controller.error != null && controller.items.isEmpty) {
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
                      onPressed: () => controller.fetchList(refresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchList(refresh: true),
              color: AppTheme.accentPurple,
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount:
                    controller.items.length +
                    (controller.isLoadingMore ? 3 : 0),
                itemBuilder: (context, index) {
                  if (index >= controller.items.length) {
                    return _buildLoadingCard();
                  }
                  return _buildDoujinCard(controller.items[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDoujinCard(DoujinItem item) {
    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RetryNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      httpHeaders: const {
                        'User-Agent':
                            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                        'Referer': 'https://komikdewasa.id/',
                      },
                    ),
                    // Latest chapter badge
                    if (item.chapters.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withAlpha(200),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            item.chapters.first.title,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textWhite,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.accentPurple,
        ),
      ),
    );
  }
}
