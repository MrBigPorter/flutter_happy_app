import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';

import '../ui/pretty_ring.dart';
import '../ui/pretty_ring_spinner.dart';

class LuckyCustomMaterialIndicator extends StatelessWidget {
  final Color? backgroundColor;
  final Future<void> Function()  onRefresh;
  final Widget child;

  const LuckyCustomMaterialIndicator({
    super.key,
     this.backgroundColor,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomMaterialIndicator(
        backgroundColor: backgroundColor ?? context.bgPrimary,
        onRefresh: onRefresh,
        indicatorBuilder: (context, controller) {
          final s = controller.state;
          final loading = s.isLoading || s.isFinalizing;

          double p = controller.value;
          if (!p.isFinite || p.isNaN) p = 0;
          p = p.clamp(0.0, 1.0);

          return SafeArea(
            top: true,
            bottom: false,
            child: SizedBox(
              height: 33,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: loading
                      ? const PrettyRingSpinner(size: 24, stroke: 3)
                      : PrettyRing(progress: p, size: 24, stroke: 3),
                ),
              ),
            ),
          );
        },
        child: child,
    );
  }
}