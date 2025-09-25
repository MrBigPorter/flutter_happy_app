import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final String id;
  const LoginPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('login #$id')),
    );
  }
}