import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final String id;
  const ProductDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('商品详情 #$id')),
      body: Center(child: Text('这里展示商品 $id 的详情')),
    );
  }
}