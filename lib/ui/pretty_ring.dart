

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

class PrettyRing extends StatelessWidget {
  final double progress; // 0..1
  final double size;
  final double stroke;
  final List<Color> colors;
  final Color? trackColor;

  const PrettyRing({
    super.key,
    required this.progress,
    this.size = 24,
    this.stroke = 3,
    this.colors = const [
      Color(0xFFFF7A7A),
      Color(0xFFFF3D3D),
      Color(0xFFFF8A00),
    ],
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final track = trackColor ?? context.bgSecondary;

    // 轻微平滑，避免抖动
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      builder: (_, v, __) {
        return CustomPaint(
          size: Size.square(size),
          painter: _PrettyRingPainter(
            progress: v,
            stroke: stroke,
            colors: colors,
            trackColor: track,
          ),
        );
      },
    );
  }
}

class _PrettyRingPainter extends CustomPainter {
  final double progress; // 0..1
  final double stroke;
  final List<Color> colors;
  final Color trackColor;

  _PrettyRingPainter({
    required this.progress,
    required this.stroke,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    // 背景轨道
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    // 渐变进度
    final rect = Rect.fromCircle(center: center, radius: radius);
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: colors,
    ).createShader(rect);

    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = shader;

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, prog);
  }

  @override
  bool shouldRepaint(covariant _PrettyRingPainter old) =>
      old.progress != progress ||
          old.stroke != stroke ||
          old.trackColor != trackColor ||
          old.colors != colors;
}