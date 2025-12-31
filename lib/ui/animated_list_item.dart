import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/utils/animation_helper.dart';

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

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 创建控制器，但不自动播放
    _controller = AnimationController(vsync: this);

    // ✨ 核心优化：在初始化时直接判断，而不监听滚动流
    _checkAnimationStrategy();
  }

  void _checkAnimationStrategy() {
    // 1. 如果已经展示过，直接跳过动画
    if (AnimatedListItem._shownIndices.contains(widget.index)) {
      _controller.value = 1.0; // 直接显示
      return;
    }

    // 2. 获取当前滚动速度
    final double speed = ScrollSpeedTracker.instance.speed.abs();

    // 3. 判断是否是首屏 (速度接近 0 认为是静止/首屏)
    // 阈值设小一点，防止误判
    final bool isIdle = speed < 0.1;

    // 标记为已展示
    AnimatedListItem._shownIndices.add(widget.index);

    if (isIdle) {
      // 🛑 首屏/静止：不播放动画，直接显示
      _controller.value = 1.0;
    } else {
      // ▶️ 正在滚动：播放动画
      _runAnimation(speed);
    }
  }

  void _runAnimation(double speed) {
    // 动态调整时长：滚得越快，动画越快 (防止用户等)
    Duration duration = const Duration(milliseconds: 400);
    Duration delay = Duration(milliseconds: (widget.index % 5) * 50); // 简单的交错效果

    if (speed > 1.5) {
      duration = const Duration(milliseconds: 100);
      delay = Duration.zero;
    } else if (speed > 0.8) {
      duration = const Duration(milliseconds: 250);
      delay = Duration.zero;
    }

    // 设置动画时长并播放
    _controller.duration = duration;

    // 使用 Future.delayed 实现交错，比 Animation delay 更轻量
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
    // ✨ 性能优化：加 RepaintBoundary
    // 动画执行时只会重绘这个 Item，不会影响整个列表
    return RepaintBoundary(
      child: Animate(
        controller: _controller,
        autoPlay: false, // 手动控制
        effects: const [
          FadeEffect(curve: Curves.easeOutQuad),
          SlideEffect(
            begin: Offset(0, 0.1), // 稍微向下偏移 10%
            end: Offset.zero,
            curve: Curves.easeOutQuad,
          ),
          // 移除了 Scale 效果，Scale 在低端机上比较耗性能
        ],
        child: widget.child,
      ),
    );
  }
}