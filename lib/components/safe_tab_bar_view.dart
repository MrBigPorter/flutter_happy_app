import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SafeTabBarView extends StatelessWidget {
  final TabController? controller;
  final List<Widget> children;
  final Widget? skeleton;

  final double itemHeight;
  final int itemCount;

  const SafeTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.skeleton,
    this.itemHeight = 60,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (controller == null || children.isEmpty) {
      return skeleton ?? _SkeletonTabBarView(
        itemHeight: itemHeight,
        itemCount: itemCount,
      );
    }
    return TabBarView(
      controller: controller,
      children: children,
    );
  }
}

class _SkeletonTabBarView extends StatelessWidget {
  final double itemHeight;
  final int itemCount;
  const _SkeletonTabBarView({this.itemHeight = 60, this.itemCount = 10});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(itemCount, (i) => Expanded(child: Skeleton.react(width: double.infinity, height:itemHeight.w))),
    );
  }
}