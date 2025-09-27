import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';

class ProductPage extends StatelessWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: "商品列表",
      body: Center(child: Text('这里是商品列表')),
      showBack: false,
    );
  }
}