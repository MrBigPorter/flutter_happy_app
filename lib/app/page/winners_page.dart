import 'package:flutter/material.dart';

class WinnersPage extends StatelessWidget {
  const WinnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('中奖名单')),
      body: Center(child: Text('这里展示中奖名单')),
    );
  }
}