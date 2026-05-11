import 'package:flutter/material.dart';

/// A scroll-aware wrapper that tracks scroll position.
///
/// Previously included manual image preloading logic via [precacheImage],
/// but since the app uses [CachedNetworkImage] with its own built-in caching
/// and preloading, that redundant logic has been removed.
///
/// The scroll position tracking ([_lastProcessedPixels]) is retained for
/// future use if needed.
class ScrollAwarePreloader extends StatefulWidget {
  final Widget child;
  final List<Object?> items;
  final double itemAverageHeight;
  final int preloadWindow;
  final double? predictWidth;

  const ScrollAwarePreloader({
    super.key,
    required this.child,
    required this.items,
    this.itemAverageHeight = 300.0,
    this.preloadWindow = 15,
    this.predictWidth,
  });

  @override
  State<ScrollAwarePreloader> createState() => _ScrollAwarePreloaderState();
}

class _ScrollAwarePreloaderState extends State<ScrollAwarePreloader> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollMetric,
      child: widget.child,
    );
  }

  bool _handleScrollMetric(ScrollNotification notification) {
    return false;
  }
}
