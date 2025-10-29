// app/routes/app_router.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/wallet_detail_page.dart';
import 'package:flutter_app/app/routes/transitions.dart';
import 'package:flutter_app/ui/modal/modal_service.dart';
import 'package:go_router/go_router.dart';

import '../../components/lucky_tab_bar.dart';
import '../page/home_page.dart';
import '../page/product_page.dart';
import '../page/winners_page.dart';
import '../page/me_page.dart';
import '../page/login_page.dart';
import '../page/product_detail_page.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {

  static final GoRouter router = GoRouter(
    //让全局弹层系统使用同一个 Navigator：
    // allow the global modal system to use the same Navigator:
    navigatorKey: ModalService.instance.navigatorKey,
    // 监听路由变化以关闭弹层：
    // observe route changes to close modals:
    observers: [
      ModalService.instance.routeObserver
    ],
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>  const LoginPage(id: '1')
      ),

      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => LuckyTabBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/product',
            builder: (context, state) => ProductPage(),
          ),
          GoRoute(
            path: '/winners',
            builder: (context, state) =>const WinnersPage(),
          ),
          GoRoute(
            path: '/me',
            builder: (context, state) =>const MePage(),
          ),
        ],
      ),
      GoRoute(
          path: '/winners/:id',
          pageBuilder: (ctx,state){
            final id = state.pathParameters['id']!;
            return fxPage(
                key: state.pageKey,
                child: WinnerDetailPage(winnerId: id),
                fx: RouteFx.sharedScale
            );
          }
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (ctx, state) {
          return fxPage(
            key: state.pageKey,
            child: ProductDetailPage(),
            fx: RouteFx.sharedScale,
          );
        }
      )
    ],
  );
}