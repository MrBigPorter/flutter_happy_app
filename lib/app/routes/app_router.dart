
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/deposit_page.dart';
import 'package:flutter_app/app/page/group_member_page.dart';
import 'package:flutter_app/app/page/group_room_page.dart';
import 'package:flutter_app/app/page/kyc_verify_page.dart';
import 'package:flutter_app/app/page/order_list_page.dart';
import 'package:flutter_app/app/page/page_404.dart';
import 'package:flutter_app/app/page/payment_page.dart';
import 'package:flutter_app/app/page/product_group_page.dart';
import 'package:flutter_app/app/page/setting_page.dart';
import 'package:flutter_app/app/routes/route_auth_config.dart';
import 'package:flutter_app/app/routes/transitions.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/progress/overlay_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../components/lucky_tab_bar.dart';
import '../page/deposit_detail_page.dart';
import '../page/group_lobby_page.dart';
import '../page/guide_page.dart';
import '../page/home_page.dart';
import '../page/product_page.dart';
import '../page/transaction/transaction_ui_model.dart';
import '../page/transaction_record_page.dart';
import '../page/winners_page.dart';
import '../page/me_page.dart';
import '../page/login_page.dart';
import '../page/product_detail_page.dart';
import '../page/withdraw_page.dart';

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

        // 这样 /product/123 会先被这里匹配，而不会被误认为是 ShellRoute 里的 /product
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
              name: 'groups',
              path: '/groups',
              builder: (context, state) => GroupLobbyPage(),
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
            name: 'productGroup',
            path: '/product/:id/group',
            pageBuilder: (ctx, state) {
              final  id = state.pathParameters['id'] ?? '';
              return fxPage(
                key: state.pageKey,
                child: ProductGroupPage(treasureId: id),
                fx: RouteFx.slideUp,
              );
            }
        ),
        GoRoute(
            name: 'groupRoom',
            path: '/group-room',
            pageBuilder: (ctx, state) {
              final  id = state.uri.queryParameters['groupId'];
              return fxPage(
                key: state.pageKey,
                child: GroupRoomPage(groupId: id ?? ''),
                fx: RouteFx.slideUp,
              );
            }
        ),
        GoRoute(
            name: 'groupMember',
            path: '/group-member',
            pageBuilder: (ctx, state) {
              final id = state.uri.queryParameters['groupId'] ?? '';
              return fxPage(
                key: state.pageKey,
                child: GroupMemberPage(groupId:id),
                fx: RouteFx.slideUp,
              );
            }
        ),
        GoRoute(
          name:'payment',
           path: '/payment',
           pageBuilder: (ctx, state){

            final  queryParams = state.uri.queryParameters;
            final PagePaymentParams params = (
            entries: queryParams['entries'],
            treasureId: queryParams['treasureId'],
            paymentMethod: queryParams['paymentMethod'] ?? '1',

            // groupId 如果是 null，代表"开团"；如果是字符串，代表"参团"
            groupId: queryParams['groupId'],

            // 只有接收到这个参数，PaymentPage 才知道这是"开团"行为
            isGroupBuy: queryParams['isGroupBuy'],
            );
            return fxPage(
                child: PaymentPage(params: params),
                key: state.pageKey,
                fx: RouteFx.slideUp
            );
           }
        ),
        GoRoute(
          name:"orderList",
          path:'/order/list',
          builder: (context,state){
            final queryParams = state.uri.queryParameters;
            return OrderListPage(args: queryParams,);
          }
        ),
        GoRoute(
            name: 'guide',
            path: '/guide',
            builder: (context, state) => GuidePage()
        ),
        GoRoute(
            name: 'setting',
            path: '/setting',
            builder: (context, state) => SettingPage()
        ),
        GoRoute(
            name: 'kycVerify',
            path: '/me/kyc/verify',
            builder: (context, state) => KycVerifyPage()
        ),
        GoRoute(
            name: 'deposit',
            path: '/me/wallet/deposit',
            builder: (context, state) => DepositPage()
        ),
        GoRoute(
            name: 'transactionRecord',
            path: '/me/wallet/transaction/record',
            builder: (context, state){
              final tab = state.uri.queryParameters['tab'];
              final type = tab == 'withdraw' ? UiTransactionType.withdraw : UiTransactionType.deposit;
              return TransactionHistoryPage(initialType: type);
            }
        ),
        GoRoute(
            name: 'withdraw',
            path: '/me/wallet/withdraw',
            builder: (context, state) => WithdrawPage()
        ),
        GoRoute(
          name: 'product-groups-detail',
          path: '/product-groups',
          pageBuilder: (ctx, state) {
            String? id = state.uri.queryParameters['treasureId'];
            return fxPage(
              key: state.pageKey,
              child: GroupLobbyPage(treasureId: id,),
              fx: RouteFx.slideUp,
            );
          },
        ),
      ],
      redirect: (context,state){
        // 1. 获取当前尝试访问的完整路径
        final String path = state.uri.toString();

        //  核心修复：拦截 luckyapp:// 开头的分享链接
        // 只要是 luckyapp://product/ 开头，马上把它修正成内部路由 /product-detail/
        if (path.startsWith('luckyapp://product/')) {
          // 比如: luckyapp://product/123?groupId=abc
          // 变成: /product/123?groupId=abc
          final newPath = path.replaceFirst('luckyapp://product/', '/product/');

          print("🔀 自动修正分享链接: $path -> $newPath");
          return newPath;
        }


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
      },
      errorPageBuilder: (context, state) {
        // 重置全局进度条
        print("🚨 404 Error: ${state.uri.toString()}");
        Future.microtask(() {
          ref.read(overlayProgressProvider.notifier).state = 0.0;
        });
        return fxPage(
          key: state.pageKey,
          child: Page404(),
          fx: RouteFx.fadeThrough,
        );
      },

    );

    // assign to the global instance, so that other parts of the app can access it
    appRouter = router;
    return router;
  }
}

