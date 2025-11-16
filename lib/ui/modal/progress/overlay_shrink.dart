import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'overlay_progress_provider.dart';

class OverlayShrink extends ConsumerWidget {
  final Widget child;
  const OverlayShrink({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(overlayEffectiveProgressProvider);
    // debugPrint('OverlayShrink progress t==>: $t');

    // 没弹窗就啥也不做
    if (t == 0) return child;

    final eased = Curves.easeOutCubic.transform(t);

    // 🔹 左右 + 顶部 的缩进
    final sideInset  = lerpDouble(0.0, 16.0.w, eased)!; // 你可以在 12~20.w 调
    final topInset   = lerpDouble(0.0, 16.0.w, eased)!;

    // 🔹 底部缩进稍微小一点，避免“底部整块上下跳”
    final bottomInset = lerpDouble(0.0, 8.0.w, eased)!; // 甚至可以先设 0 看感觉

    // 🔹 圆角 & 阴影
    final radius        = lerpDouble(0.0, 24.0.w, eased)!;
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
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: 24.w * eased,
              offset: Offset(0, 8.h * eased),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
      ),
    );
  }
}