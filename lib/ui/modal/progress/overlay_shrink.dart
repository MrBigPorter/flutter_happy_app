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
    final t = ref.watch(overlayProgressProvider);

    if (t < 0.01) return child;

    final eased = Curves.easeOutCubic.transform(t);

    final sideInset  = lerpDouble(0.0, 16.0.w, eased)!;
    final topInset   = lerpDouble(0.0, 16.0.w, eased)!;

    final bottomInset = lerpDouble(0.0, 8.0.w, eased)!;

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
              color: Colors.black.withValues(alpha: shadowOpacity),
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