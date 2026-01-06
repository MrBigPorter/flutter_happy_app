import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../theme/design_tokens.g.dart';
import '../../../ui/button/button.dart';
import '../../../ui/button/variant.dart';
import '../../../utils/format_helper.dart';

class WithdrawSuccessModal extends StatelessWidget {
  final double amount;
  final double fee;
  final double actual;
  final VoidCallback close;

  const WithdrawSuccessModal({
    super.key,
    required this.amount,
    required this.fee,
    required this.actual,
    required this.close,
  });

  @override
  Widget build(BuildContext context) {
    // 定义基础动画时长
    const baseDelay = Duration(milliseconds: 100);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 成功图标 (弹性弹出 + 旋转微调)
          Container(
            width: 72.w, // 稍微加大一点
            height: 72.w,
            decoration: BoxDecoration(
              color: context.utilitySuccess50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.utilitySuccess600,
              size: 44.w,
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .rotate(begin: -0.1, end: 0, curve: Curves.easeOut),

          SizedBox(height: 20.h),

          // 2. 标题和状态 (淡入 + 上浮)
          Column(
            children: [
              Text(
                'withdraw.success.title'.tr(),
                style: TextStyle(
                  fontSize: 20.sp, // 字体稍微加大显眼
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'withdraw.success.processing_desc'.tr(),
                style: TextStyle(
                    fontSize: 13.sp, color: context.textSecondary700),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: baseDelay)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

          SizedBox(height: 24.h),

          // 3. 票据详情容器 (淡入 + 展开效果)
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgSecondary,
              borderRadius: BorderRadius.circular(16.r), // 圆角加大一点
              border: Border.all(color: context.borderSecondary.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  context,
                  'withdraw.success.amount_label',
                  FormatHelper.formatCurrency(amount),
                  delay: baseDelay * 2,
                ),
                SizedBox(height: 12.h),
                _buildReceiptRow(
                  context,
                  'withdraw.success.fee_label',
                  '- ${FormatHelper.formatCurrency(fee)}',
                  valueColor: context.utilityError600,
                  delay: baseDelay * 3,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(height: 1, color: context.borderSecondary),
                ),
                _buildReceiptRow(
                  context,
                  'withdraw.success.est_arrival_label',
                  FormatHelper.formatCurrency(actual),
                  isBold: true,
                  valueColor: context.utilitySuccess600,
                  delay: baseDelay * 4,
                  // 给金额加个高光流光效果，强调钱
                  highlight: true,
                ),
                SizedBox(height: 12.h),
                _buildReceiptRow(
                  context,
                  'withdraw.success.method_label',
                  'GCash', // 品牌词通常不翻译，如果需要也可以改成 key
                  delay: baseDelay * 5,
                ),
              ],
            ),
          ).animate().fadeIn(delay: baseDelay * 1.5).scale(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOut,
              duration: 400.ms),

          SizedBox(height: 32.h),

          // 4. 操作按钮组 (底部上浮)
          Row(
            children: [
              Expanded(
                child: Button(
                  variant: ButtonVariant.outline,
                  onPressed: () {
                    close();
                    // 确保路由栈正确
                    appRouter.push('/me/wallet/transaction/record?tab=withdraw');
                  },
                  child: Text('withdraw.success.check_history_btn'.tr()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Button(
                  onPressed: close,
                  child: Text('withdraw.success.done_btn'.tr()),
                ),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: baseDelay * 6)
              .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  // 辅助构建行：label 会在内部调用 .tr()
  Widget _buildReceiptRow(
      BuildContext context,
      String labelKey, // 这里传入的是 Key
      String value, {
        bool isBold = false,
        Color? valueColor,
        Duration? delay,
        bool highlight = false,
      }) {
    Widget valueText = Text(
      value,
      style: TextStyle(
        fontSize: 13.sp,
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        color: valueColor ?? context.textPrimary900,
      ),
    );

    // 如果需要高光效果（流光）
    if (highlight) {
      valueText = valueText
          .animate(onPlay: (controller) => controller.repeat(period: 2.seconds))
          .shimmer(color: Colors.white.withOpacity(0.6), duration: 800.ms);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          labelKey.tr(), // 在这里统一调用 tr()
          style: TextStyle(fontSize: 13.sp, color: context.textTertiary600),
        ),
        valueText,
      ],
    )
    // 给每一行加单独的入场动画
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}