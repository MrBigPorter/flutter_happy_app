// app/routes/app_router.dart
import 'package:go_router/go_router.dart';

import '../../components/lucky_tab_bar.dart';
import '../page/home_page.dart';
import '../page/product_page.dart';
import '../page/winners_page.dart';
import '../page/me_page.dart';
import '../page/login_page.dart';

class AppRouter {

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>  const LoginPage(id: '1')
      ),

      ShellRoute(
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
    ],
  );
}