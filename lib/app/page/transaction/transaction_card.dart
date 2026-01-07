import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于震动反馈
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 你的项目特定引用
import 'package:flutter_app/app/page/transaction/transaction_history_detail_page.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import '../../../components/skeleton.dart';
import '../../../theme/design_tokens.g.dart'; // 确保这里包含了 bgPrimary, textPrimary900 等定义
import '../../../ui/animations/transparent_fade_route.dart';

class TransactionCard extends StatelessWidget {
  final TransactionUiModel item;
  final int index;

  const TransactionCard({
    super.key,
    required this.item,
    this.index = 0
  });

  @override
  Widget build(BuildContext context) {
    // 判断是否是充值
    final isDeposit = item.type == UiTransactionType.deposit;

    // 状态颜色逻辑
    Color statusColor = item.statusCode == 2 ? const Color(0xFF2E7D32) : const Color(0xFFEF6C00);
    if (item.statusCode == 3) statusColor = const Color(0xFFC62828);

    // 状态背景色
    final statusBg = statusColor.withOpacity(0.1); // 注意: 如果 flutter 版本较低用 withOpacity, 新版用 withValues(alpha: 0.1)

    final formatter = NumberFormat("#,##0.00", "en_US");

    return _ScaleButton(
        onTap: () {
          Navigator.of(context).push(
              TransparentFadeRoute(
                  child: TransactionHistoryDetailPage(
                    item: item,
                    onClose: () {
                      Navigator.of(context).pop();
                    },
                  )
              )
          );
        },
        child: Hero(
            tag: 'txn_${item.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: context.bgPrimary, // 依赖 design_tokens.g.dart
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // ==============================
                    // 图标部分 (纯 Icon，无图片逻辑)
                    // ==============================
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        // 充值显示绿色背景，提现显示紫色背景
                        color: isDeposit
                            ? const Color(0xFF2E7D32).withOpacity(0.08)
                            : const Color(0xFF9C27B0).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        // 充值用钱包图标，提现用ATM图标
                        isDeposit ? Icons.account_balance_wallet : Icons.local_atm,
                        color: isDeposit ? const Color(0xFF2E7D32) : Colors.purple,
                        size: 22.w,
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // 中间信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // 显示后端返回的 "GCash", "Maya" 等
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                              color: context.textPrimary900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            DateFormat('yyyy-MM-dd HH:mm').format(item.time),
                            style: TextStyle(
                                color: context.textSecondary700,
                                fontSize: 12.sp
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 右侧金额
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${isDeposit ? '+' : '-'}${formatter.format(item.amount)}",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16.sp,
                            // 充值绿色，提现黑色
                            color: isDeposit ? const Color(0xFF2E7D32) : context.textPrimary900,
                            fontFamily: 'Monospace',
                          ),
                        ),
                        SizedBox(height: 6.h),
                        // 状态标签
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            item.statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            )
        )
    ).animate(delay: (50 * index).ms)
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ==========================================
// 辅助组件：按压缩放按钮
// ==========================================
class _ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleButton({required this.child, required this.onTap});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact(); // 轻微震动
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ==========================================
// 辅助组件：骨架屏
// ==========================================
class TransactionSkeleton extends StatelessWidget {
  const TransactionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8.h,
        bottom: 8.h,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Skeleton.react(width: 44.w, height: 44.w),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.react(width: 120.w, height: 16.h),
                  SizedBox(height: 8.h),
                  Skeleton.react(width: 80.w, height: 12.h),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Skeleton.react(width: 60.w, height: 20.h),
          ],
        ),
      ),
    );
  }
}