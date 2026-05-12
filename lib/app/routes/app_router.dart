import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/group_member_page.dart' deferred as _group_member;
import 'package:flutter_app/app/page/group_room_page.dart' deferred as _group_room;
import 'package:flutter_app/app/page/kyc_verify/kyc_verify_page.dart' deferred as _kyc_verify;
import 'package:flutter_app/app/page/order_list_page.dart' deferred as _order_list;
import 'package:flutter_app/app/page/page_404.dart' deferred as _page_404;
import 'package:flutter_app/app/page/payment/payment_page.dart' deferred as _payment hide PagePaymentParamsExt;
import 'package:flutter_app/app/page/product_group_page.dart' deferred as _product_group;
import 'package:flutter_app/app/page/setting_page.dart' deferred as _setting;
import 'package:flutter_app/app/page/treasure_coins_page.dart' deferred as _treasure_coins;
import 'package:flutter_app/app/routes/route_auth_config.dart';
import 'package:flutter_app/app/routes/transitions.dart';
import 'package:flutter_app/core/models/payment.dart';
import 'package:flutter_app/core/services/auth/global_oauth_handler.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/app/routes/deferred_page.dart';
import 'package:flutter_app/app/page/product_page_skeleton.dart';
import 'package:flutter_app/app/page/me_components/me_page_skeleton.dart';
import 'package:flutter_app/app/page/home_page_skeleton.dart';
import 'package:flutter_app/ui/chat/chat_search/chat_search_page.dart' deferred as _chat_search;
import 'package:flutter_app/ui/chat/conversation_list_page.dart' deferred as _chat;
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/ui/modal/base/modal_auto_close_observer.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_app/ui/modal/progress/overlay_progress_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/components/lucky_tab_bar.dart';
import 'package:flutter_app/ui/chat/chat_room/chat_page.dart' deferred as _chat_room;
import 'package:flutter_app/ui/chat/contact_list/contact_list_page.dart' deferred as _contact;
import 'package:flutter_app/ui/chat/contact_profile_page.dart' deferred as _contact_profile;
import 'package:flutter_app/ui/chat/contact_search_page.dart' deferred as _contact_search;
import 'package:flutter_app/ui/chat/group/group_member_select_page.dart' deferred as _group_member_select;
import 'package:flutter_app/ui/chat/new_friend_page.dart' deferred as _new_friend;
import 'package:flutter_app/app/page/deposit/deposit_page.dart' deferred as _deposit show DepositPage;
import 'package:flutter_app/app/page/deposit_detail_page.dart' deferred as _winner_detail;
import 'package:flutter_app/app/page/group_lobby/group_lobby_page.dart' deferred as _group_lobby;
import 'package:flutter_app/app/page/guide_page.dart' deferred as _guide;
import 'package:flutter_app/app/page/home_page.dart' deferred as _home;
import 'package:flutter_app/app/page/product_page.dart' deferred as _product;
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/app/page/transaction_record_page.dart' deferred as _transaction_record;
import 'package:flutter_app/app/page/me_components/me_page.dart' deferred as _me;
import 'package:flutter_app/app/page/login_page/login_page.dart';
import 'package:flutter_app/app/page/lucky_draw/lucky_draw_page.dart' deferred as _lucky_draw;
import 'package:flutter_app/app/page/oauth_processing_page/oauth_processing_page.dart' deferred as _oauth;
import 'package:flutter_app/app/page/pwa_debug_page.dart' deferred as _pwa_debug;
import 'package:flutter_app/app/page/product_detail_page.dart' deferred as _product_detail;
import 'package:flutter_app/app/page/withdraw/withdraw_page.dart' deferred as _withdraw hide WithdrawPageUI;
import 'package:flutter_app/app/page/lucky_draw/lucky_draw_wheel_page.dart' deferred as _lucky_draw_wheel;
import 'package:flutter_app/ui/chat/group/group_request_list/group_request_list_page.dart' deferred as _group_request;
import 'package:flutter_app/ui/chat/group/group_profile/group_profile_page.dart' deferred as _group_profile;
import '../../ui/chat/group/group_search/group_search_page.dart' deferred as _group_search;
import '../page/deposit/deposit_result_page.dart' deferred as _deposit_result;
import '../page/deposit/web_popup_auto_close.dart' deferred as _web_popup_auto_close;
import '../page/kyc_status_page.dart' deferred as _kyc_status;
import '../page/liveness_debug_page.dart' deferred as _liveness_debug;
import '../page/my_vouchers_page.dart' deferred as _my_vouchers;
import '../page/flash_sale/flash_sale_page.dart' deferred as _flash_sale;
import '../page/flash_sale/flash_sale_product_page.dart' deferred as _flash_sale_product;
import 'extra_codec.dart';
import 'package:flutter_app/ui/chat/direct_chat_settings_page.dart' deferred as _direct_chat_settings;
import 'package:flutter_app/ui/chat/local_contact_search_page.dart' deferred as _local_contact_search;
import 'package:flutter_app/ui/chat/models/selection_types.dart';
import 'package:flutter_app/ui/chat/selector/contact_selection_page.dart' deferred as _selector;

