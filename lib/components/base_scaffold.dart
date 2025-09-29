import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
          ? PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: AppBar(
            backgroundColor: context.bgPrimary,
            elevation: 0,
            shape: Border(
              bottom: BorderSide(color: context.borderSecondary, width: 1),
            ),
            title: title != null
                ? Text(
              title!.tr(),
              style: TextStyle(
                fontSize: 16.w,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            )
                : Image.asset('assets/images/logo.png', height: 32.w),
            centerTitle: true,
            leading: showBack
                ? IconButton(
              icon: backIconPath != null
                  ? Image.asset(backIconPath!)
                  :  Icon(Icons.chevron_left, size: 24.w),
              onPressed: () => Navigator.pop(context),
            )
                : null,
            actions: actions,
            bottom: bottom,
          )
      )
          : null,
      body: body,
    );
  }
}
