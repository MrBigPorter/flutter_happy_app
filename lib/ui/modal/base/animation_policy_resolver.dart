import 'package:flutter/animation.dart';
import 'package:flutter_app/ui/modal/base/animation_policy_config.dart';

/// Animation policy resolver for modal UI components.
/// Resolves animation and behavior configuration based on style and global policy.
class AnimationPolicyResolver {
  /// Resolves the final animation policy config by combining business style and global policy.
  ///
  /// Parameters:
  /// - [businessStyle] - The animation style specific to business logic
  /// - [globalPolicy] - The global animation policy configuration
  ///
  /// Returns an [AnimationPolicyConfig] with resolved settings.
  static AnimationPolicyConfig resolve({
    AnimationStyleConfig? businessStyle,
    AnimationPolicyConfig? globalPolicy,
  }) {
    final style =
        businessStyle ?? globalPolicy?.style ?? AnimationStyleConfig.minimal;
    switch (style) {
      case AnimationStyleConfig.celebration:
        return _celebration();
      case AnimationStyleConfig.minimal:
        return _minimal();
    }
  }

  /// Creates minimal animation policy configuration with subtle animations.
  ///
  /// Features shorter durations and simple curves for a clean, functional feel.
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

  /// Creates celebration animation policy configuration with dramatic animations.
  ///
  /// Features longer durations, elastic curves and visual effects for celebratory moments.
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
