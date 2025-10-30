import 'package:flutter/animation.dart';
import 'package:flutter_app/ui/modal/base/animation_policy_config.dart';

class AnimationPolicyResolver {
  static AnimationPolicyConfig resolve({
    AnimationStyleConfig? businessStyle,
    AnimationPolicyConfig? globalPolicy,
  }) {
    final style = businessStyle ?? globalPolicy?.style ?? AnimationStyleConfig.minimal;
    switch (style) {
      case AnimationStyleConfig.celebration:
        return _celebration();
      case AnimationStyleConfig.bounce:
      case AnimationStyleConfig.flip3D:
        return AnimationPolicyConfig(
          inDuration: const Duration(milliseconds: 500),
          outDuration: const Duration(milliseconds: 250),
          style: businessStyle ?? AnimationStyleConfig.bounce,
          blurSigma: 12.0
        );
      case AnimationStyleConfig.minimal:
        return _minimal();
        default:
          return AnimationPolicyConfig(
            inDuration: const Duration(milliseconds: 300),
            outDuration: const Duration(milliseconds: 200),
            style: businessStyle ?? AnimationStyleConfig.minimal,
          );
    }
  }

  static AnimationPolicyConfig _minimal() => const AnimationPolicyConfig(
    style: AnimationStyleConfig.minimal,
    inDuration: Duration(milliseconds: 280),
    outDuration: Duration(milliseconds: 200),
    inCurve: Curves.easeOutCubic,
    outCurve: Curves.easeInCubic,
    allowBackgroundClose: true,
    enableDragToClose: true,
    blurSigma: 0.0,
    enableParticles: false,
  );

  static AnimationPolicyConfig _celebration() => const AnimationPolicyConfig(
    style: AnimationStyleConfig.celebration,
    inDuration: Duration(milliseconds: 600),
    outDuration: Duration(milliseconds: 400),
    inCurve: Curves.elasticOut,
    outCurve: Curves.easeInOutBack,
    allowBackgroundClose: false,
    enableDragToClose: false,
    blurSigma: 16.0,
    enableParticles: true,
  );
}

