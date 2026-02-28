import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 1. Layout modes definition
enum ActionSheetType { grid, list }

// 2. Upgraded ActionItem with destructive operation support
class ActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive; // Whether this is a destructive action (e.g., Delete)

  const ActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false, // Defaults to false
  });
}

class ChatActionSheet extends StatelessWidget {
  final List<ActionItem> actions;
  final ActionSheetType type; // Controls the display mode

  const ChatActionSheet({
    super.key,
    required this.actions,
    this.type = ActionSheetType.list, // Default is list (long-press menu), grid used for input panel
  });

  @override
  Widget build(BuildContext context) {
    // Dispatch layout based on type
    if (type == ActionSheetType.grid) {
      return _buildGridLayout(context);
    } else {
      return _buildListLayout(context);
    }
  }

  // =================================================
  // Mode A: Grid Layout (Used for input "+" panel)
  // =================================================
  Widget _buildGridLayout(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
      ),
      // Grid height is usually fixed or constrained by parent in this mode
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true, // Adaptive height
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
                  child: Icon(
                    item.icon,
                    size: 28.sp,
                    color: context.textBrandPrimary900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textPrimary900,
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
  // Mode B: List Layout (Used for message long-press menu)
  // =================================================
  Widget _buildListLayout(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)), // Rounded top corners
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle at the top
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
          // List items
          ...actions.map((item) => InkWell(
            onTap: item.onTap,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: context.borderPrimary,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: item.isDestructive
                        ? context.utilityError500 // Highlights dangerous actions in red
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
          // Spacing below the list
          SizedBox(height: 8.h),
        ],
      ),
    );
  }
}