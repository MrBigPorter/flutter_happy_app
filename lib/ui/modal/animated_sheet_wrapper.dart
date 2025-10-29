import 'dart:ui';
import 'package:flutter/material.dart';
import 'animation_policy_config.dart';

/// AnimatedSheetWrapper
/// ------------------------------------------------------------------
/// 底部弹窗动画包装组件 bottom sheet animation wrapper
/// - 支持淡入淡出 + 滑动动画 support fade + slide animation
/// - 支持自定义动画时长与曲线 support custom duration and curve
/// - 支持模糊背景与粒子特效（可选） support blur background and particle effects (optional)
/// ------------------------------------------------------------------
/// 用法：
/// ```dart
/// AnimatedSheetWrapper(
///  policy: animationPolicy,
///  child: YourSheetContent(),
///  );
///  ------------------------------------------------------------------
class AnimatedSheetWrapper extends StatefulWidget {
  final AnimationPolicyConfig policy;
  final Widget child;

  const AnimatedSheetWrapper({
    super.key,
    required this.policy,
    required this.child,
  });

  @override
  State<AnimatedSheetWrapper> createState() => AnimatedSheetWrapperState();
}

class AnimatedSheetWrapperState extends State<AnimatedSheetWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.policy.inDuration,
      reverseDuration: widget.policy.outDuration,
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: widget.policy.inCurve,
      reverseCurve: widget.policy.outCurve,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04), // 从下往上滑入
      end: Offset.zero,
    ).animate(_fade);

    // 延迟执行，避开系统动画启动阶段
    Future.delayed(const Duration(milliseconds: 160), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enableBlur = widget.policy.blurSigma > 0;
    final enableParticles = widget.policy.enableParticles;

    Widget animated = SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );

    // 模糊层 + 粒子层（仅当策略开启）
    if (enableBlur || enableParticles) {
      animated = Stack(
        children: [
          if (enableBlur)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.policy.blurSigma,
                sigmaY: widget.policy.blurSigma,
              ),
              child: Container(color: Colors.transparent),
            ),
          if (enableParticles)
            const _ParticleLayer(),
          animated,
        ],
      );
    }

    return animated;
  }
}

/// ------------------------------------------------------------------
/// 简易粒子层（仅视觉增强，低成本）
/// ------------------------------------------------------------------
class _ParticleLayer extends StatefulWidget {
  const _ParticleLayer();

  @override
  State<_ParticleLayer> createState() => _ParticleLayerState();
}

class _ParticleLayerState extends State<_ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return CustomPaint(
            painter: _ParticlePainter(_ctrl.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.1 + 0.15 * (1 - progress));
    for (int i = 0; i < 20; i++) {
      final dx = (size.width / 20) * i + (progress * 10);
      final dy = (size.height / 10) * (i % 10) * (1 - progress);
      canvas.drawCircle(Offset(dx, dy), 1.5 + progress * 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}