import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'overlay_progress_provider.dart';

class OverlayShrink extends StatelessWidget {
  final Widget child;
  const OverlayShrink({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 1. 依然使用 Consumer 来做局部刷新优化，只重绘壳子
    return Consumer(
      child: child, // 缓存 child，防止 child 自身的 build 方法被调用
      builder: (context, ref, cachedChild) {
        final t = ref.watch(overlayProgressProvider);


        // 当 t 很小时，我们依然要渲染下面的结构，只是参数为 0
        // 这样 Flutter 才知道 cachedChild 还是同一个实例，不需要重建 State
        final eased = Curves.easeOutCubic.transform(t);

        // 各种插值
        final sideInset = lerpDouble(0.0, 16.0.w, eased)!;
        final topInset = lerpDouble(0.0, 16.0.w, eased)!;
        final bottomInset = lerpDouble(0.0, 8.0.w, eased)!;
        final radius = lerpDouble(0.0, 24.0.w, eased)!;
        final shadowOpacity = 0.12 * eased;

        final bg = Theme.of(context).scaffoldBackgroundColor;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            sideInset,
            topInset,
            sideInset,
            bottomInset,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                // 当 opacity 极小时，不渲染阴影以节省性能，但 Box 结构要保留
                if (shadowOpacity > 0.01)
                  BoxShadow(
                    color: Colors.black.withOpacity(shadowOpacity), // 兼容旧版 Flutter
                    offset: Offset(0, 8.h * eased),
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: ClipRRect(
              // 当 radius 为 0 时，ClipRRect 几乎没有性能消耗，但必须保留占位
              borderRadius: BorderRadius.circular(radius),
              child: cachedChild,
            ),
          ),
        );
      },
    );
  }
}