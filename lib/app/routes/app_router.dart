import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/wallet_detail_page.dart';
import 'package:flutter_app/app/routes/transitions.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:go_router/go_router.dart';

import '../../components/lucky_tab_bar.dart';
import '../page/home_page.dart';
import '../page/product_page.dart';
import '../page/winners_page.dart';
import '../page/me_page.dart';
import '../page/login_page.dart';
import '../page/product_detail_page.dart';

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
// 全局路由器实例  Global router instance
late GoRouter appRouter;

class AppRouter {

  static GoRouter create() {
    return GoRouter(
      debugLogDiagnostics: true,
      //让全局弹层系统使用同一个 Navigator：
      // allow the global modal system to use the same Navigator:
      navigatorKey: NavHub.key,
      // 监听路由变化以关闭弹层：
      // observe route changes to close modals:
      observers: [
        ModalManager.instance,
        ModalAutoCloseObserver()
      ],
      initialLocation: '/home',
      routes: [
        GoRoute(
            name:"login",
            path: '/login',
            builder: (context, state) =>   LoginPage()
        ),

        ShellRoute(
          navigatorKey: _shellKey,
          observers: [
            ModalAutoCloseObserver()
          ],
          builder: (context, state, child) => LuckyTabBar(child: child),
          routes: [
            GoRoute(
              name:'home',
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              name: 'product',
              path: '/product',
              builder: (context, state) => ProductPage(),
            ),
            GoRoute(
              name: 'winners',
              path: '/winners',
              builder: (context, state) =>const WinnersPage(),
            ),
            GoRoute(
              name: 'me',
              path: '/me',
              builder: (context, state) =>const MePage(),
            ),
          ],
        ),
        GoRoute(
            name: 'walletDetail',
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
            name: 'productDetail',
            path: '/product/:id',
            parentNavigatorKey: NavHub.key,
            pageBuilder: (ctx, state) {
              final id = state.pathParameters['id']!;
              return fxPage(
                key: state.pageKey,
                child: ProductDetailPage(productId: id,),
                fx: RouteFx.sharedScale,
              );
            }
        ),
      ],
    );
  }
}