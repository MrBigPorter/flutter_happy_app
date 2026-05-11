import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/utils/animation_helper.dart';

/// 列表项入场动画组件
///
/// 核心优化：
/// - 使用静态 `_isScrollingFast` 标记，避免每个 item 都读取 ScrollSpeedTracker
/// - 快速滚动时跳过 AnimationController 创建，直接显示子组件
/// - 首屏/静止时也跳过动画，直接显示
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
  });

  /// 下拉刷新时调用，重置记忆
  static void reset() {
    _shownIndices.clear();
  }

  /// 全局记录已展示过的索引
  static final Set<int> _shownIndices = {};

  /// 静态标记：当前是否在快速滚动
  /// 由 ScrollSpeedTracker 的监听器更新
  static bool _isScrollingFast = false;

  /// 由外部（如 product_page 的 scroll listener）调用
  static void updateScrollSpeed(double speed) {
    _isScrollingFast = speed.abs() > 0.5;
  }

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _skipAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _checkAnimationStrategy();
  }

  void _checkAnimationStrategy() {
    // 1. 如果已经展示过，直接跳过动画
    if (AnimatedListItem._shownIndices.contains(widget.index)) {
      _controller.value = 1.0;
      _skipAnimation = true;
      return;
    }

    // 2. 标记为已展示
    AnimatedListItem._shownIndices.add(widget.index);

    // 3. 如果正在快速滚动，跳过动画
    if (AnimatedListItem._isScrollingFast) {
      _controller.value = 1.0;
      _skipAnimation = true;
      return;
    }

    // 4. 获取当前滚动速度
    final double speed = ScrollSpeedTracker.instance.speed.abs();

    // 5. 判断是否是首屏 (速度接近 0 认为是静止/首屏)
    final bool isIdle = speed < 0.1;

    if (isIdle) {
      // 首屏/静止：不播放动画，直接显示
      _controller.value = 1.0;
      _skipAnimation = true;
    } else {
      // 正在慢速滚动：播放动画
      _runAnimation(speed);
    }
  }

  void _runAnimation(double speed) {
    // 动态调整时长：滚得越快，动画越快 (防止用户等)
    Duration duration = const Duration(milliseconds: 400);
    Duration delay = Duration(milliseconds: (widget.index % 5) * 50);

    if (speed > 1.5) {
      duration = const Duration(milliseconds: 100);
      delay = Duration.zero;
    } else if (speed > 0.8) {
      duration = const Duration(milliseconds: 250);
      delay = Duration.zero;
    }

    _controller.duration = duration;

    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果跳过动画，直接返回子组件（减少 RepaintBoundary 层级）
    if (_skipAnimation) {
      return widget.child;
    }

    return RepaintBoundary(
      child: Animate(
        controller: _controller,
        autoPlay: false,
        effects: const [
          FadeEffect(curve: Curves.easeOutQuad),
          SlideEffect(
            begin: Offset(0, 0.1),
            end: Offset.zero,
            curve: Curves.easeOutQuad,
          ),
        ],
        child: widget.child,
      ),
    );
  }
}
