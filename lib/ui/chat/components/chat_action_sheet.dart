import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 定义每个菜单项的数据模型
class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class ChatActionSheet extends StatelessWidget {
  final List<ActionItem> actions;

  const ChatActionSheet({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    // 微信风格：灰底，卡片白底
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary, // 浅灰背景
      ),
      // 根据数量自动计算高度，或者固定高度
      height: 260.h,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 一行4个
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.75, // 控制宽高比，留出文字空间
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          return _buildItem(context, item);
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, ActionItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标容器
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: context.bgSecondary,
              borderRadius: BorderRadius.circular(16.r), // 微圆角
            ),
            child: Icon(item.icon, size: 28.sp, color: context.textBrandPrimary900),
          ),
          SizedBox(height: 8.h),
          // 文字
          Text(
            item.label,
            style: TextStyle(
              fontSize: 12.sp,
              color:context.textBrandPrimary900,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}