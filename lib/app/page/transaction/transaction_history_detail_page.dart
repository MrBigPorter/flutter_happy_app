import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart'; // 必须引入这个

import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/common.dart';

class TransactionHistoryDetailPage extends ConsumerWidget {
  final TransactionUiModel item;
  final VoidCallback? onClose;

  const TransactionHistoryDetailPage({
    super.key,
    required this.item,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeposit = item.type == UiTransactionType.deposit;

    // 状态样式定义 & 国际化文案
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (item.statusCode == 1) { // Pending
      statusColor = const Color(0xFFEF6C00);
      statusIcon = Icons.access_time_filled_rounded;
      statusLabel = "transaction.status_processing".tr(); // 国际化
    } else if (item.statusCode == 3) { // Failed
      statusColor = const Color(0xFFC62828);
      statusIcon = Icons.error_rounded;
      statusLabel = "transaction.status_failed".tr(); // 国际化
    } else { // Success
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = "transaction.status_successful".tr(); // 国际化
    }

    return DraggableScrollableScaffold(
      heroTag: 'txn_${item.id}',
      onDismiss: onClose ?? () => Navigator.of(context).pop(),

      // --- Header ---
      headerBuilder: (context, dragProgress, scrollController) {
        return _TransactionHeader(
          scrollController: scrollController,
          title: "transaction.title".tr(), // 国际化
          onClose: onClose,
        );
      },

      // --- Body ---
      bodyBuilder: (context, scrollController, physics) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: physics,
          child: Container(
            constraints: BoxConstraints(minHeight: 1.sh),
            color: context.bgSecondary,
            padding: EdgeInsets.fromLTRB(16.w, 80.w, 16.w, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.w),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: context.textPrimary900.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 图标动画
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 32.w)
                            .animate(delay: 100.ms)
                            .scale(duration: 400.ms, curve: Curves.elasticOut)
                            .rotate(begin: -0.1, end: 0),
                      )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

                      SizedBox(height: 16.h),

                      // 瀑布流内容
                      ...[
                        // 状态
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary900,
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // 金额
                        Text(
                          "${isDeposit ? '+' : '-'}${FormatHelper.formatCurrency(item.amount)}",
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w900,
                            color: isDeposit ? const Color(0xFF2E7D32) : context.textPrimary900,
                            fontFamily: 'Monospace',
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // "Total Amount"
                        Text(
                          "transaction.total_amount".tr(), // 国际化
                          style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                        ),

                        SizedBox(height: 32.h),
                        Divider(height: 1, thickness: 1, color: context.borderSecondary.withOpacity(0.5)),
                        SizedBox(height: 32.h),

                        // 详情列表 - 全部国际化
                        _DetailRow(
                            label: "transaction.type".tr(),
                            value: isDeposit ? "transaction.type_deposit".tr() : "transaction.type_withdraw".tr()
                        ),
                        _DetailRow(
                            label: "transaction.payment_method".tr(),
                            value: item.title
                        ),
                        _DetailRow(
                            label: "transaction.time".tr(),
                            value: DateFormat('yyyy-MM-dd HH:mm:ss').format(item.time)
                        ),
                        _DetailRow(
                            label: "transaction.number".tr(),
                            value: item.id,
                            isCopyable: true
                        ),
                        if (item.statusCode == 3)
                          _DetailRow(
                            label: "transaction.reason".tr(),
                            value: "transaction.declined".tr(), // 这里最好是后端返回的错误码对应的前端翻译，暂时用通用文案
                            valueColor: context.utilityError500,
                          ),
                      ]
                          .animate(interval: 50.ms)
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad),
                    ],
                  ),
                )
                    .animate()
                    .moveY(begin: 20, end: 0, curve: Curves.easeOut),

                SizedBox(height: 32.h),

                // 底部帮助
                TextButton.icon(
                  onPressed: () {
                    // TODO: 客服逻辑
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.textSecondary700,
                  ),
                  icon: Icon(Icons.help_outline_rounded, size: 16.w),
                  label: Text("transaction.help_text".tr()), // 国际化
                )
                    .animate(delay: 600.ms)
                    .fadeIn()
                    .moveY(begin: 10, end: 0),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 40.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ... Header 组件保持不变 ...

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCopyable;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isCopyable = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondary700,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: GestureDetector(
              onTap: isCopyable ? () {
                Clipboard.setData(ClipboardData(text: value));
                HapticFeedback.selectionClick();
                // 国际化 Toast
                RadixToast.success("common.copied".tr());
              } : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: valueColor ?? context.textPrimary900,
                        fontWeight: FontWeight.w600,
                        fontFamily: isCopyable ? 'Monospace' : null,
                      ),
                    ),
                  ),
                  if (isCopyable) ...[
                    SizedBox(width: 4.w),
                    Icon(Icons.copy_rounded, size: 14.w, color: context.textTertiary600),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------------------
/// 动态 Header (带透明度变化 + 修复了 ScrollController 报错)
/// -------------------------------------------
class _TransactionHeader extends StatelessWidget {
  final ScrollController scrollController;
  final String title;
  final VoidCallback? onClose;

  const _TransactionHeader({
    required this.scrollController,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double offset = 0;

        // 【修复1】核心修复代码：防止多 ScrollView 冲突
        // 不要直接用 scrollController.offset
        if (scrollController.hasClients && scrollController.positions.isNotEmpty) {
          offset = scrollController.positions.first.pixels;
        }

        // 计算透明度：滚动 50px 后完全显示 Header 背景
        double opacity = (offset / 50.0).clamp(0.0, 1.0);

        return Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: context.bgPrimary.withOpacity(opacity),
            border: Border(
              bottom: BorderSide(
                color: context.borderSecondary.withOpacity(opacity),
                width: 1,
              ),
            ),
          ),
          child: NavigationToolbar(
            // 左侧：关闭按钮
            leading: IconButton(
              icon: Icon(Icons.close, color: context.textPrimary900),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
            ),
            // 中间：标题 (滚动出现)
            middle: Opacity(
              opacity: opacity,
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                  color: context.textPrimary900,
                ),
              ),
            ),
            /*// 右侧：分享按钮 (可选)
            trailing: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(Icons.ios_share, color: context.textPrimary900),
                onPressed: () {
                  // 分享逻辑
                },
              ),
            ),*/
          ),
        );
      },
    );
  }
}

