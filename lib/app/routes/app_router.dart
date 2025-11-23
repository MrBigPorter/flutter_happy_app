import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/payment_page.dart';
import 'package:flutter_app/app/page/wallet_detail_page.dart';
import 'package:flutter_app/app/routes/route_auth_config.dart';
import 'package:flutter_app/app/routes/transitions.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// application router
/// Defines the application's routing structure and navigation logic.
/// - Uses GoRouter for route management.
/// - Integrates with Riverpod for state management.
/// - Supports authentication-based redirection.
/// - Manages modal dialogs with a global navigator key.
/// - Implements custom page transitions for specific routes.
///
class AppRouter {

  static GoRouter create(Ref ref) {
    final router =  GoRouter(
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
              final  queryParams = state.uri.queryParameters;
              return fxPage(
                key: state.pageKey,
                child: ProductDetailPage(productId: id,queryParams:queryParams),
                fx: RouteFx.zoomIn,
              );
            }
        ),
        GoRoute(
          name:'payment',
           path: '/payment',
           pageBuilder: (ctx, state){

            final  queryParams = state.uri.queryParameters;
            final PagePaymentParams params = (
              entries: queryParams['entries'] ?? '',
              treasureId: queryParams['treasureId']?? '',
              paymentMethod: queryParams['paymentMethod'] ?? '1',
              groupId: queryParams['groupId'] ?? '',
            );
            return fxPage(
                child: PaymentPage(params: params),
                key: state.pageKey,
                fx: RouteFx.slideUp
            );
           }
        )
      ],
      redirect: (context,state){

        // get the current path
        final path = state.uri.path;

        // check if the user is authenticated
        final isAuthenticated = ref.read(authProvider.select( (auth) => auth.isAuthenticated ));


        // check if the current path requires login
        final bool needLogin = RouteAuthConfig.needLoginForPath(path);

        // if the user is not authenticated and trying to access a protected route, redirect to login
        if(needLogin && !isAuthenticated){
          return '/login';
        }

        if(isAuthenticated && path == '/login'){
          // If the user is authenticated and tries to access the login page, redirect to home
          return '/home';
        }
        
        // Add global redirect logic here
        return null;
      }
    );

    // assign to the global instance, so that other parts of the app can access it
    appRouter = router;
    return router;
  }
}