import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

enum SkeletonShape { rect, circle }

/// 骨架屏 Skeleton Screen
/// width: 宽度 width
/// height: 高度 height
/// shape: 形状 shape (rect or circle)
/// shimmer: 是否启用闪烁效果 whether to enable shimmer effect
/// borderRadius: 圆角 border radius (only for rect shape)
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
    final box = Container(
      width: width.w,
      height: height.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: shape == SkeletonShape.circle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: shape == SkeletonShape.rect ? borderRadius : null,
      ),
    );

    if (!shimmer) return box;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: box,
    );
  }
}
