import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

/// Animated counting widget
class AnimeCount extends StatefulWidget {
  final num value;
  final String? prefix;
  final String? suffix;
  final TextStyle? textStyle;
  final Duration? duration;
  final Widget Function(num value)? render;
  final Curve curve;

  const AnimeCount({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.textStyle,
    this.duration,
    this.render,
    this.curve = Curves.easeOutCirc,
  });

  /// Gradient style with linear gradient shader
  static Widget gradient({
    required num value,
    String? prefix,
    String? suffix,
    TextStyle? textStyle,
    Duration? duration,
  }) {
    return Builder(
      builder: (context) {
        return AnimeCount(
          value: value,
          prefix: prefix,
          suffix: suffix,
          duration: duration,
          render: (display) {
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  colors: [context.textBrandPrimary900, context.textWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(rect);
              },
              child: Text(
                '${prefix ?? ''}$display${suffix ?? ''}',
                style: textStyle ??
                    TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: context.textWhite.withAlpha(100),
                          offset: const Offset(0, 0),
                          blurRadius: 12,
                        ),
                      ],
                    ),
              ),
            );
          },
        );
      },
    );
  }

  /// Odo style with animated switcher
  static Widget odo({
    required num value,
    String? prefix,
    String? suffix,
    TextStyle? textStyle,
    Duration? duration,
    Widget Function(num value)? render,
    Curve curve = Curves.easeOutCirc,
  }) {
    return Builder(
      builder: (context) {
        return AnimeCount(
          value: value,
          prefix: prefix,
          suffix: suffix,
          textStyle: textStyle,
          duration: duration,
          curve: curve,
          render: (val) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) {
                return ScaleTransition(scale: anim, child: child);
              },
              child: Text(
                '${prefix ?? ''}$val${suffix ?? ''}',
                key: ValueKey(value),
                style: textStyle ??
                    TextStyle(
                      fontSize: context.textXl,
                      fontWeight: FontWeight.w800,
                      color: context.textBrandPrimary900,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<AnimeCount> createState() => _AnimeCountState();
}

class _AnimeCountState extends State<AnimeCount> {
  late num _oldValue;

  @override
  void initState() {
    super.initState();
    // 初次渲染：旧值 = 当前值（避免从 0 突然跳上来）
    _oldValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimeCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的 value 变化时，记录一下「之前的值」
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
    }
  }

  Duration _calcDuration(num oldVal, num newVal) {
    final diff = (newVal - oldVal).abs();
    // 差值越大，时间越长，控制在 0.5s ~ 5s 之间
    final seconds = math.min(5, math.max(0.5, diff / 100));
    return Duration(milliseconds: (seconds * 1000).round());
  }

  @override
  Widget build(BuildContext context) {
    final begin = _oldValue.toDouble();
    final end = widget.value.toDouble();

    return TweenAnimationBuilder<num>(
      tween: Tween(begin: begin, end: end),
      duration: widget.duration ?? _calcDuration(begin, end),
      curve: widget.curve,
      builder: (context, num val, child) {
        final rounded = val.round();

        // 自定义渲染（比如渐变、AnimatedSwitcher 这些）
        if (widget.render != null) {
          return widget.render!(rounded);
        }

        // 默认样式
        return Text(
          '${widget.prefix ?? ''}$rounded${widget.suffix ?? ''}',
          style: widget.textStyle ??
              TextStyle(
                fontSize: context.textXl,
                fontWeight: FontWeight.bold,
                color: context.textBrandPrimary900,
              ),
        );
      },
    );
  }
}