import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../controllers/search_controller.dart' as app;
import '../models/search_result_model.dart';
import '../models/source_type.dart';
import 'manga_detail_screen.dart';

/// Search screen with multi-source search
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final app.SearchController _controller = app.SearchController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _controller.search(query);
    });
  }

  void _navigateToDetail(SearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MangaDetailScreen(mangaUrl: result.url),
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
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search manga...',
              hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
              border: InputBorder.none,
            ),
          ),
          actions: [
            Consumer<app.SearchController>(
              builder: (context, controller, _) {
                if (controller.query.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchController.clear();
                      _controller.clear();
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<app.SearchController>(
          builder: (context, controller, _) {
            if (controller.query.isEmpty) {
              return _buildEmptyState();
            }

            if (controller.isLoading) {
              return _buildLoadingState();
            }

            if (controller.error != null) {
              return _buildErrorState(controller.error!);
            }

            if (!controller.hasResults) {
              return _buildNoResultsState();
            }

            return Column(
              children: [
                // Source filter chips
                _buildSourceFilters(controller),
                // Results list
                Expanded(child: _buildResultsList(controller)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSourceFilters(app.SearchController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              label: 'All (${controller.results.length})',
              isSelected: controller.filterSource == null,
              onTap: () => controller.setFilter(null),
            ),
            const SizedBox(width: AppTheme.spacingS),
            ...MangaSource.values.map((source) {
              final count = controller.getCountBySource(source);
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingS),
                child: _buildFilterChip(
                  label: '${source.emoji} ${source.displayName} ($count)',
                  isSelected: controller.filterSource == source,
                  onTap: () => controller.setFilter(source),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentPurple : AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentPurple
                : AppTheme.textGrey.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textGrey,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(app.SearchController controller) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: controller.results.length,
      itemBuilder: (context, index) {
        final result = controller.results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return GestureDetector(
      onTap: () => _navigateToDetail(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.cardBlack,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusMedium),
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
              ),
              child: CachedNetworkImage(
                imageUrl: result.imageUrl,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppTheme.cardBlack,
                  highlightColor: AppTheme.textGrey.withAlpha(51),
                  child: Container(color: AppTheme.cardBlack),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.cardBlack,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getSourceColor(result.source).withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${result.source.emoji} ${result.source.shortLabel}',
                        style: TextStyle(
                          color: _getSourceColor(result.source),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    // Title
                    Text(
                      result.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    // Meta info
                    Row(
                      children: [
                        if (result.type != null) ...[
                          Text(
                            result.type!,
                            style: const TextStyle(
                              color: AppTheme.textGrey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                        ],
                        if (result.status != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: result.status?.toLowerCase() == 'completed'
                                  ? Colors.green.withAlpha(51)
                                  : AppTheme.accentPurple.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              result.status!,
                              style: TextStyle(
                                color:
                                    result.status?.toLowerCase() == 'completed'
                                    ? Colors.green
                                    : AppTheme.accentPurple,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                        if (result.rating != null) ...[
                          const Spacer(),
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            result.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (result.latestChapter != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        result.latestChapter!,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Arrow
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingM),
              child: Icon(Icons.chevron_right, color: AppTheme.textGrey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(MangaSource source) {
    switch (source) {
      case MangaSource.komiku:
        return Colors.red;
      case MangaSource.asia:
        return Colors.blue;
      case MangaSource.international:
        return Colors.green;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: AppTheme.textGrey.withAlpha(102)),
          const SizedBox(height: AppTheme.spacingL),
          const Text(
            'Search for manga',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Results from 3 sources: ID, Asia, International',
            style: TextStyle(
              color: AppTheme.textGrey.withAlpha(150),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.cardBlack,
          highlightColor: AppTheme.textGrey.withAlpha(51),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardBlack,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            'Search failed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            error,
            style: const TextStyle(color: AppTheme.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: AppTheme.textGrey),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Try a different search term',
            style: TextStyle(color: AppTheme.textGrey.withAlpha(180)),
          ),
        ],
      ),
    );
  }
}
