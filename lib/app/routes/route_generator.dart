import 'package:flutter/material.dart';
import '../page/home_page.dart';
import '../page/login_page.dart';
import '../page/product_detail_page.dart';

class AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const productDetail = '/product/:id';
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomePage(id: '',));
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage(id: '',));
      case '/product/:id':
        final args = settings.arguments as Map<String, dynamic>?;
        final id = args?['id'] ?? '0';
        return MaterialPageRoute(builder: (_) => ProductDetailPage(id: id));
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("404 - Page Not Found")),
          ),
        );
    }
  }
}