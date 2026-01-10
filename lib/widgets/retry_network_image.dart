import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';

/// A smart network image widget that automatically retries with different URL variants
/// (e.g., removing proxies) if the initial load fails.
class RetryNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Map<String, String>? httpHeaders;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? fadeOutDuration;

  const RetryNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.httpHeaders,
    this.placeholder,
    this.errorWidget,
    this.fadeOutDuration,
  });

  @override
  State<RetryNetworkImage> createState() => _RetryNetworkImageState();
}

class _RetryNetworkImageState extends State<RetryNetworkImage> {
  late List<String> _urls;
  int _currentIndex = 0;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _urls = _generateUrlVariants(widget.imageUrl);
  }

  @override
  void didUpdateWidget(RetryNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      setState(() {
        _urls = _generateUrlVariants(widget.imageUrl);
        _currentIndex = 0;
        _isRetrying = false;
      });
    }
  }

  List<String> _generateUrlVariants(String url) {
    // Avoid double cleaning if already matched
    final variants = <String>[url];

    // Variant 2: Fixed common malformations (double slashes)
    // e.g., https://i0.wp.com//domain.com -> https://i0.wp.com/domain.com
    String fixedDouble = url.replaceAll('//', '/').replaceFirst(':/', '://');
    if (fixedDouble != url) {
      variants.add(fixedDouble);
    }

    // Variant 3: Direct URL (Extract from proxy)
    String? direct;

    // WordPress i0.wp.com
    if (url.contains('i0.wp.com/')) {
      final parts = url.split('i0.wp.com/');
      if (parts.length > 1) {
        direct = parts[1];
      }
    }
    // wsrv.nl proxy
    else if (url.contains('wsrv.nl/?url=')) {
      final parts = url.split('wsrv.nl/?url=');
      if (parts.length > 1) {
        // Handle additional params if any
        String raw = parts[1];
        if (raw.contains('&')) {
          raw = raw.split('&').first;
        }
        direct = Uri.decodeComponent(raw);
      }
    }

    if (direct != null && direct.isNotEmpty) {
      String localDirect = direct;
      // Clean leading slashes
      while (localDirect.startsWith('/')) {
        localDirect = localDirect.substring(1);
      }
      // Ensure protocol
      if (!localDirect.startsWith('http')) {
        localDirect = 'https://$localDirect';
      }

      // Clean again to be sure
      String cleanedDirect = localDirect
          .replaceAll('//', '/')
          .replaceFirst(':/', '://');
      variants.add(cleanedDirect);
    }

    return variants.toSet().toList();
  }

  void _handleError() {
    if (_currentIndex < _urls.length - 1) {
      debugPrint(
        'RetryNetworkImage: Loading failed for ${_urls[_currentIndex]}. Retrying with next variant...',
      );
      if (mounted) {
        setState(() {
          _currentIndex++;
          _isRetrying = true;
        });
      }
    } else {
      debugPrint(
        'RetryNetworkImage: All URL variants failed for ${widget.imageUrl}',
      );
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _urls.length) {
      return widget.errorWidget ?? _defaultErrorWidget();
    }

    final currentUrl = _urls[_currentIndex];

    return CachedNetworkImage(
      imageUrl: currentUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      httpHeaders: widget.httpHeaders,
      fadeOutDuration: widget.fadeOutDuration,
      placeholder: (context, url) =>
          widget.placeholder ?? _defaultPlaceholder(),
      errorWidget: (context, url, error) {
        // Trigger retry logic
        if (_currentIndex < _urls.length - 1 && !_isRetrying) {
          // Delay to avoid infinite build loop if state change happens too fast
          Future.microtask(() => _handleError());
          return widget.placeholder ?? _defaultPlaceholder();
        }

        return widget.errorWidget ?? _defaultErrorWidget();
      },
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.cardBlack,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.accentPurple.withAlpha(150),
          ),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: AppTheme.cardBlack,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textGrey,
          size: 24,
        ),
      ),
    );
  }
}
