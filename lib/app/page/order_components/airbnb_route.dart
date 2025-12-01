import 'package:flutter/material.dart';

class AirbnbRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  AirbnbRoute({required this.child})
      : super(
    opaque: false, // 保持透明，为了看到背景
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 500), // 稍微慢一点，配合 Hero 的飞行时间
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // ✅ 改为渐变：让背景黑罩慢慢浮现，而卡片的放大移动交给 Hero 处理
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut, // 渐入曲线
        ),
        child: child,
      );
    },
  );
}