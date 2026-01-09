import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart'; // 必须包含 ProductListItem
import 'package:flutter_app/utils/format_helper.dart';

class JoinTreasureBar extends StatelessWidget {
  final ProductListItem item;
  final String? groupId;

  const JoinTreasureBar({
    super.key,
    required this.item,
    this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    // 🔥 [关键修复] 价格展示逻辑
    // 1. 单买价：优先用后端返回的 soloAmount，如果没有，则用拼团价 * 1.5 兜底
    //    千万不能用 costAmount (进货价)！
    final double soloVal = item.soloAmount ?? ((item.unitAmount ?? 0) * 1.5);
    final String soloPrice = FormatHelper.formatCurrency(soloVal);

    // 2. 拼团价
    final String groupPrice = FormatHelper.formatCurrency(item.unitAmount ?? 0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 首页按钮
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_outlined, size: 22.w, color: context.textSecondary700),
                    Text('Home', style: TextStyle(fontSize: 10.sp, color: context.textSecondary700)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.w),

            Expanded(
              child: Row(
                children: [
                  // --- 左侧：单买按钮 (Solo Buy) ---
                  Expanded(
                    flex: 3,
                    child: _buildBtn(
                      context,
                      bgColor: const Color(0xFFFFEDE9),
                      fgColor: Colors.red,
                      price: soloPrice,
                      label: 'Solo Buy',
                      //  [关键] isGroup = false
                      onTap: () => _goToCheckout(context, null, isGroup: false),
                      isLeft: true,
                    ),
                  ),

                  // --- 右侧：拼团按钮 (Group Buy) ---
                  Expanded(
                    flex: 5,
                    child: _buildBtn(
                      context,
                      bgColor: Colors.red,
                      fgColor: Colors.white,
                      price: groupPrice,
                      label: groupId != null ? 'Join Now' : 'Start Group',
                      //  [关键] isGroup = true
                      onTap: () => _goToCheckout(context, groupId, isGroup: true),
                      isLeft: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBtn(BuildContext context, {
    required Color bgColor,
    required Color fgColor,
    required String price,
    required String label,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? Radius.circular(24.r) : Radius.zero,
              right: !isLeft ? Radius.circular(24.r) : Radius.zero,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(price, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, height: 1.1)),
            Text(label, style: TextStyle(fontSize: 10.sp, height: 1.1)),
          ],
        ),
      ),
    );
  }

  void _goToCheckout(BuildContext context, String? gid, {required bool isGroup}) {
    //  [关键修复] 统一路由路径为 /payment，并带上 isGroupBuy 参数
    String path = '/payment?treasureId=${item.treasureId}&isGroupBuy=$isGroup';
    if (gid != null) {
      path += '&groupId=$gid';
    }
    appRouter.push(path);
  }
}