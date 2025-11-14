import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

/// Enumeration of different route transition effects.
/// - slideUp: Slide the new page up from the bottom. 详情页/编辑页/确认页 - detail/edit/confirm pages.
/// - zoomIn: Zoom in the new page from the center. 弹窗类页面 - popup-like pages.
/// - fadeThrough: Fade through transition between pages. 新旧内容关系弱 - weak relation between old and new content.
/// - sharedScale: Shared axis transition with scaling effect. 列表 → 详情特别顺滑 -list to detail is very smooth.
/// - sharedX: Shared axis transition along the horizontal axis. 列表 → 详情特别顺滑 -list to detail is very smooth.
/// - sharedY: Shared axis transition along the vertical axis. 列表 → 详情特别顺滑 -list to detail is very smooth.

enum RouteFx { slideUp, zoomIn, fadeThrough, sharedScale, sharedX, sharedY }

/// Creates a page with a custom transition effect.
/// [child]: The widget to be displayed on the page.
/// [key]: A unique key for the page.
/// [fx]: The transition effect to be used (default is sharedScale).
/// [inMs]: Duration for the transition when the page is pushed (default is 420
/// milliseconds).
/// [outMs]: Duration for the transition when the page is popped (default is 300
/// milliseconds).
/// Returns a [Page] with the specified transition effect.
/// Example usage:
/// ```dart
/// fxPage(
///  child: MyPageWidget(),
///  key: ValueKey('myPage'),
///  fx: RouteFx.zoomIn,
///  inMs: Duration(milliseconds: 500),
///  outMs: Duration(milliseconds: 400),
///  );
///  ```
///
Page<void> fxPage({
  required Widget child,
  required LocalKey key,
  RouteFx fx = RouteFx.sharedScale,
  Duration? inMs,
  Duration? outMs,
}) {
  final durIn = inMs ?? const Duration(milliseconds: 600);
  final durOut = outMs ?? const Duration(milliseconds: 420);

  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: durIn,
    reverseTransitionDuration: durOut,
    transitionsBuilder: (ctx, animation, secondary, child) {
      switch (fx) {
        case RouteFx.slideUp:
          final tween = Tween(
            begin: Offset(0, 0.35),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        case RouteFx.zoomIn:
          final s = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: s,
            child: FadeTransition(opacity: animation, child: child),
          );
        case RouteFx.fadeThrough:
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondary,
            child: child,
          );
        case RouteFx.sharedScale:
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.scaled,
            child: child,
          );
        case RouteFx.sharedX:
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        case RouteFx.sharedY:
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondary,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
      }
    },
  );
}
