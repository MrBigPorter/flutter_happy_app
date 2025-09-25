import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String id;
  const HomePage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('home #$id')),
    );
  }
}