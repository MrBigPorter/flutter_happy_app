import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_app/utils/animation_helper.dart';

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  final Duration delayPerItem;
  final Duration duration;

  final bool fade;
  final bool slide;
  final bool scale;
  final double beginOffsetY;
  final double beginScale;

  final Curve defaultCurve;
  final Curve scaleCurve;

  /// 进入可见才播放（建议保持为 true）
  final bool playWhenVisible;

  /// 离开是否反向
  final bool fadeOutWhenLeave;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayPerItem = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 400),
    this.fade = true,
    this.slide = true,
    this.scale = true,
    this.beginOffsetY = 20.0,
    this.beginScale = 0.9,
    this.defaultCurve = Curves.easeOutCubic,
    this.scaleCurve = Curves.elasticOut,
    this.playWhenVisible = true,
    this.fadeOutWhenLeave = false,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late Animation<double> _opacity;
  late Animation<double> _offsetY;
  late Animation<double> _scale;

  // 本次“可见周期”是否已经播过（离开视口会重置为 false）
  bool _playedThisVisibility = false;

  // 可见后安排的延迟计时器，离开时要取消
  Timer? _delayTimer;

  late final StreamSubscription<bool> _syncSub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);
    _configure(); // 首帧先初始化，避免 LateInitializationError

    // 外部同步（保持你的原有设计）
    _syncSub = AnimationSyncManager.instance.stream.listen((play) {
      if (!mounted) return;
      if (play) {
        _playNow(); // 立刻按当前滚动状态播放一次
      } else {
        _controller.reset();
        _playedThisVisibility = false;
      }
    });
    PageMotionDirection.instance.register(_controller);

    // 首帧可见检查（避免空屏不播）
    if (widget.playWhenVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndMaybeQueue());
    } else {
      // 不关心可见性时，进场就按序排队
      _queuePlayWithDelay();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    PageMotionDirection.instance.unregister(_controller);
    _syncSub.cancel();
    super.dispose();
  }

  // 根据当前滚动状态，动态配置本次动画参数（方向/时长/曲线）
  void _configure() {
    final speed = ScrollSpeedTracker.instance.speed;      // -∞..+∞
    final dir   = ScrollSpeedTracker.instance.direction;  // -1..+1
    final accel = ScrollSpeedTracker.instance.accel;

    final offsetY = widget.slide ? widget.beginOffsetY * dir : 0.0;

    _controller.duration =
    speed.abs() > 0.6 ? const Duration(milliseconds: 200) : widget.duration;

    final curve = accel < 0 ? Curves.easeOutCubic : Curves.easeInOutCubic;
    final curved = CurvedAnimation(parent: _controller, curve: curve);

    _opacity = Tween<double>(
      begin: widget.fade ? 0.1 : 1.0,
      end: 1.0,
    ).animate(curved);

    _offsetY = Tween<double>(
      begin: offsetY,
      end: 0.0,
    ).animate(curved);

    _scale = Tween<double>(
      begin: widget.scale ? widget.beginScale : 1.0,
      end: 1.0,
    ).animate(curved);
  }

  // 首帧检查：如果已经在屏幕内，就安排一次延迟播放
  void _checkAndMaybeQueue() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final size = box.size;
    final pos = box.localToGlobal(Offset.zero);
    final screenH = MediaQuery.of(context).size.height;
    final visible = pos.dy < screenH && pos.dy + size.height > 0;

    if (visible) _queuePlayWithDelay();
  }

  // 可见后：根据 index 和速度排队延迟，再播放
  void _queuePlayWithDelay() {
    if (_playedThisVisibility) return;

    _delayTimer?.cancel();

    if (ScrollSpeedTracker.instance.speed.abs() > 0.9) {
      _playedThisVisibility = true;
      _controller.value = 1.0;
      return;
    }

    final delayMs = VelocityWaveDelay.compute(
      index: widget.index,
      baseMs: widget.delayPerItem.inMilliseconds,
      speed: ScrollSpeedTracker.instance.speed,
    ).clamp(0, 300);
    final boundedDelay = delayMs.clamp(0, 200);
    _delayTimer = Timer(Duration(milliseconds: boundedDelay), () {
      if (!mounted || _playedThisVisibility) return;
      _playNow();
    });
  }

  // 真正触发播放：先按“当前滚动状态”配置，再 forward
  void _playNow() {
    if (_playedThisVisibility) return;
    _configure();
    _playedThisVisibility = true;
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        Widget w = child!;
        if (widget.scale)  w = Transform.scale(scale: _scale.value, child: w);
        if (widget.slide)  w = Transform.translate(offset: Offset(0, _offsetY.value), child: w);
        if (widget.fade)   w = Opacity(opacity: _opacity.value, child: w);
        return w;
      },
      child: widget.child,
    );

    if (!widget.playWhenVisible) return content;

    return VisibilityDetector(
      key: ValueKey('ali-${widget.index}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;

        final visible = info.visibleFraction > 0.1;

        if (visible) {
          // 进入视口：安排一次延迟→播放
          if (!_playedThisVisibility) _queuePlayWithDelay();
        } else {
          // 离开视口：允许下次再播；可选反向
          _delayTimer?.cancel();
          if (_playedThisVisibility) {
            _playedThisVisibility = false;
            if (widget.fadeOutWhenLeave && !_controller.isDismissed) {
              _controller.reverse();
            } else {
              _controller.reset();
            }
          }
        }
      },
      child: content,
    );
  }
}