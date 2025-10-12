import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A widget that creates a sticky header using SliverPersistentHeader.
/// - [pinned]: Whether the header should remain visible at the top when scrolling.
/// - [minHeight]: The minimum height of the header when fully collapsed.
/// - [maxHeight]: The maximum height of the header when fully expanded.
/// - [builder]: A function that builds the header's content based on the current
/// - build context, shrink offset, and whether it overlaps content.
class StickyHeader extends StatelessWidget {
  final double minHeight;
  final double maxHeight;
  final bool pinned;

  final Widget Function(BuildContext context, StickyHeaderInfo info) builder;

  const StickyHeader({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  }) : pinned = true;

  const StickyHeader.pinned({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  }) : pinned = true;

  const StickyHeader.unpinned({
    super.key,
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  }) : pinned = false;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: pinned,
      delegate: _StickyHeaderDelegate(
        minHeight: minHeight,
        maxHeight: maxHeight,
        builder: builder,
      ),
    );
  }
}

/// Information about the current state of the sticky header, including
/// shrink offset, overlap status, progress, min and max extents, and whether
/// it is at the top of the scroll view.
class StickyHeaderInfo {
  final double progress;
  final bool isAtTop;
  final double opacity;
  final double shrinkOffset;

  StickyHeaderInfo({
    required this.progress,
    required this.isAtTop,
    required this.opacity,
    required this.shrinkOffset,
  });
}

/// A delegate for creating a sticky header with customizable min and max heights
/// and a builder function to define the header's content.
/// - [minHeight]: The minimum height of the header when fully collapsed.
/// - [maxHeight]: The maximum height of the header when fully expanded.
/// - [builder]: A function that builds the header's content based on the current
///  shrink offset and whether it overlaps content.
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  final Widget Function(BuildContext context, StickyHeaderInfo info) builder;

  _StickyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.builder,
  });

  @override
  double get minExtent => minHeight.h;

  @override
  double get maxExtent => maxHeight.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double restExtent = maxExtent - minExtent;
    final double progress = math.min(shrinkOffset / (restExtent > 0 ? restExtent : minHeight), 1.0).clamp(0, 1.0);
    final double opacity = 1.0 - (shrinkOffset / (restExtent > 0 ? restExtent : minHeight)).clamp(0.0, 1.0);
    final bool isAtTop =
        shrinkOffset >= (restExtent > 0 ? restExtent : minHeight);
    return SizedBox.expand(
      child: builder(
        context,
        StickyHeaderInfo(
          progress: progress,
          isAtTop: isAtTop,
          opacity: opacity,
            shrinkOffset: shrinkOffset
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate old) {
    return old.minHeight != minHeight ||
        old.maxHeight != maxHeight ||
        old.builder != builder;
  }
}
