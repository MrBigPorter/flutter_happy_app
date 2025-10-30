import 'package:flutter/material.dart';

/// Animation style configuration for modal sheets
enum AnimationStyleConfig {
  /// Minimal animation style with basic transitions
  minimal, // 平滑淡入
  /// Celebration animation style with particles and enhanced effects
  celebration,// 丰富动画效果
  fadeScale, // 淡入放大
  dropDown, // 从顶部下落
  bounce, // 弹性放大
  flip3D, // 3D翻转
  shake, // 左右震动
  slam,//  重击落下 回弹
}

/// Configuration for modal sheet animations and behavior
class AnimationPolicyConfig {
  /// The animation style to use (minimal or celebration)
  final AnimationStyleConfig style;

  /// Duration for the sheet entrance animation
  final Duration inDuration;

  /// Duration for the sheet exit animation
  final Duration outDuration;

  /// Curve for the entrance animation
  final Curve inCurve;

  /// Curve for the exit animation
  final Curve outCurve;

  /// Whether tapping the background closes the sheet
  final bool allowBackgroundClose;

  /// Whether dragging down can close the sheet
  final bool enableDragToClose;

  /// Blur sigma value for background effects
  final double blurSigma;

  /// Whether to show celebration particle effects
  final bool enableParticles;

  /// Creates an animation policy configuration
  const AnimationPolicyConfig({
    this.style = AnimationStyleConfig.dropDown,
    this.inDuration = const Duration(milliseconds: 300),
    this.outDuration = const Duration(milliseconds: 200),
    this.inCurve = Curves.easeOut,
    this.outCurve = Curves.easeIn,
    this.allowBackgroundClose = true,
    this.enableDragToClose = true,
    this.blurSigma = 12.0,
    this.enableParticles = false,
  });

  /// Creates a copy with some fields replaced with new values
  AnimationPolicyConfig copyWith({
    AnimationStyleConfig? style,
    Duration? inDuration,
    Duration? outDuration,
    Curve? inCurve,
    Curve? outCurve,
    bool? allowBackgroundClose,
    bool? enableDragToClose,
    double? blurSigma,
    bool? enableParticles,
  }) {
    return AnimationPolicyConfig(
      style: style ?? this.style,
      inDuration: inDuration ?? this.inDuration,
      outDuration: outDuration ?? this.outDuration,
      inCurve: inCurve ?? this.inCurve,
      outCurve: outCurve ?? this.outCurve,
      allowBackgroundClose: allowBackgroundClose ?? this.allowBackgroundClose,
      enableDragToClose: enableDragToClose ?? this.enableDragToClose,
      blurSigma: blurSigma ?? this.blurSigma,
      enableParticles: enableParticles ?? this.enableParticles,
    );
  }
}

extension _Merge on AnimationPolicyConfig {
  AnimationPolicyConfig mergeGlobal(AnimationPolicyConfig? g) {
    if (g == null) return this;
    // 仅当全局的 style 与当前一致时，才用它来微调参数；避免把庆祝改成极简或反之
    if (g.style != style) return this;
    return copyWith(
      inDuration: g.inDuration,
      outDuration: g.outDuration,
      inCurve: g.inCurve,
      outCurve: g.outCurve,
      allowBackgroundClose: g.allowBackgroundClose,
      enableDragToClose: g.enableDragToClose,
      blurSigma: g.blurSigma,
      enableParticles: g.enableParticles,
    );
  }
}
