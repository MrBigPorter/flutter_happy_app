import 'package:flutter/material.dart';


class TransparentFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;

  TransparentFadeRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
    opaque: false, // 关键：保持上一页可见
    barrierColor: Colors.transparent, // 关键：不使用系统遮罩，由子页面自己处理
    transitionDuration: duration,
    reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.8).round()),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart, // 进场快
          reverseCurve: Curves.easeIn, // 退场柔
        ),
        child: child,
      );
    },
  );
}