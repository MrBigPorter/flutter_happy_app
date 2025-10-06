import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A custom AppBar widget
/// if title is null or empty, show logo
/// else show title text
/// if backIconPath is not null, show custom back icon
/// else show default back icon
/// progress is used to control header opacity
class LuckyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // app bar title
  final List<Widget>? actions; // app bar actions
  final bool showBack; // whether show back button
  final String? backIconPath; // custom back icon path

  const LuckyAppBar({
    super.key,
    this.title,
    this.actions,
    this.showBack = true,
    this.backIconPath,
  });

  @override
  Size get preferredSize => Size.fromHeight(50.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.bgPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: context.borderSecondary, width: 1),
      ),
      title: _Title(title: title),
      centerTitle: true,
      leading: _BackIcon(backIconPath: backIconPath),
      actions: actions,
    );
  }
}


/// Title widget for app bar
/// if title is null or empty, show logo
/// else show title text
class _Title extends StatelessWidget {
  final String? title;

  const _Title({this.title});

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return Image.asset('assets/images/logo.png', height: 32.w);
    }

    return Text(
      title!.tr(),
      style: TextStyle(
        fontSize: 16.w,
        fontWeight: FontWeight.w800,
        color: context.textPrimary900,
      ),
    );
  }
}


/// Back icon widget for app bar
/// if backIconPath is not null, show custom back icon
/// else show default back icon
class _BackIcon  extends StatelessWidget {
   final String? backIconPath;

   const _BackIcon({this.backIconPath});

    @override
    Widget build(BuildContext context) {
      return IconButton(
        icon: backIconPath != null
            ? Image.asset(backIconPath!)
            : Icon(Icons.chevron_left, size: 24.w),
        onPressed: () => Navigator.pop(context),
      );
    }
}
