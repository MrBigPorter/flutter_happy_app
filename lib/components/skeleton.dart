import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_app/theme/design_tokens.g.dart';

enum SkeletonShape { rect, circle }

/// 骨架屏 Skeleton Screen
/// width: 宽度 width
/// height: 高度 height
/// shape: 形状 shape (rect or circle)
/// shimmer: 是否启用闪烁效果 whether to enable shimmer effect
/// borderRadius: 圆角 border radius (only for rect shape)
///
/// Colors are theme-aware via [TokensX] extension on BuildContext,
/// matching the app shell style (bgPrimary for elements, bgTertiary for shimmer).
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final SkeletonShape shape;
  final bool shimmer;
  final BorderRadius borderRadius;

  const Skeleton.react({
    super.key,
    required this.width,
    required this.height,
    this.shimmer = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : shape = SkeletonShape.rect;

  const Skeleton.circle({
    super.key,
    required this.width,
    required this.height,
    this.shimmer = true,
  }) : shape = SkeletonShape.circle,
       borderRadius = BorderRadius.zero;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = context.bgPrimary;
    // Derive shimmer colors from the token — blends slightly lighter/darker
    // for a subtle shimmer effect matching the index.html app shell style.
    final baseColor = Color.lerp(
      skeletonColor,
      isDark ? Colors.white : Colors.grey.shade400,
      isDark ? 0.08 : 0.12,
    )!;
    final highlightColor = Color.lerp(
      skeletonColor,
      isDark ? Colors.white : Colors.grey.shade200,
      isDark ? 0.15 : 0.20,
    )!;

    final box = Container(
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        color: skeletonColor,
        shape: shape == SkeletonShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == SkeletonShape.rect ? borderRadius : null,
      ),
    );

    if (!shimmer) return box;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: box,
    );
  }
}
