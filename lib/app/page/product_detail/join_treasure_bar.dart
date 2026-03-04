import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/utils/format_helper.dart';

class JoinTreasureBar extends StatelessWidget {
  final ProductListItem item;
  final String? groupId;
  final TreasureStatusModel? realTimeStatus;

  const JoinTreasureBar({
    super.key,
    required this.item,
    this.groupId,
    this.realTimeStatus,
  });

  @override
  Widget build(BuildContext context) {
    // 1. 价格展示逻辑
    final double soloVal = item.soloAmount ?? ((item.unitAmount ?? 0) * 1.5);
    final String soloPrice = FormatHelper.formatCurrency(soloVal);
    final String groupPrice = FormatHelper.formatCurrency(item.unitAmount ?? 0);

    // 2.  核心状态诊断：如果实时状态还没加载回来，用列表带进来的初始数据兜底（防闪烁）
    final bool isOffline = (realTimeStatus?.state ?? item.state) == 0;

    final int initialStockLeft = (item.seqShelvesQuantity ?? 0) - (item.seqBuyQuantity ?? 0);
    final bool isSoldOut = realTimeStatus?.isSoldOut ?? (initialStockLeft <= 0);

    final bool isExpired = realTimeStatus?.isExpired ?? false;

    // 是否可以购买
    final bool canBuy = !isOffline && !isSoldOut && !isExpired;

    // 动态生成不可购买时的提示文案
    String disabledLabel = 'Unavailable';
    if (isOffline) {
      disabledLabel = 'Off Shelves'; // 已下架
    } else if (isSoldOut) {
      disabledLabel = 'Sold Out';    // 已售罄
    } else if (isExpired) {
      disabledLabel = 'Ended';       // 活动已结束
    }

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
            // 🏠 首页按钮 (始终可用)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => appRouter.go('/home'),
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

            //  核心 UI 逻辑：根据是否能买，渲染不同排版
            Expanded(
              child: canBuy
                  ? Row(
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
                      onTap: () => _goToCheckout(context, groupId, isGroup: true),
                      isLeft: false,
                    ),
                  ),
                ],
              )
              //  [修复] 绝不显示两个尴尬的灰按钮！一旦不可售，直接合体为一条灰色通栏！
                  : SizedBox(
                height: 44.h,
                child: ElevatedButton(
                  onPressed: null, // 物理阻断点击
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[600],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    disabledLabel, // 居中显示 Sold Out 等文案
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1, // 加一点字间距更有质感
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 按钮辅助构造器 (仅可售时使用) ---
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

  // --- 路由跳转逻辑 ---
  void _goToCheckout(BuildContext context, String? gid, {required bool isGroup}) {
    String path = '/payment?treasureId=${item.treasureId}&isGroupBuy=$isGroup';
    if (gid != null) {
      path += '&groupId=$gid';
    }
    appRouter.push(path);
  }
}