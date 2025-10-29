import 'package:flutter/material.dart';

enum AnimationStyleConfig {
  minimal,
  celebration,
}

class AnimationPolicyConfig {
  final AnimationStyleConfig style;
  final Duration inDuration;
  final Duration outDuration;
  final Curve inCurve;
  final Curve outCurve;
  final bool allowBackgroundClose;
  final bool enableDragToClose;
  final double blurSigma;
  final bool enableParticles;

  const AnimationPolicyConfig({
    this.style = AnimationStyleConfig.minimal,
    this.inDuration = const Duration(milliseconds: 300),
    this.outDuration = const Duration(milliseconds: 200),
    this.inCurve = Curves.easeOut,
    this.outCurve = Curves.easeIn,
    this.allowBackgroundClose = true,
    this.enableDragToClose = true,
    this.blurSigma = 0.0,
    this.enableParticles = false,
  });

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
  AnimationPolicyConfig mergeGlobal(AnimationPolicyConfig? g){
    if(g == null) return this;
    // 仅当全局的 style 与当前一致时，才用它来微调参数；避免把庆祝改成极简或反之
    if(g.style != style) return this;
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