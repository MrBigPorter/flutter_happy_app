import 'package:flutter/material.dart';

/// one base scaffold with optional app bar
/// can be use showAppBar to control whether show app bar
/// title for app bar title
/// body  for scaffold body
class BaseScaffold extends StatelessWidget {
  final String? title; // app bar title
  final Widget body; // scaffold body
  final bool showAppBar; // whether show app bar
  final List<Widget>? actions; // app bar actions
  final bool showBack; // whether show back button
  final String? backIconPath; // custom back icon path
  final PreferredSizeWidget? bottom; // tabbar

  const BaseScaffold({
    super.key,
    this.title,
    required this.body,
    this.showAppBar = true,
    this.actions,
    this.showBack = true,
    this.backIconPath,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: title != null
                  ? Text(title!)
                  : Image.asset('assets/images/logo.png', height: 32),
              centerTitle: true,
              leading: showBack
                  ? IconButton(
                      icon: backIconPath != null
                          ? Image.asset(backIconPath!)
                          : const Icon(Icons.chevron_left, size: 24),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: body,
    );
  }
}
