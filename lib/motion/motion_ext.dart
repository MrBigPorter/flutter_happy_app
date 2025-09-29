import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension MotionX on Widget {
  /// 点击抖动 + 放大
  Widget wiggleOnTap({
    double dx = 2,
    double degAmp = 0,      // 需要旋转时再用（度数）；默认 0 不旋转
    double scaleUp = 1.02,
    VoidCallback? onTap,
  }) {
    return _WiggleOnTap(
      dx: dx,
      degAmp: degAmp,
      scaleUp: scaleUp,
      onTap: onTap,
      child: this,
    );
  }
}

class _WiggleOnTap extends StatefulWidget {
  const _WiggleOnTap({
    required this.child,
    required this.dx,
    required this.degAmp,
    required this.scaleUp,
    this.onTap,
  });

  final Widget child;
  final double dx;
  final double degAmp;   // 旋转幅度（度）
  final double scaleUp;
  final VoidCallback? onTap;

  @override
  State<_WiggleOnTap> createState() => _WiggleOnTapState();
}

class _WiggleOnTapState extends State<_WiggleOnTap> {
  // 每点一次自增，让 Animate 的 key 变化，从而“重放”一遍动画
  int _nonce = 0;

  @override
  Widget build(BuildContext context) {
    var chain = widget.child
        .animate(key: ValueKey(_nonce))                         // 关键点
        .shake(duration: 300.ms, hz: 4, offset: Offset(widget.dx, 0))
        .scale(
      duration: 300.ms,
      begin: const Offset(1, 1),
      end: Offset(widget.scaleUp, widget.scaleUp),
      curve: Curves.easeOut,
    );

    // 需要旋转抖动就加一段 rotate（把度转弧度）
    if (widget.degAmp != 0) {
      final rad = widget.degAmp * 3.1415926535 / 180.0;
      chain = chain.rotate(
        duration: 300.ms,
        begin: -rad / 2,
        end: rad / 2,
        curve: Curves.easeInOut,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onTap?.call();
        setState(() => _nonce++);   // 触发重建 → 动画从头播放
      },
      child: chain,
    );
  }
}