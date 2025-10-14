import 'package:flutter/cupertino.dart';


class CustomCupertinoSliverRefreshControl extends StatelessWidget {
  final Future<void> Function() onRefresh;

  /// 触发刷新需要的拉动距离（默认 150）
  final double triggerDistance;

  /// indicator 显示的高度（默认 70）
  final double indicatorExtent;

  /// activityIndicator 半径（默认 14）
  final double radius;

  const CustomCupertinoSliverRefreshControl({
    super.key,
    required this.onRefresh,
    this.triggerDistance = 150,
    this.indicatorExtent = 70,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      refreshTriggerPullDistance: triggerDistance,
      refreshIndicatorExtent: indicatorExtent,
      builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
        // 1️⃣ 拉动小于 40px 时完全不显示
        if (pulledExtent < 40) return const SizedBox.shrink();

        // 2️⃣ 从 40px 开始逐渐淡入
        final opacity = ((pulledExtent - 40) / 60).clamp(0.0, 1.0);

        // 3️⃣ 模拟 iOS 阻尼动画：拉得越多，indicator 稍微下移一些
        final offset = (pulledExtent - refreshIndicatorExtent).clamp(0, 40);

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offset / 2), // ✅ 微弱位移，更自然
            child: const Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          ),
        );
      },
    );
  }
}