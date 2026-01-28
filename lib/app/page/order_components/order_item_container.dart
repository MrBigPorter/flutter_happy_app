import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- 你的项目引用，请根据实际路径调整 ---
import 'package:flutter_app/app/page/order_detail_page.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animations/transparent_fade_route.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import '../../../core/providers/order_provider.dart';
import 'refund_request_sheet.dart'; // 刚才写的弹窗组件

class OrderItemContainer extends ConsumerWidget {
  final OrderItem item;
  final bool isLast;
  final VoidCallback? onRefresh;

  const OrderItemContainer({
    super.key,
    required this.item,
    required this.isLast,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String heroTag = 'order_card_${item.orderId}';
    final isWinning = item.isWon;

    Widget cardContent = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 32.h : 12.h),
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // 1. 中奖极淡金色渐变
              gradient: isWinning
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFBEB), Colors.white],
              )
                  : null,
              color: isWinning ? null : context.bgPrimary,
              borderRadius: BorderRadius.circular(16.w),
              // 2. 边框
              border: isWinning
                  ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                  : Border.all(color: context.borderSecondary, width: 0.5),
              // 3. 阴影
              boxShadow: [
                BoxShadow(
                  color: isWinning
                      ? const Color(0xFFFFD700).withOpacity(0.15)
                      : context.fgPrimary900.withOpacity(0.04),
                  blurRadius: 20.w,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部状态栏
                _OrderItemStatusHeader(item: item),

                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      _OrderItemHeader(item: item),

                      SizedBox(height: 16.h),
                      _DashedSeparator(color: context.borderSecondary),
                      SizedBox(height: 16.h),

                      _OrderItemInfo(item: item),

                      // 中奖/拼团信息
                      _OrderItemGroupSuccess(item: item),

                      //  修改：只要申请过退款 (状态 > 0)，就显示退款详情块
                      if (item.refundStatus > 0) ...[
                        SizedBox(height: 12.h),
                        _OrderItemRefundInfo(item: item),
                      ],

                      // 操作按钮区 (只有未完全退款时才显示部分按钮)
                      SizedBox(height: 20.h),
                      _OrderItemActions(
                        item: item,
                        onRequestRefund: () {
                          // 弹出退款申请 BottomSheet
                          RadixSheet.show(
                            builder: (ctx, close) => RefundRequestSheet(
                              orderId: item.orderId,
                              amount: '₱${item.finalAmount}',
                              onSubmit: (reason) async {
                                Navigator.pop(ctx);

                                // 调用 Provider
                                final req = RefundApplyReq(orderId: item.orderId, reason: reason);
                                final result = await ref.read(orderRefundApplyProvider.notifier).create(req);

                                if (result != null) {
                                  RadixToast.success('Refund request submitted successfully.');
                                  // 关键：刷新列表和详情，UI 才会变
                                  ref.invalidate(orderDetailProvider(item.orderId));
                                  if (onRefresh != null) onRefresh!();
                                }
                              },
                            ),
                          );
                        },
                        onViewFriends: () {
                          if (item.group != null) {
                            appRouter.push('/group-member/?groupId=${item.group!.groupId}');
                          }
                        },
                        onViewRewardDetails: () {
                          Navigator.of(context).push(
                            TransparentFadeRoute(
                              child: OrderDetailPage(
                                orderId: item.orderId,
                                imageList: [item.treasure.treasureCoverImg],
                                onClose: () => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                        onTeamUp: () {
                          appRouter.push('/me/order/${item.orderId}/team-up');
                        },
                        onClaimPrize: () {
                          appRouter.push('/me/order/${item.orderId}/claim-prize');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return cardContent
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
        .slideY(begin: 0.1, end: 0.0, duration: 400.ms, curve: Curves.easeOutQuad)
        .then(delay: 200.ms)
        .shimmer(
      duration: 1500.ms,
      color: isWinning ? const Color(0xFFFFD700).withOpacity(0.4) : Colors.transparent,
      angle: 0.8,
    );
  }
}

/// ---------------------------------------------------------
/// 顶部状态栏 (Status Header) - 已增强退款状态显示
/// ---------------------------------------------------------
class _OrderItemStatusHeader extends StatelessWidget {
  final OrderItem item;

  const _OrderItemStatusHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    String statusText = '';
    Color statusColor = context.textBrandSecondary700;
    Color statusBg = context.textBrandSecondary700.withOpacity(0.1);

    //  1. 优先判断退款状态
    if (item.refundStatus == 1) {
      // 审核中
      return _buildContainer(
        text: 'Refunding',
        textColor: const Color(0xFFD97706), // Orange 700
        bgColor: const Color(0xFFFFFBEB),   // Orange 50
        context: context,
      );
    } else if (item.refundStatus == 3) {
      // 被驳回
      return _buildContainer(
        text: 'Refund Rejected',
        textColor: context.utilityError500, // Red
        bgColor: context.utilityError500.withOpacity(0.1),
        context: context,
      );
    }

    // 2. 常规状态判断
    switch (item.orderStatusEnum) {
      case OrderStatus.won:
        statusText = 'Winner';
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFFFBEB);
        break;
      case OrderStatus.refunded:
        statusText = 'Refunded';
        statusColor = context.utilityError500;
        statusBg = context.utilityError500.withOpacity(0.1);
        break;
      case OrderStatus.cancelled:
        statusText = 'Cancelled';
        statusColor = context.textSecondary700;
        statusBg = context.bgSecondary;
        break;
      case OrderStatus.groupSuccess:
        statusText = 'Group Success';
        statusColor = Colors.green;
        statusBg = Colors.green.withOpacity(0.1);
        break;
      case OrderStatus.paid:
        statusText = 'Paid';
        statusColor = context.textBrandPrimary900;
        statusBg = context.textBrandPrimary900.withOpacity(0.05);
        break;
      case OrderStatus.processing:
        statusText = 'Processing';
        statusColor = context.textBrandPrimary900;
        statusBg = context.textBrandPrimary900.withOpacity(0.05);
        break;
      default:
        statusText = 'Pending';
        break;
    }

    return _buildContainer(
        text: statusText,
        textColor: statusColor,
        bgColor: statusBg,
        context: context
    );
  }

  Widget _buildContainer({
    required String text,
    required Color textColor,
    required Color bgColor,
    required BuildContext context,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: context.bgSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.w),
          topRight: Radius.circular(16.w),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.createdAt != null
                ? DateFormatHelper.format(item.createdAt, 'yyyy-MM-dd HH:mm')
                : '',
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textTertiary600,
              fontFamily: 'Monospace',
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.w),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 商品头部信息
/// ---------------------------------------------------------
class _OrderItemHeader extends StatelessWidget {
  final OrderItem item;

  const _OrderItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.w),
          child: CachedNetworkImage(
            imageUrl: item.treasure.treasureCoverImg,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            memCacheWidth: (80.w * MediaQuery.of(context).devicePixelRatio).round(),
            errorWidget: (_, __, ___) => Container(color: context.borderSecondary),
            placeholder: (_, __) => Skeleton.react(width: 80.w, height: 80.w),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.treasure.treasureName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary900,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 8.w),
              RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12.sp, color: context.textTertiary600),
                  children: [
                    TextSpan(text: '${FormatHelper.formatWithCommas(item.buyQuantity)}/${FormatHelper.formatWithCommas(item.treasure.seqShelvesQuantity)} '),
                    TextSpan(text: 'common.sold.lowercase'.tr()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 订单信息
/// ---------------------------------------------------------
class _OrderItemInfo extends StatelessWidget {
  final OrderItem item;
  const _OrderItemInfo({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          label: 'common.ticket.price'.tr(),
          value: FormatHelper.formatWithCommasAndDecimals(item.unitPrice),
        ),
        SizedBox(height: 8.w),
        _InfoRow(
          label: 'common.tickets.number'.tr(),
          value: 'x${item.buyQuantity}',
        ),
        SizedBox(height: 12.w),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              // 如果已退款，显示 Total Refund，否则 Total Price
              item.isRefunded ? 'Total Refund' : 'common.total.price'.tr(),
              style: TextStyle(fontSize: 14.sp, color: context.textPrimary900, fontWeight: FontWeight.bold),
            ),
            Text(
              '₱${item.finalAmount}',
              style: TextStyle(
                fontSize: 18.sp,
                color: context.textBrandPrimary900,
                fontWeight: FontWeight.w900,
                fontFamily: 'RobotoMono',
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13.sp, color: context.textSecondary700)),
        Text(value, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: context.textPrimary900)),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 中奖/拼团成功块
/// ---------------------------------------------------------
class _OrderItemGroupSuccess extends StatelessWidget {
  final OrderItem item;
  const _OrderItemGroupSuccess({required this.item});

  @override
  Widget build(BuildContext context) {
    if (!item.showGroupSuccessSection) return const SizedBox.shrink();

    final Color bgColor = item.isWon ? const Color(0xFFFFFBEB) : context.bgSecondary;
    final Color borderColor = item.isWon ? const Color(0xFFFCD34D).withOpacity(0.5) : Colors.transparent;

    return Container(
      margin: EdgeInsets.only(top: 16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          if (item.isGroupSuccess)
            _SuccessRow(
              label: 'Group Success',
              value: '${item.prizeCoin ?? 0} Coins',
              icon: Icons.group_add_rounded,
              valueColor: context.textBrandSecondary700,
            ),
          if (item.isGroupSuccess && item.isWon)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.w),
              child: Divider(height: 1, color: borderColor.withOpacity(0.5)),
            ),
          if (item.isWon)
            _SuccessRow(
              label: 'common.winning.number'.tr(),
              value: item.prizeAmount ?? '₱0.00',
              icon: Icons.emoji_events_rounded,
              valueColor: const Color(0xFFD97706),
              isBold: true,
            ),
        ],
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  final bool isBold;

  const _SuccessRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: valueColor),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(fontSize: 12.sp, color: context.textSecondary700, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14.sp : 12.sp,
            color: valueColor,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontFamily: isBold ? 'RobotoMono' : null,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 退款详情块 - 支持审核中、成功、失败状态
/// ---------------------------------------------------------
class _OrderItemRefundInfo extends StatefulWidget {
  final OrderItem item;
  const _OrderItemRefundInfo({required this.item});

  @override
  State<_OrderItemRefundInfo> createState() => _OrderItemRefundInfoState();
}

class _OrderItemRefundInfoState extends State<_OrderItemRefundInfo> {
  bool isOpen = true;

  @override
  Widget build(BuildContext context) {
    //  动态样式逻辑
    String title = 'Refund Details';
    Color titleColor = context.textSecondary700;
    Color iconColor = context.textSecondary700;

    if (widget.item.refundStatus == 1) { // Refunding
      title = 'Refund Processing';
      titleColor = const Color(0xFFD97706); // Orange
      iconColor = const Color(0xFFD97706);
    } else if (widget.item.refundStatus == 3) { // Rejected
      title = 'Refund Rejected';
      titleColor = context.utilityError500; // Red
      iconColor = context.utilityError500;
    }

    return Container(
      decoration: BoxDecoration(
        color: context.bgSecondary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: context.borderSecondary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => isOpen = !isOpen),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_return_outlined, size: 16.w, color: iconColor),
                      SizedBox(width: 8.w),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isOpen ? Icons.expand_less : Icons.expand_more,
                    size: 16.w,
                    color: context.textTertiary600,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.w),
              child: Column(
                children: [
                  Divider(height: 1, color: context.borderSecondary.withOpacity(0.5)),
                  SizedBox(height: 8.w),

                  // 1. 申请原因
                  _InfoRow(
                    label: 'Reason',
                    value: widget.item.refundReason ?? 'Other',
                  ),

                  // 2. 如果被拒绝，显示拒绝原因 (红色高亮)
                  if (widget.item.refundStatus == 3 && widget.item.refundRejectReason != null) ...[
                    SizedBox(height: 8.w),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rejection', style: TextStyle(fontSize: 13.sp, color: context.textSecondary700)),
                        Flexible(
                          child: Text(
                            widget.item.refundRejectReason!,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: context.utilityError500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  ],

                  SizedBox(height: 8.w),
                  _InfoRow(
                    label: 'Amount',
                    value: '₱${widget.item.finalAmount}',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 底部按钮操作栏
/// ---------------------------------------------------------
class _OrderItemActions extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onViewFriends;
  final VoidCallback? onViewRewardDetails;
  final VoidCallback? onTeamUp;
  final VoidCallback? onClaimPrize;
  final VoidCallback? onRequestRefund;

  const _OrderItemActions({
    required this.item,
    this.onViewFriends,
    this.onViewRewardDetails,
    this.onTeamUp,
    this.onClaimPrize,
    this.onRequestRefund,
  });

  @override
  Widget build(BuildContext context) {
    // 智能判断能否退款 (使用 model extension)
    // 如果已经申请了(状态=1或2)，canRequestRefund 会自动变 false，按钮消失
    final canRefund = item.canRequestRefund;

    // 如果失败了 (状态=3)，canRequestRefund 会变 true (逻辑里允许重试)
    // 所以“退款被拒”时，按钮会重新出现，允许再次申请，逻辑闭环完美。

    final showRewardDetails = item.orderStatus != 1 && item.orderStatus != 4;

    List<Widget> buttons = [
      if (canRefund)
        Button(
          height: 36.h,
          onPressed: onRequestRefund,
          variant: ButtonVariant.outline,
          // 如果是被拒状态，按钮文案可以改成 "Re-Apply"
          child: Text(
            item.refundStatus == 3 ? 'Re-Apply Refund' : 'Refund',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
        ),

      Button(
        height: 36.h,
        variant: ButtonVariant.outline,
        onPressed: onViewFriends,
        child: Text(
          'common.view.friends'.tr(),
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
        ),
      ),
      if (showRewardDetails)
        Button(
          variant: ButtonVariant.outline,
          height: 36.h,
          onPressed: onViewRewardDetails,
          child: Text(
            'common.award.details'.tr(),
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.sp),
          ),
        )
      else
        Button(
          height: 36.h,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 16.w,
            height: 16.h,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: onTeamUp,
          child: Text('common.team.up'.tr()),
        ),
      if (item.isWon)
        Button(
          height: 36.h,
          variant: ButtonVariant.primary,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 16.w,
            height: 16.h,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: onClaimPrize, // 注意这里应该是 onClaimPrize
          child: null,
        ),
    ];

    return Container(
      width: double.infinity,
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8.w,
        runSpacing: 12.h,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: buttons,
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 虚线分割线
/// ---------------------------------------------------------
class _DashedSeparator extends StatelessWidget {
  final double height;
  final Color color;

  const _DashedSeparator({required this.color, this.height = 1.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color.withOpacity(0.3)),
              ),
            );
          }),
        );
      },
    );
  }
}

/// ---------------------------------------------------------
/// 骨架屏 (Skeleton) - 模拟订单卡片加载状态
/// ---------------------------------------------------------
class OrderItemContainerSkeleton extends StatelessWidget {
  final bool isLast;

  const OrderItemContainerSkeleton({super.key, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        // 保持和真实 Item 一样的底部间距逻辑，避免加载完跳动
        bottom: isLast ? 32.h : 12.h,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: context.borderSecondary, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 顶部：日期占位
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton.react(width: 100.w, height: 12.w),
                Skeleton.react(width: 60.w, height: 18.w, borderRadius: BorderRadius.circular(4.w)),
              ],
            ),
            SizedBox(height: 12.h),

            // 2. 中部：图片 + 标题
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片占位 (80x80)
                Skeleton.react(
                  width: 80.w,
                  height: 80.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                SizedBox(width: 12.w),
                // 文字占位
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 模拟两行标题
                      Skeleton.react(width: double.infinity, height: 14.h),
                      SizedBox(height: 8.w),
                      Skeleton.react(width: 150.w, height: 14.h),
                      SizedBox(height: 8.w),
                      // 模拟销量文字
                      Skeleton.react(width: 80.w, height: 12.h),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // 3. 信息行占位 (价格、数量)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton.react(width: 60.w, height: 12.w),
                Skeleton.react(width: 40.w, height: 12.w),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton.react(width: 60.w, height: 12.w),
                Skeleton.react(width: 30.w, height: 12.w),
              ],
            ),

            SizedBox(height: 16.h),
            // 分割线
            Container(height: 1, color: context.borderSecondary.withOpacity(0.3)),
            SizedBox(height: 16.h),

            // 4. 底部：总价 + 按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左侧总价
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.react(width: 35.w, height: 10.h),
                    SizedBox(height: 4.w),
                    Skeleton.react(width: 60.w, height: 18.h),
                  ],
                ),
                // 右侧按钮组
                Flexible(child:Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Skeleton.react(
                      width: 60.w,
                      height: 36.h,
                    ),
                    SizedBox(width: 8.w),
                    Skeleton.react(
                      width: 65.w,
                      height: 36.h,
                    ),
                  ],
                ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}