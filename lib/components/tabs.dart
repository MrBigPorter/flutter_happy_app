import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Tabs<T> extends StatelessWidget {
  final List<T> data;
  final T activeItem;
  final Widget Function(T item) renderItem;
  final void Function(T v) onChangeActive;
  final bool autoScrollIntoView;
  final double height;
  final int tabCount;

  const Tabs({
    super.key,
    required this.data,
    required this.activeItem,
    required this.renderItem,
    required this.onChangeActive,
    this.autoScrollIntoView = true,
    this.height = 44,
    this.tabCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndex = data.indexOf(activeItem);


    /// skeleton loading before data loaded
    if (data.isEmpty) {
      return SizedBox(
        height: height.w,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabCount, (_) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              child: Skeleton.react(
                width: 60.w,
                height: height.w,
                borderRadius: BorderRadius.circular(context.radiusSm),
              ),
            );
          }),
        ),
      );
    }

    return SizedBox(
      height: height.w,
      child: ListView.separated(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.only(left: 16.w,right: 16.w),
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => SizedBox(width: 12.w),
        itemBuilder: (_, index) {
          final item = data[index];
          final isActive = index == activeIndex;
          return _TabBarItem<T>(
            item,
            isActive,
            renderItem,
            onChangeActive,
          );
        },

      ),
    );
  }
}

class _TabBarItem<T> extends StatefulWidget {
  final T item;
  final bool isActive;
  final Widget Function(T item) renderItem;
  final void Function(T v) onChangeActive;

  const _TabBarItem(
      this.item,
      this.isActive,
      this.renderItem,
      this.onChangeActive,
      );
  @override
  _TabBarItemState<T> createState() => _TabBarItemState<T>();
}

class _TabBarItemState<T> extends State<_TabBarItem<T>> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
       return GestureDetector(
        onTap: () => widget.onChangeActive(widget.item),
        onTapDown: (_)=> setState(() => _pressed = true),
        onTapUp: (_)=> setState(() => _pressed = false),
        onTapCancel: ()=> setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
          decoration: BoxDecoration(
              color: widget.isActive ? context.bgBrandSolid : Colors.transparent,
              borderRadius: BorderRadius.circular(6.w)
          ),
          child: DefaultTextStyle(
              style: TextStyle(
                  fontSize: 14.w,
                  fontWeight: FontWeight.w500,
                  color: widget.isActive ? context.textPrimaryOnBrand : context.textQuaternary500
              ),
              child: AnimatedScale(
                  scale: _pressed ? 0.7 : 1.0,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  child: widget.renderItem(widget.item) ,
              )
          ),
        ),
      );
  }
}
