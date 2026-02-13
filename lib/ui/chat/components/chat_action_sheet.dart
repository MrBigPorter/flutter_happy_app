import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 1. 定义布局模式
enum ActionSheetType { grid, list }

// 2. 升级 ActionItem：增加 isDestructive
class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive; // 新增：是否为破坏性操作(如删除)

  const ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false, // 默认为 false
  });
}

class ChatActionSheet extends StatelessWidget {
  final List<ActionItem> actions;
  final ActionSheetType type; // 新增：控制显示模式

  const ChatActionSheet({
    super.key,
    required this.actions,
    this.type = ActionSheetType.list, // 默认为列表模式(用于长按菜单)，输入框面板需手动传 grid
  });

  @override
  Widget build(BuildContext context) {
    // 根据类型分发布局
    if (type == ActionSheetType.grid) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  // =================================================
  // 模式 A: 网格布局 (用于输入框 "+" 号面板)
  // =================================================
  Widget _buildGridLayout(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
      ),
      // Grid 模式下通常高度固定或由外部约束
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true, // 自适应高度
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 16.w,
          childAspectRatio: 0.75,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final item = actions[index];
          return GestureDetector(
            onTap: item.onTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: context.bgSecondary,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(item.icon, size: 28.sp, color: context.textBrandPrimary900),
                ),
                SizedBox(height: 8.h),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textPrimary900, // 修正颜色引用
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =================================================
  // 模式 B: 列表布局 (用于消息长按菜单)
  // =================================================
  Widget _buildListLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)), // 顶部圆角
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部小横条
          Center(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 12.h),
              width: 36.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          // 列表项
          ...actions.map((item) => InkWell(
            onTap: item.onTap,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.borderPrimary, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: item.isDestructive
                        ? context.utilityError500 // 危险操作变红
                        : context.textPrimary900,
                    size: 24.sp,
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: item.isDestructive
                          ? context.utilityError500
                          : context.textPrimary900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )),
          // 取消按钮
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}