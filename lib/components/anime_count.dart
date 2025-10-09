import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'dart:math' as math;

/// Animated counting widget
///
class AnimeCount extends StatelessWidget {
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
  /// Example:
  /// ```dart
  /// AnimeCount.gradient(
  /// value: 12345,
  /// prefix: '\$',
  /// suffix: ' USD',
  /// textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold
  /// color: Colors.orangeAccent),
  /// duration: Duration(seconds: 2),
  /// curve: Curves.easeInOut,
  /// )
  /// ```
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
                '${prefix??''}$display${suffix??''}',
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
  /// Example:
  /// ```dart
  /// AnimeCount.odo(
  ///  value: 12345,
  ///  prefix: '\$',
  ///  suffix: ' USD',
  ///  textStyle: TextStyle(fontSize: 24, color: Colors.green),
  ///  duration: Duration(seconds: 2),
  ///  curve: Curves.easeInOut,
  ///  )
  ///  ```
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
      builder: (context){
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
                style:
                textStyle ??
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
      curve: curve,
      builder: (context, num val, child) {
        final rounded = val.round();
        if (render != null) {
          return render!(rounded);
        }
        return Text(
          '${prefix ?? ''}$rounded${suffix ?? ''}',
          style:
              textStyle ??
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
