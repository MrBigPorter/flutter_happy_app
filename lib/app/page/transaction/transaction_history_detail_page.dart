import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 引入你项目中的组件
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/common.dart';

class TransactionHistoryDetailPage extends ConsumerWidget {
  final TransactionUiModel item;
  final VoidCallback? onClose; // 传入关闭回调

  const TransactionHistoryDetailPage({
    super.key,
    required this.item,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 预处理颜色逻辑
    final isDeposit = item.type == UiTransactionType.deposit;

    // 状态样式定义
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (item.statusCode == 1) { // Pending
      statusColor = const Color(0xFFEF6C00); // 或 context.utilityWarning
      statusIcon = Icons.access_time_filled_rounded;
      statusLabel = "Processing";
    } else if (item.statusCode == 3) { // Failed
      statusColor = const Color(0xFFC62828); // 或 context.utilityError
      statusIcon = Icons.error_rounded;
      statusLabel = "Failed";
    } else { // Success
      statusColor = const Color(0xFF2E7D32); // 或 context.utilitySuccess
      statusIcon = Icons.check_circle_rounded;
      statusLabel = "Successful";
    }

    return DraggableScrollableScaffold(
      // 给个 tag 防止 hero 冲突
      heroTag: 'txn_${item.id}',
      onDismiss: onClose ?? () => Navigator.of(context).pop(),

      // 1. 动态 Header (带毛玻璃和透明度变化)
      headerBuilder: (context, dragProgress, scrollController) {
        return _TransactionHeader(
          scrollController: scrollController,
          title: "Transaction Details",
          onClose: onClose,
        );
      },

      // 2. 主体内容 (Receipt Card)
      bodyBuilder: (context, scrollController, physics) {
        return SingleChildScrollView(
          // 🔥 关键：必须绑定这个 controller 才能实现拖拽手势
          controller: scrollController,
          physics: physics,
          child: Container(
            constraints: BoxConstraints(minHeight: 1.sh - 100.w), // 保证够高能拖动
            color: context.bgSecondary, // 浅灰背景
            padding: EdgeInsets.fromLTRB(16.w, 80.w, 16.w, 40.w), // Top padding 留给 Header
            child: Column(
              children: [
                // --- 核心收据卡片 ---
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.w),
                  decoration: BoxDecoration(
                    color: context.bgPrimary, // 白色
                    borderRadius: BorderRadius.circular(24.r),
                    // 高级阴影
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
                      // 图标
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(statusIcon, color: statusColor, size: 32.w),
                      ),
                      SizedBox(height: 16.w),

                      // 状态文字
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary900,
                        ),
                      ),
                      SizedBox(height: 24.w),

                      // 大额金额
                      Text(
                        "${isDeposit ? '+' : '-'}${NumberFormat("#,##0.00").format(item.amount)}",
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: isDeposit ? const Color(0xFF2E7D32) : context.textPrimary900,
                          fontFamily: 'Monospace',
                          letterSpacing: -1,
                        ),
                      ),
                      SizedBox(height: 8.w),
                      Text(
                        "Total Amount",
                        style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                      ),

                      SizedBox(height: 32.w),
                      // 虚线分割效果 (用 Divider 模拟)
                      Divider(height: 1, thickness: 1, color: context.borderSecondary.withOpacity(0.5)),
                      SizedBox(height: 32.w),

                      // 详情列表
                      _DetailRow(label: "Type", value: isDeposit ? "Deposit" : "Withdraw"),
                      _DetailRow(label: "Payment Method", value: item.title),
                      _DetailRow(
                          label: "Time",
                          value: DateFormat('yyyy-MM-dd HH:mm:ss').format(item.time)
                      ),
                      _DetailRow(
                          label: "Transaction No.",
                          value: item.id,
                          isCopyable: true
                      ),

                      // 如果失败显示原因
                      if (item.statusCode == 3)
                        _DetailRow(
                          label: "Reason",
                          value: "Payment Declined", // 这里应从 item 读取
                          valueColor: context.utilityError500,
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 32.w),

                // --- 底部帮助 ---
                TextButton.icon(
                  onPressed: () {
                    // TODO: 客服逻辑
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.textSecondary700,
                  ),
                  icon: Icon(Icons.help_outline_rounded, size: 16.w),
                  label: Text("Have an issue with this transaction?"),
                ),

                // 底部留白，防遮挡
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20.w),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// -------------------------------------------
/// 动态 Header (带透明度变化 + 分享按钮)
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
        if (scrollController.hasClients) {
          offset = scrollController.offset;
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
            // 右侧：分享按钮
            trailing: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: IconButton(
                icon: Icon(Icons.ios_share, color: context.textPrimary900),
                onPressed: () {
                  // TODO: 调用分享逻辑
                  // ShareService.shareScreenshot(...)
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// -------------------------------------------
/// 详情行组件
/// -------------------------------------------
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied"), duration: Duration(seconds: 1)),
                );
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
                        fontFamily: isCopyable ? 'Monospace' : null, // 单号用等宽
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