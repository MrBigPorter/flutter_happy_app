import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'lucky_app_bar.dart';

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

  const BaseScaffold({
    super.key,
    this.title,
    required this.body,
    this.showAppBar = true,
    this.actions,
    this.showBack = true,
    this.backIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? LuckyAppBar(
              title: title,
              actions: actions,
              showBack: showBack,
              backIconPath: backIconPath,
            )
          : null,
      body: body,
    );
  }
}
