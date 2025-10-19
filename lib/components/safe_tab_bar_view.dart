import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SafeTabBarView extends StatelessWidget {
  final TabController? controller;
  final List<Widget> children;
  final Widget? skeleton;
  final ScrollPhysics? physics;

  final double itemHeight;
  final int itemCount;

  const SafeTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.skeleton,
    this.itemHeight = 100,
    this.itemCount = 5,
    this.physics,
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
      physics: physics?? const NeverScrollableScrollPhysics(),
      controller: controller,
      children: children,
    );
  }
}

class _SkeletonTabBarView extends StatelessWidget {
  final double itemHeight;
  final int itemCount;
  const _SkeletonTabBarView({this.itemHeight = 60, this.itemCount = 5});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,          // 如果外层还有滚动，配合 NeverScrollableScrollPhysics
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: 16.w),
      itemBuilder: (_, __) => SizedBox(
        height: 100.w,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Skeleton.react(width: double.infinity, height: itemHeight.w),
        )
      ),
    );
  }
}