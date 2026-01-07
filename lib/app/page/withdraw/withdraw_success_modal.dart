import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 假设你的路径
import '../../../theme/design_tokens.g.dart';
import '../../../ui/button/button.dart';
import '../../../ui/button/variant.dart';
import '../../../utils/format_helper.dart';

class WithdrawSuccessModal extends StatelessWidget {
  final double amount;
  final double fee;
  final double actual;

  //  新增：渠道名称 (如 GCash) 和 账号 (如 0917***123)
  final String channelName;
  final String account;

  final VoidCallback close;

  const WithdrawSuccessModal({
    super.key,
    required this.amount,
    required this.fee,
    required this.actual,
    required this.channelName, // 必传
    required this.account,     // 必传
    required this.close,
  });

  @override
  Widget build(BuildContext context) {
    const baseDelay = Duration(milliseconds: 100);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.w, horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 成功图标
          Container(
            width: 72.w,
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

          // 2. 标题和状态
          Column(
            children: [
              Text(
                'withdraw.success.title'.tr(), // "Submission Successful"
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'withdraw.success.processing_desc'.tr(), // "Your request is being processed..."
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: context.textSecondary700),
              ),
            ],
          )
              .animate()
              .fadeIn(delay: baseDelay)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),

          SizedBox(height: 24.h),

          // 3. 票据详情容器
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.bgSecondary,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.borderSecondary.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildReceiptRow(
                  context,
                  'withdraw.success.amount_label', // "Withdraw Amount"
                  FormatHelper.formatCurrency(amount),
                  delay: baseDelay * 2,
                ),
                SizedBox(height: 12.h),

                _buildReceiptRow(
                  context,
                  'withdraw.success.fee_label', // "Service Fee"
                  '- ${FormatHelper.formatCurrency(fee)}',
                  valueColor: context.utilityError600,
                  delay: baseDelay * 3,
                ),

                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(height: 1, color: context.borderSecondary),
                ),

                // 实际到账
                _buildReceiptRow(
                  context,
                  'withdraw.success.actual_label', // "Actual Arrival"
                  FormatHelper.formatCurrency(actual),
                  isBold: true,
                  valueColor: context.utilitySuccess600,
                  delay: baseDelay * 4,
                  highlight: true,
                ),

                SizedBox(height: 12.h),

                //  动态显示渠道
                _buildReceiptRow(
                  context,
                  'withdraw.success.method_label', // "To Account"
                  "$channelName ($_maskedAccount)", // 显示 "GCash (**** 6789)"
                  delay: baseDelay * 5,
                ),
              ],
            ),
          ).animate().fadeIn(delay: baseDelay * 1.5).scale(
              begin: const Offset(0.95, 0.95),
              curve: Curves.easeOut,
              duration: 400.ms),

          SizedBox(height: 32.h),

          // 4. 操作按钮组
          Row(
            children: [
              Expanded(
                child: Button(
                  variant: ButtonVariant.outline,
                  onPressed: () {
                    close(); // 关闭弹窗
                    // 关闭提现页面 (返回上一页)，防止回退
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    // 跳转到记录页
                    appRouter.push('/me/wallet/transaction/record?tab=withdraw');
                  },
                  child: Text('withdraw.success.check_history_btn'.tr()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Button(
                  onPressed: () {
                    close(); // 关闭弹窗
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // 关闭提现页面，回首页
                    }
                  },
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

  // 简单的脱敏逻辑：只显示后4位
  String get _maskedAccount {
    if (account.length <= 4) return account;
    return "**** ${account.substring(account.length - 4)}";
  }

  Widget _buildReceiptRow(
      BuildContext context,
      String labelKey,
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
        fontFamily: isBold ? 'Monospace' : null, // 数字用等宽字体更好看
      ),
    );

    if (highlight) {
      valueText = valueText
          .animate(onPlay: (controller) => controller.repeat(period: 2.seconds))
          .shimmer(color: Colors.white.withOpacity(0.6), duration: 800.ms);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          labelKey.tr(),
          style: TextStyle(fontSize: 13.sp, color: context.textTertiary600),
        ),
        valueText,
      ],
    )
        .animate()
        .fadeIn(delay: delay, duration: 400.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}