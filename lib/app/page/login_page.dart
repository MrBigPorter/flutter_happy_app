import 'package:flutter/material.dart';
import 'package:flutter_app/components/base_scaffold.dart';

class LoginPage extends StatelessWidget {
  final String id;
  const LoginPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Center(
        child:Text("login page"),
      ),
    );
  }
}