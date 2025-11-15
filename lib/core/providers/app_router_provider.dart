import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// AppRouterProvider - A Riverpod provider for the application's GoRouter instance
/// This provider creates and exposes the GoRouter instance used for navigation throughout the app.
/// Usage:
/// ```dart
/// final router = ref.watch(appRouterProvider);
/// ```
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.create(ref);
});
