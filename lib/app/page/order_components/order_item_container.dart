import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_app/app/page/order_detail_page.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animations/transparent_fade_route.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';

import 'refund_request_sheet.dart';

class OrderItemContainer extends StatelessWidget {
  final OrderItem item;
  final bool isLast;

  const OrderItemContainer({
    super.key,
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final String heroTag = 'order_card_${item.orderId}';
    // 使用 Extension 里的 getter
    final isWinning = item.isWon;

    Widget cardContent = Padding(
      padding: EdgeInsets.only(bottom: isLast ? 32.h : 12.h),
      child: Hero(
        tag: heroTag,
        // 关键修复：加一层 Material 避免 Hero 飞行时文字出现黄色下划线
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // 1. 高级感核心：中奖时使用极淡的金色渐变
              gradient: isWinning
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFBEB), // Amber 50
                        Colors.white,
                      ],
                    )
                  : null,
              color: isWinning ? null : context.bgPrimary,
              borderRadius: BorderRadius.circular(16.w),
              // 2. 边框：中奖金边
              border: isWinning
                  ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                  : Border.all(color: context.borderSecondary, width: 0.5),
              // 3. 阴影：中奖带金光
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

                      // 已退款信息
                      if (item.isRefunded) ...[
                        SizedBox(height: 12.h),
                        _OrderItemRefundInfo(item: item),
                      ],

                      // 操作按钮区 (未退款时显示)
                      if (!item.isRefunded) ...[
                        SizedBox(height: 20.h),
                        _OrderItemActions(
                          item: item,
                          onRequestRefund: () {
                            // 弹出退款申请 BottomSheet
                            RadixSheet.show(
                              builder: (context, close) => RefundRequestSheet(
                                orderId: item.orderId,
                                amount: '₱${item.finalAmount}', // 传入金额

                                onSubmit: (reason) {
                                  // 1. 关闭弹窗
                                  Navigator.pop(context);

                                  // 2. TODO: 调用真正的 API
                                  // ref.read(orderProvider.notifier).refundOrder(item.orderId, reason);

                                  // 3. 临时反馈
                                  print("Refund Reason: $reason");
                                  RadixToast.success(
                                    "Refund request submitted successfully",
                                  );
                                },
                              ),
                            );
                          },
                          onViewFriends: () {
                            if (item.group != null) {
                              appRouter.push(
                                '/group-member/?groupId=${item.group!.groupId}',
                              );
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
                            appRouter.push(
                              '/me/order/${item.orderId}/claim-prize',
                            );
                          },
                        ),
                      ],
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
        // 4. 动画修正：使用 slideY (从下往上浮出)
        .slideY(
          begin: 0.1,
          end: 0.0,
          duration: 400.ms,
          curve: Curves.easeOutQuad,
        )
        // 5. 中奖流光特效
        .then(delay: 200.ms)
        .shimmer(
          duration: 1500.ms,
          color: isWinning
              ? const Color(0xFFFFD700).withOpacity(0.4)
              : Colors.transparent,
          angle: 0.8,
        );
  }
}

/// ---------------------------------------------------------
/// 顶部状态栏 (Status Header)
/// ---------------------------------------------------------
class _OrderItemStatusHeader extends StatelessWidget {
  final OrderItem item;

  const _OrderItemStatusHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    String statusText = '';
    Color statusColor = context.textBrandSecondary700;
    Color statusBg = context.textBrandSecondary700.withOpacity(0.1);

    // ✅ 使用 Model 中定义的 Enum 扩展，不再手写数字判断
    switch (item.orderStatusEnum) {
      case OrderStatus.won:
        statusText = 'Winner';
        statusColor = const Color(0xFFD97706); // Amber 700
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
        statusText = 'Paid'; // 或 Completed
        statusColor = context.textBrandPrimary900;
        statusBg = context.textBrandPrimary900.withOpacity(0.05);
        break;
      case OrderStatus.processing:
        statusText = 'Processing';
        statusColor = context.textBrandPrimary900;
        statusBg = context.textBrandPrimary900.withOpacity(0.05);
        break;
      case OrderStatus.pending:
      default:
        statusText = 'Pending';
        statusColor = context.textBrandSecondary700;
        statusBg = context.textBrandSecondary700.withOpacity(0.1);
        break;
    }

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
              color: statusBg,
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 头部商品信息 (Header)
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
            memCacheWidth: (80.w * MediaQuery.of(context).devicePixelRatio)
                .round(),
            errorWidget: (_, __, ___) => Container(
              color: context.borderSecondary,
              child: Icon(CupertinoIcons.photo, color: context.textTertiary600),
            ),
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
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textTertiary600,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${FormatHelper.formatWithCommas(item.buyQuantity)}/${FormatHelper.formatWithCommas(item.treasure.seqShelvesQuantity)} ',
                    ),
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
/// 订单详细数据 (Info)
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
              item.isRefunded
                  ? 'common.refund'.tr()
                  : 'common.total.price'.tr(),
              style: TextStyle(
                fontSize: 14.sp,
                color: context.textPrimary900,
                fontWeight: FontWeight.bold,
              ),
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
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: context.textSecondary700),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimary900,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 中奖/拼团成功展示区 (Success Section)
/// ---------------------------------------------------------
class _OrderItemGroupSuccess extends StatelessWidget {
  final OrderItem item;

  const _OrderItemGroupSuccess({required this.item});

  @override
  Widget build(BuildContext context) {
    // 如果既没拼团成功也没中奖，隐藏
    if (!item.showGroupSuccessSection) return const SizedBox.shrink();

    final Color bgColor = item.isWon
        ? const Color(0xFFFFFBEB)
        : context.bgSecondary;

    final Color borderColor = item.isWon
        ? const Color(0xFFFCD34D).withOpacity(0.5)
        : Colors.transparent;

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
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textSecondary700,
            fontWeight: FontWeight.w500,
          ),
        ),
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
/// 退款详情展示 (Refund Info)
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
                      Icon(
                        Icons.assignment_return_outlined,
                        size: 16.w,
                        color: context.textSecondary700,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Refund Details',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary700,
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
                  Divider(
                    height: 1,
                    color: context.borderSecondary.withOpacity(0.5),
                  ),
                  SizedBox(height: 8.w),
                  _InfoRow(
                    label: 'Reason',
                    value: widget.item.refundReason ?? 'Other',
                  ),
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
/// 底部操作栏 (Actions)
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
    final showRewardDetails = item.orderStatus != 1 && item.orderStatus != 4;

    //  使用 Model 里的 canRequestRefund 智能判断
    final canRefund = item.canRequestRefund;

    List<Widget> buttons = [
      if (canRefund)
        Button(
          height: 36.h,
          onPressed: onRequestRefund,
          variant: ButtonVariant.outline,
          child: Text(
            'Refund',
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
          onPressed: onTeamUp,
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
/// 骨架屏 (Skeleton)
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
        bottom: isLast ? 32.w : 16.w,
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(16.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Skeleton.react(
                  width: 80.w,
                  height: 80.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: double.infinity, height: 14.h),
                      SizedBox(height: 8.w),
                      Skeleton.react(width: 100.w, height: 12.h),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Skeleton.react(width: double.infinity, height: 12.w),
            SizedBox(height: 12.w),
            Skeleton.react(width: double.infinity, height: 12.w),
            SizedBox(height: 12.w),
            Row(
              children: [
                const Spacer(),
                Skeleton.react(
                  width: 100.w,
                  height: 36.h,
                  borderRadius: BorderRadius.circular(18.w),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
