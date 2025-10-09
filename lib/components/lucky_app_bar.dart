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
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.bgPrimary,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(125),
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          height: 56.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: context.bgSecondary,width: 1),
            )
          ),
          child: Stack(
            children: [
              _Title(title: title),
              if(showBack)
                Positioned(
                  left: 0,
                  bottom: 0,
                  top: 0,
                  child: _BackIcon(backIconPath: backIconPath),
                ),

              if(actions != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  top: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                )
            ],
          ),
        ),
      ),
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
      return Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 32.h,
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: Text(
        title!.tr(),
        style: TextStyle(
          fontSize: 16.w,
          fontWeight: FontWeight.w800,
          color: context.textPrimary900,
        ),
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
            : Icon(Icons.chevron_left, size: 24.h),
        onPressed: () => Navigator.pop(context),
      );
    }
}
