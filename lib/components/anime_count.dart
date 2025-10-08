import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'dart:math' as math;

class AnimeCount extends StatelessWidget {
  final num value;
  final String? prefix;
  final String? suffix;
  final TextStyle? textStyle;
  final Duration? duration;
  final Widget Function(num value)? render;

  const AnimeCount({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.textStyle,
    this.duration,
    this.render,
  });

  Duration _calcDuration(num oldVal, num newVal) {
    final diff = (newVal - oldVal).abs();
    final seconds = math.min(5, math.max(0.5, diff / 100));
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<num>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration ?? _calcDuration(0, value),
      curve: Curves.easeOutCirc,
      builder: (context, num val, child) {
        final rounded = val.round();
        final display = render?.call(rounded) ?? _AnimeText(text: rounded);
        return display;
      },
    );
  }
}

class _AnimeText extends StatelessWidget {
  final int text;
  final TextStyle? textStyle;
  final Duration? duration;

  const _AnimeText({required this.text, this.textStyle, this.duration});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.0 + 0.08 * math.sin(text/5),
      child: Text(
        "$text",
        style: TextStyle(
          fontSize: context.textXl,
          color: context.fgBrandPrimary,
          fontWeight: FontWeight.w800,
        ).merge(textStyle),
      ),
    );
  }
}
