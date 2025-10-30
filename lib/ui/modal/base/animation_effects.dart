import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/ui/modal/base/animation_policy_config.dart';

Widget buildModalTransition(
  // anim is 0.0 to 1.0 animation controller
  Animation<double> anim,
  // the child widget to animate
  Widget child,
  // animation style config
  AnimationStyleConfig style, {
  bool allowBgClose = true,
  double blurSigma = 12.0,
  Color barrierColor = const Color(0xAA000000),
  required BuildContext context,
}) {
  // Define curved animation for opacity
  final curved = CurvedAnimation(
    parent: anim,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  Widget modal;
  switch (style) {
    case AnimationStyleConfig.dropDown:
      modal = FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutBack,
                  reverseCurve: Curves.easeInCubic,
                ),
              ),
          child: child,
        ),
      );
      break;
    case AnimationStyleConfig.bounce:
      modal = FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: child,
        ),
      );
      break;
    case AnimationStyleConfig.flip3D:
      modal = AnimatedBuilder(
        animation: anim,
        builder: (ctx, _) {
          // Rotate around X axis from 90 degrees (pi/2) to 0
          // pi radians = 180 degrees 2pi = 360 degrees 4pi = 720 degrees
          final rotation = (1 - anim.value) * pi / 2;
          return Transform(
            transform: Matrix4.identity()
              //想要 3D 有立体感，就记得加 .setEntry(3, 2, 透视系数)。
              // 透视系数通常是一个很小的负数，常用 -0.001 或 -0.0005。
              ..setEntry(3, 2, 0.001)
              // rotateX 旋转
              // rotateY 旋转
              ..rotateY(rotation),
            // 旋转中心
            alignment: Alignment.center,
            child: Opacity(opacity: anim.value, child: child),
          );
        },
      );
      break;
    case AnimationStyleConfig.celebration:
      modal = FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: Curves.elasticOut,
              reverseCurve: Curves.easeInOutBack,
            ),
          ),
          child: child,
        ),
      );
      break;
    case AnimationStyleConfig.shake:
      modal = AnimatedBuilder(
          animation: anim,
          builder: (ctx, _) {
            // Shake effect: oscillate left and right with decreasing amplitude
            // pi * 2 180 degrees = 1 cycle， pi * 4 = 2 cycles，pi * 8 = 4 cycles
            //shin 0~1 1-0=1 0-1=-1
            final dx = sin(anim.value * pi * 8) * (1 - anim.value) * 8.0;
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child
            );
          }
      );
      break;
    case AnimationStyleConfig.slam:
      modal = AnimatedBuilder(
        animation: anim,
        builder: (ctx,_){
          // anim from 0.0 to 1.0
          // elasticOut let anim value 0~1 but always over 1 and back to 1
          final curve = Curves.elasticOut.transform(anim.value);
          // Move down from -200 to 0 and scale from 0.9 to 1.0
          // yOffset goes from -200 to 0, when curve is 0, yOffset is -200, when curve is 1, yOffset is 0
          final yOffset = (1 - curve) * -200;
          return Transform.translate(
            offset: Offset(0, yOffset),
            child: Transform.scale(
              scale: 0.9 + 0.1 * curve,
              child: child,
            ),
          );
        },
      );
      break;
      case AnimationStyleConfig.fadeScale:
        modal = FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.9 , end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeInCubic),
            ),
            child: child,
          ),
        );
    default:
      modal = FadeTransition(opacity: anim, child: child);
      break;
  }

  return Stack(
    fit: StackFit.expand,
    children: [
      // ① 背景：模糊 + 暗幕（用 anim.value 控制强度，不用 FadeTransition 包整屏）
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: allowBgClose ? () => Navigator.of(context).pop() : null,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma * anim.value,
            sigmaY: blurSigma * anim.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: Container(
              color: barrierColor.withValues(alpha: 0.35 * anim.value),
            ),
          ),
        ),
      ),
      Center(child: modal),
    ],
  );
}
