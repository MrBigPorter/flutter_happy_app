import 'package:flutter/material.dart';
import '../base/animation_policy_config.dart';

/// AnimatedSheetWrapper
/// ------------------------------------------------------------------
/// A bottom sheet animation wrapper component with the following features:
/// - Support fade + slide animation
/// - Support custom duration and curve
/// - Support blur background and particle effects (optional)
/// ------------------------------------------------------------------
/// Usage:
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
      begin: const Offset(0, 0.04), // Slide in from bottom
      end: Offset.zero,
    ).animate(_fade);

    // Delayed execution to avoid system animation startup phase
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

    Widget animated = SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: widget.child,
      ),
    );

    return animated;
  }
}

/// ------------------------------------------------------------------
/// Simple particle layer (visual enhancement only, low cost)
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
    )
      ..repeat(reverse: true);
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
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 + 0.15 * (1 - progress));
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