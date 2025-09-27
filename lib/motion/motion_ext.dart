import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/widgets.dart';

extension MotionX on Widget {
  /// 点击时抖动并放大 Wiggle and scale up on tap
  /// [dx] 水平抖动幅度 Horizontal shake amplitude
  /// [degAmp] 旋转抖动幅度 Rotation shake amplitude
  /// [scaleUp] 放大倍数 Scale up factor
  /// [onTap] 点击回调 Tap callback
  /// 默认值 Default values: dx=2, degAmp=3, scaleUp=1.02
  Widget wiggleOnTap({
    double dx = 2,
    double degAmp = 3,
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

/// A widget that wiggles and scales up when tapped.
/// 点击时抖动并放大
/// [dx] 水平抖动幅度 Horizontal shake amplitude
/// [degAmp] 旋转抖动幅度 Rotation shake amplitude
/// [scaleUp] 放大倍数 Scale up factor
/// [onTap] 点击回调 Tap callback
/// 默认值 Default values: dx=2, degAmp=3, scaleUp=1.02
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
  final double scaleUp;
  final double degAmp;
  final VoidCallback? onTap;

  @override
  State<_WiggleOnTap> createState() => _WiggleOnTapState();
}

/// State class for [_WiggleOnTap].
/// [_WiggleOnTap]的状态类
/// Uses [TickerProviderStateMixin] to provide a ticker for the animation controller.
/// 使用[TickerProviderStateMixin]为动画控制器提供ticker
/// Manages the animation controller's lifecycle.
/// 管理动画控制器的生命周期
/// Disposes the controller in the dispose method to avoid memory leaks.
/// 在dispose方法中释放控制器以避免内存泄漏
/// Implements the build method to return the animated widget.
/// 实现build方法以返回动画小部件
/// Uses [GestureDetector] to detect taps and trigger the animation.
/// 使用[GestureDetector]检测点击并触发动画
/// Animates the child widget with shake and scale animations.
class _WiggleOnTapState extends State<_WiggleOnTap>
    with TickerProviderStateMixin {
  /// Animation controller for the wiggle and scale animations.
  /// 抖动和放大动画的控制器
  /// Initialized lazily to avoid unnecessary resource usage.
  /// 延迟初始化以避免不必要的资源使用
  /// Disposed in the dispose method to avoid memory leaks.
  /// 在dispose方法中释放以避免内存泄漏s
  /// Using `late final` to ensure it's only initialized once.
  /// 使用`late final`确保只初始化一次
  /// `vsync: this` to tie the controller's lifecycle to the widget's lifecycle.
  /// `vsync: this`将控制器的生命周期绑定到小部件的
  late final AnimationController _ctrl = AnimationController(vsync: this);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Using [GestureDetector] to detect taps and trigger the animation.
    /// 使用[GestureDetector]检测点击并触发动画
    /// On tap, call the provided [onTap] callback and start the animation.
    /// 点击时，调用提供的[onTap]回调并启动动画
    /// The child widget is animated with shake and scale animations.
    return GestureDetector(
      /// Ensuring the entire area is tappable.
      /// 确保整个区域都可以点击
      behavior: HitTestBehavior.opaque,
      onTap: () {
        /// Start the animation from the beginning.
        widget.onTap?.call();
        super.dispose();
      },
      child: widget.child
          .animate(onPlay: (controller) => controller.forward(from: 0))
          .shake(duration: 300.ms, hz: 4, offset: Offset(widget.dx, 0))
          .scale(
            duration: 300.ms,
            begin: Offset(1, 1),
            end: Offset(widget.scaleUp, widget.scaleUp),
            curve: Curves.easeOut,
          ),
    );
  }
}
