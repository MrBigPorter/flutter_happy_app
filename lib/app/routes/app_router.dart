// app/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../components/lucky_tab_bar.dart';
import '../page/home_page.dart';
import '../page/product_page.dart';
import '../page/winners_page.dart';
import '../page/me_page.dart';
import '../page/login_page.dart';

class AppRouter {
  // 统一“推开”动效（iOS 原生样式）：新页在上方从右滑入；旧页在下方轻微左移并暗一点
  static Page<T> _iosPush<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    // CupertinoPage 自带 iOS push 转场（包含旧页的 secondary 动画），
    // 视觉上就是你要的“新页把旧页推开”的效果，且不会出现旧页盖在上面的闪烁。
    return CupertinoPage<T>(
      key: state.pageKey,
      child: child,
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    // 如需禁用 Hero 带来的交叉转场，可加 observers: [HeroController()]
    routes: [
      // 登录页也复用同一动效
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _iosPush(state: state, child: const LoginPage(id: '1')),
      ),

      // 底部 Tab 外壳不做动画（非常重要，否则会叠加两层动画造成“旧页停顿可见”）
      ShellRoute(
        builder: (context, state, child) => LuckyTabBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                _iosPush(state: state, child: const HomePage()),
          ),
          GoRoute(
            path: '/product',
            pageBuilder: (context, state) =>
                _iosPush(state: state, child: const ProductPage()),
          ),
          GoRoute(
            path: '/winners',
            pageBuilder: (context, state) =>
                _iosPush(state: state, child: const WinnersPage()),
          ),
          GoRoute(
            path: '/me',
            pageBuilder: (context, state) =>
                _iosPush(state: state, child: const MePage()),
          ),
        ],
      ),
    ],
  );
}