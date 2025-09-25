
import 'package:flutter/cupertino.dart';

/// A simple wrapper around Navigator to provide global navigation methods.
/// Usage:
/// 1. Set `navigatorKey` in MaterialApp/CupertinoApp.
/// 2. Use `AppRouter.push`, `AppRouter.replace`, `AppRouter.pop` for navigation.
/// 3. This avoids the need to pass BuildContext around.
class AppRouter {
  // it is important to use a global key for navigator
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<T?> push<T> (String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> replace<T> (String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T, T>(routeName, arguments: arguments);
  }

  static void pop<T extends Object?>([ T? result ]) {
    return navigatorKey.currentState!.pop<T>(result);
  }
}