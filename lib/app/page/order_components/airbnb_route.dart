import 'package:flutter/material.dart';

class AirbnbRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  AirbnbRoute({required this.child})
      : super(
    opaque: false, // keeps previous route visible
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}