final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
// 全局路由器实例  Global router instance
late GoRouter appRouter;
bool isAppRouterReady = false; // 新增这一行：专门用来给 DeepLink 做状态指示灯

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// application router
/// Defines the application's routing structure and navigation logic.
/// - Uses GoRouter for route management.
/// - Integrates with Riverpod for state management.
/// - Supports authentication-based redirection.
/// - Manages modal dialogs with a global navigator key.
/// - Implements custom page transitions for specific routes.
///
class AppRouter {
  /// 集中注册所有需要支持序列化的参数类
  static void _registerRoutes() {
    // 以后每增加一个 Args 类，就在这里加一行
    RouteArgsRegistry.register(
      'ContactSelectionArgs',
      ContactSelectionArgs.fromJson,
    );

    // 示例：如果有其他页面参数
    // RouteArgsRegistry.register('PaymentParams', PaymentParams.fromJson);
  }

  static GoRouter create(Ref ref) {
    //  就在这里调用！确保在 GoRouter 初始化之前完成注册
    _registerRoutes();

    final router = GoRouter(
      debugLogDiagnostics: true,
      //让全局弹层系统使用同一个 Navigator：
      // allow the global modal system to use the same Navigator:
      navigatorKey: NavHub.key,

      //  3. 核心：在这里挂载公用的编解码器
      extraCodec: const CommonExtraCodec(),

      // 监听路由变化以关闭弹层：
      // observe route changes to close modals:
      observers: [
        routeObserver,
        ModalManager.instance,
        ModalAutoCloseObserver(),
        BotToastNavigatorObserver(),
      ],
      initialLocation: '/home',
      routes: [
        // 不带底部导航栏的页面 (全屏页)
        // 把 ChatPage 放在这里，和 ShellRoute 平级！
        GoRoute(
          path: '/chat/group/select/member',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) {
            final groupId = state.uri.queryParameters['groupId'];
            final preSelectedId = state.uri.queryParameters['preSelectedId'];
            return DeferredPage(
              loadLibrary: _group_member_select.loadLibrary,
              builder: () => _group_member_select.GroupMemberSelectPage(
                existingGroupId: groupId,
                preSelectedId: preSelectedId,
              ),
            );
          },
        ),
        GoRoute(
          path: '/chat/group/requests/:groupId',
          name: 'group_requests',
          builder: (context, state) {
            final groupId = state.pathParameters['groupId']!;
            return DeferredPage(
              loadLibrary: _group_request.loadLibrary,
              builder: () => _group_request.GroupRequestListPage(groupId: groupId),
            );
          },
        ),
        GoRoute(
          path: '/contact/search',
          name: 'contactSearch',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) => DeferredPage(
            loadLibrary: _contact_search.loadLibrary,
            builder: () => _contact_search.ContactSearchPage(),
          ),
        ),
        GoRoute(
          path: '/contact/local-search',
          name: 'contactLocalSearch',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) => DeferredPage(
            loadLibrary: _local_contact_search.loadLibrary,
            builder: () => _local_contact_search.LocalContactSearchPage(),
          ),
        ),
        GoRoute(
          path: '/contact/new-friends',
          name: 'newFriends',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) => DeferredPage(
            loadLibrary: _new_friend.loadLibrary,
            builder: () => _new_friend.NewFriendPage(),
          ),
        ),
        GoRoute(
          path: '/chat/group/profile/:id',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) {
            final cid = state.pathParameters['id']!;
            return DeferredPage(
              loadLibrary: _group_profile.loadLibrary,
              builder: () => _group_profile.GroupProfilePage(conversationId: cid),
            );
          },
        ),
        GoRoute(
          path: '/chat/group/search',
          name: 'group_search',
          builder: (context, state) => DeferredPage(
            loadLibrary: _group_search.loadLibrary,
            builder: () => _group_search.GroupSearchPage(),
          ),
        ),
        GoRoute(
          path: '/chat/search',
          name: 'chat_search',
          pageBuilder: (context, state) {
            final conversationId =
                state.uri.queryParameters['conversationId'] ?? '';
            // 预加载 chunk，不等待
            unawaited(_chat_search.loadLibrary());
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: () => Future<void>.value(),
                builder: () => _chat_search.ChatSearchPage(conversationId: conversationId),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          path: '/chat/contacts',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) => DeferredPage(
            loadLibrary: _contact.loadLibrary,
            builder: () => _contact.ContactListPage(),
          ),
        ),
        GoRoute(
          path: '/chat/direct/profile/:id',
          builder: (context, state) {
            final cid = state.pathParameters['id']!;
            return DeferredPage(
              loadLibrary: _direct_chat_settings.loadLibrary,
              builder: () => _direct_chat_settings.DirectChatSettingsPage(conversationId: cid),
            );
          },
        ),
        GoRoute(
          path: '/contact/profile/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            // 安全转换：extra 可能为 null（deep link / URL 直访），不能硬 cast
            final cachedUser = state.extra is ChatUser
                ? state.extra as ChatUser
                : null;

            return DeferredPage(
              loadLibrary: _contact_profile.loadLibrary,
              builder: () => _contact_profile.ContactProfilePage(userId: userId, cachedUser: cachedUser),
            );
          },
        ),
        GoRoute(
          path: '/contact/selector',
          pageBuilder: (context, state) {
            // 必须传递 extra 参数
            final args = state.extra is ContactSelectionArgs
                ? state.extra as ContactSelectionArgs
                : ContactSelectionArgs();
            // 预加载 chunk，不等待
            unawaited(_selector.loadLibrary());
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: () => Future<void>.value(),
                builder: () => _selector.ContactSelectionPage(args: args),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          path: '/chat/room/:conversationId',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) {
            return DeferredPage(
              loadLibrary: _chat_room.loadLibrary,
              builder: () => _chat_room.ChatPage(
                conversationId: state.pathParameters['conversationId']!,
              ),
            );
          },
        ),
        GoRoute(
          name: "login",
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),

        GoRoute(
          name: 'oauthProcessing',
          path: '/oauth/processing',
          builder: (context, state) => DeferredPage(
            loadLibrary: _oauth.loadLibrary,
            builder: () => _oauth.OauthProcessingPage(),
          ),
        ),

        // Deep Link OAuth callback route - handles token from backend
        GoRoute(
          name: 'oauthCallback',
          path: '/oauth/callback',
          builder: (context, state) {
            debugPrint('GoRouter: Deep Link OAuth callback route matched');
            debugPrint('Callback URL: ${state.uri}');
            
            // Extract token from URL parameters
            final token = state.uri.queryParameters['token'];
            final refreshToken = state.uri.queryParameters['refreshToken'];
            final stateParam = state.uri.queryParameters['state'];
            
            if (token != null) {
              debugPrint('Token received: ${token.substring(0, 20)}...');
              debugPrint('Refresh token: ${refreshToken?.substring(0, 20)}...');
              debugPrint('State: $stateParam');
              
              // 调用全局处理器处理 Deep Link OAuth 回调
              // 注意：这里需要异步处理，但路由 builder 是同步的
              // 所以使用 Future.microtask 在下一帧执行
              Future.microtask(() async {
                try {
                  // 从 URL 参数解析 provider（后端在 state 或 URL 中返回）
                  final provider = state.uri.queryParameters['provider'] ?? 'google';
                  
                  // 调用全局处理器保存 token
                  await GlobalOAuthHandler.handleDeepLinkOAuthCallback(
                    token: token,
                    refreshToken: refreshToken ?? '',
                    state: stateParam ?? '',
                    provider: provider,
                    navigateAfterSuccess: true,
                    showGlobalLoading: true,
                  );
                  
                  debugPrint('GoRouter: Deep Link OAuth processing completed');
                } catch (e, stackTrace) {
                  debugPrint('GoRouter: Deep Link OAuth processing failed: $e');
                  debugPrint('Stack trace: $stackTrace');
                  
                  // 即使处理失败，也重定向到首页（避免卡在回调页面）
                  if (context.mounted) {
                    context.go('/home');
                  }
                }
              });
            } else {
              // 无 token：可能是取消授权（error=cancelled）或其他错误
              final error = state.uri.queryParameters['error'];
              final provider = state.uri.queryParameters['provider'] ?? '';
              debugPrint('No token in callback URL, error=$error provider=$provider');
              Future.microtask(() {
                if (!context.mounted) return;
                // 取消授权 → 直接回登录页，不经过 /home 再被守卫跳回
                // 其他错误 → 同样回登录页，避免空白停留
                context.go('/login');
              });
            }
            
            // 返回空白页面，不显示额外的loading
            // GlobalOAuthHandler已经处理了全局loading
            return const SizedBox.shrink();
          },
        ),

        // Firebase OAuth callback route - returns empty container, Firebase SDK handles the callback
        GoRoute(
          path: '/__/auth/handler',
          builder: (context, state) {
            debugPrint('GoRouter: Firebase OAuth callback route matched');
            return const SizedBox.shrink();
          },
        ),

        // 这样 /product/123 会先被这里匹配，而不会被误认为是 ShellRoute 里的 /product
        GoRoute(
          name: 'productDetail',
          path: '/product-detail/:id',
          parentNavigatorKey: NavHub.key,
          pageBuilder: (ctx, state) {
            unawaited(_product_detail.loadLibrary());
            final id = state.pathParameters['id']!;
            final queryParams = state.uri.queryParameters;
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _product_detail.loadLibrary,
                builder: () => _product_detail.ProductDetailPage(productId: id, queryParams: queryParams),
              ),
              fx: RouteFx.zoomIn,
            );
          },
        ),

        ShellRoute(
          navigatorKey: _shellKey,
          observers: [ModalAutoCloseObserver()],
          builder: (context, state, child) => LuckyTabBar(child: child),
          routes: [
            GoRoute(
              name: 'home',
              path: '/home',
              builder: (context, state) => DeferredPage(
                loadLibrary: _home.loadLibrary,
                skeletonBuilder: () => const HomePageSkeleton(),
                builder: () => _home.HomePage(),
              ),
            ),
            GoRoute(
              name: 'product',
              path: '/product',
              builder: (context, state) => DeferredPage(
                loadLibrary: _product.loadLibrary,
                skeletonBuilder: () => const ProductPageSkeleton(),
                builder: () => _product.ProductPage(),
              ),
            ),
            GoRoute(
              name: 'conversations',
              path: '/conversations',
              builder: (context, state) => DeferredPage(
                loadLibrary: _chat.loadLibrary,
                builder: () => _chat.ConversationListPage(),
              ),
            ),
            GoRoute(
              name: 'me',
              path: '/me',
              builder: (context, state) => DeferredPage(
                loadLibrary: _me.loadLibrary,
                skeletonBuilder: () => const MePageSkeleton(),
                builder: () => _me.MePage(),
              ),
            ),
          ],
        ),
        GoRoute(
          name: 'walletDetail',
          path: '/winners/:id',
          pageBuilder: (ctx, state) {
            unawaited(_winner_detail.loadLibrary());
            final id = state.pathParameters['id']!;
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _winner_detail.loadLibrary,
                builder: () => _winner_detail.WinnerDetailPage(winnerId: id),
              ),
              fx: RouteFx.sharedScale,
            );
          },
        ),
        GoRoute(
          name: 'productGroup',
          path: '/product/:id/group',
          pageBuilder: (ctx, state) {
            unawaited(_product_group.loadLibrary());
            final id = state.pathParameters['id'] ?? '';
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _product_group.loadLibrary,
                builder: () => _product_group.ProductGroupPage(treasureId: id),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'meVoucher',
          path: '/me/voucher',
          pageBuilder: (ctx, state) {
            unawaited(_my_vouchers.loadLibrary());
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _my_vouchers.loadLibrary,
                builder: () => _my_vouchers.MyVouchersPage(),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'groupRoom',
          path: '/group-room',
          pageBuilder: (ctx, state) {
            unawaited(_group_room.loadLibrary());
            final id = state.uri.queryParameters['groupId'];
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _group_room.loadLibrary,
                builder: () => _group_room.GroupRoomPage(groupId: id ?? ''),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'groupMember',
          path: '/group-member',
          pageBuilder: (ctx, state) {
            unawaited(_group_member.loadLibrary());
            final id = state.uri.queryParameters['groupId'] ?? '';
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _group_member.loadLibrary,
                builder: () => _group_member.GroupMemberPage(groupId: id),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'payment',
          path: '/payment',
          pageBuilder: (ctx, state) {
            unawaited(_payment.loadLibrary());
            final queryParams = state.uri.queryParameters;
            final PagePaymentParams params = (
              entries: queryParams['entries'],
              treasureId: queryParams['treasureId'],
              paymentMethod: queryParams['paymentMethod'] ?? '1',
              flashSaleProductId: queryParams['flashSaleProductId'],

              // groupId 如果是 null，代表"开团"；如果是字符串，代表"参团"
              groupId: queryParams['groupId'],

              // 只有接收到这个参数，PaymentPage 才知道这是"开团"行为
              isGroupBuy: queryParams['isGroupBuy'],
            );
            return fxPage(
              child: DeferredPage(
                loadLibrary: _payment.loadLibrary,
                builder: () => _payment.PaymentPage(params: params),
              ),
              key: state.pageKey,
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: "orderList",
          path: '/order/list',
          builder: (context, state) {
            final queryParams = state.uri.queryParameters;
            return DeferredPage(
              loadLibrary: _order_list.loadLibrary,
              builder: () => _order_list.OrderListPage(args: queryParams),
            );
          },
        ),
        GoRoute(
          name: 'guide',
          path: '/guide',
          builder: (context, state) => DeferredPage(
            loadLibrary: _guide.loadLibrary,
            builder: () => _guide.GuidePage(),
          ),
        ),
        GoRoute(
          name: 'setting',
          path: '/setting',
          builder: (context, state) => DeferredPage(
            loadLibrary: _setting.loadLibrary,
            builder: () => _setting.SettingPage(),
          ),
        ),
        GoRoute(
          name: 'pwaDebug',
          path: '/debug/pwa',
          builder: (context, state) => DeferredPage(
            loadLibrary: _pwa_debug.loadLibrary,
            builder: () => _pwa_debug.PwaDebugPage(),
          ),
        ),
        GoRoute(
          name: 'luckyDraw',
          path: '/lucky-draw',
          builder: (context, state) {
            final initialTab = state.uri.queryParameters['tab'] == 'results'
                ? 1
                : 0;
            return DeferredPage(
              loadLibrary: _lucky_draw.loadLibrary,
              builder: () => _lucky_draw.LuckyDrawPage(initialTab: initialTab),
            );
          },
        ),
        GoRoute(
          name: 'luckyDrawWheel',
          path: '/lucky-draw/wheel/:ticketId',
          parentNavigatorKey: NavHub.key,
          builder: (context, state) {
            final ticketId = state.pathParameters['ticketId']!;
            return DeferredPage(
              loadLibrary: _lucky_draw_wheel.loadLibrary,
              builder: () => _lucky_draw_wheel.LuckyDrawWheelPage(ticketId: ticketId),
            );
          },
        ),
        GoRoute(
          name: 'flashSale',
          path: '/flash-sale',
          pageBuilder: (ctx, state) {
            unawaited(_flash_sale.loadLibrary());
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _flash_sale.loadLibrary,
                builder: () => _flash_sale.FlashSalePage(),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'flashSaleProduct',
          path: '/flash-sale/products/:id',
          pageBuilder: (ctx, state) {
            unawaited(_flash_sale_product.loadLibrary());
            final id = state.pathParameters['id']!;
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _flash_sale_product.loadLibrary,
                builder: () => _flash_sale_product.FlashSaleProductPage(flashSaleProductId: id),
              ),
              fx: RouteFx.zoomIn,
            );
          },
        ),
        GoRoute(
          name: 'kycStatus',
          path: '/me/kyc/status',
          builder: (context, state) => DeferredPage(
            loadLibrary: _kyc_status.loadLibrary,
            builder: () => _kyc_status.KycStatusPage(),
          ),
        ),
        GoRoute(
          name: 'kycVerify',
          path: '/me/kyc/verify',
          builder: (context, state) => DeferredPage(
            loadLibrary: _kyc_verify.loadLibrary,
            builder: () => _kyc_verify.KycVerifyPage(),
          ),
        ),
        GoRoute(
          name: 'deposit',
          path: '/me/wallet/deposit',
          builder: (context, state) => DeferredPage(
            loadLibrary: _deposit.loadLibrary,
            builder: () => _deposit.DepositPage(),
          ),
        ),
        GoRoute(
          name: 'walletRechargeFailure',
          path: '/wallet/recharge/failure/:orderNo',
          builder: (context, state) {
            final orderNo = state.pathParameters['orderNo'] ?? '';
            return DeferredPage(
              loadLibrary: _deposit_result.loadLibrary,
              builder: () => _deposit_result.DepositResultPage(orderNo: orderNo),
            );
          },
        ),
        GoRoute(
          name: 'walletRechargeSuccess',
          path: '/wallet/recharge/success/:orderNo',
          builder: (context, state) {
            final orderNo = state.pathParameters['orderNo'] ?? '';
            return DeferredPage(
              loadLibrary: _web_popup_auto_close.loadLibrary,
              builder: () => _web_popup_auto_close.WebPopupAutoClose(orderNo: orderNo),
            );
          },
        ),
        GoRoute(
          name: 'transactionRecord',
          path: '/me/wallet/transaction/record',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final type = tab == 'withdraw'
                ? UiTransactionType.withdraw
                : UiTransactionType.deposit;
            return DeferredPage(
              loadLibrary: _transaction_record.loadLibrary,
              builder: () => _transaction_record.TransactionHistoryPage(initialType: type),
            );
          },
        ),
        GoRoute(
          name: 'withdraw',
          path: '/me/wallet/withdraw',
          builder: (context, state) => DeferredPage(
            loadLibrary: _withdraw.loadLibrary,
            builder: () => _withdraw.WithdrawPage(),
          ),
        ),
        GoRoute(
          name: 'treasureCoins',
          path: '/me/wallet/coins',
          pageBuilder: (ctx, state) {
            unawaited(_treasure_coins.loadLibrary());
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _treasure_coins.loadLibrary,
                builder: () => _treasure_coins.TreasureCoinsPage(),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
        GoRoute(
          name: 'debug-liveness',
          path: '/me/kyc/debug-liveness',
          builder: (context, state) => DeferredPage(
            loadLibrary: _liveness_debug.loadLibrary,
            builder: () => _liveness_debug.LivenessDebugPage(),
          ),
        ),
        GoRoute(
          name: 'product-groups-detail',
          path: '/product-groups',
          pageBuilder: (ctx, state) {
            unawaited(_group_lobby.loadLibrary());
            String? id = state.uri.queryParameters['treasureId'];
            return fxPage(
              key: state.pageKey,
              child: DeferredPage(
                loadLibrary: _group_lobby.loadLibrary,
                builder: () => _group_lobby.GroupLobbyPage(treasureId: id),
              ),
              fx: RouteFx.slideUp,
            );
          },
        ),
      ],
      redirect: (context, state) {
        final uri = state.uri;

        // 移除老的Firebase OAuth回调处理，使用Deep Link OAuth系统
        // Firebase OAuth回调现在由Deep Link OAuth服务处理

        // 拦截原生协议
        if (uri.scheme == 'joymini') {
          if (uri.host == 'product') {
            final pid = uri.pathSegments.isNotEmpty
                ? uri.pathSegments.first
                : uri.queryParameters['pid'];
            if (pid != null) {
              final gid =
                  uri.queryParameters['groupId'] ?? uri.queryParameters['gid'];
              // 这里重定向后，GoRouter 会直接去目的地，DeepLinkService 就会被上面的时间锁拦住
              return gid != null
                  ? '/product-detail/$pid?groupId=$gid'
                  : '/product-detail/$pid';
            }
          } else if (uri.host == 'oauth') {
            // 处理 joymini://oauth/callback 回调
            // 重定向到 /oauth/callback 路由，让路由处理器处理 token
            return '/oauth/callback${uri.query.isNotEmpty ? '?${uri.query}' : ''}';
          }
        }

        final String path = state.matchedLocation;
        final isAuthenticated = ref.read(
          authProvider.select((auth) => auth.isAuthenticated),
        );

        // Check if the target route requires authentication.
        final bool needLogin = RouteAuthConfig.needLoginForPath(path);

        // Redirect unauthenticated users to login page for protected routes.
        if (needLogin && !isAuthenticated) {
          return '/login';
        }

        // Prevent authenticated users from accessing the login page.
        if (isAuthenticated && path == '/login') {
          return '/home';
        }

        // 已登录用户也允许访问 OAuth processing 页面，避免 callback 期间被提前重定向打断
        if (path == '/oauth/processing') {
          return null;
        }

        return null;
      },
      errorPageBuilder: (context, state) {
        debugPrint('Route error: ${state.error}');
        // 重置全局进度条
        Future.microtask(() {
          ref.read(overlayProgressProvider.notifier).state = 0.0;
        });
        unawaited(_page_404.loadLibrary());
        return fxPage(
          key: state.pageKey,
          child: DeferredPage(
            loadLibrary: _page_404.loadLibrary,
            builder: () => _page_404.Page404(),
          ),
          fx: RouteFx.fadeThrough,
        );
      },
    );

    // assign to the global instance, so that other parts of the app can access it
    appRouter = router;
    isAppRouterReady = true; // 新增这一行：初始化完成后，绿灯亮起！
    return router;
  }
}
