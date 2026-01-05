import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/order_detail_page.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/animations/transparent_fade_route.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    final isWinning = item.isWon;

    Widget cardContent = Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 32.h : 12.h,
      ),
      child: Hero(
        tag: heroTag,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // 1. 高级感核心：中奖时使用极淡的金色渐变，普通时纯白
              gradient: isWinning
                  ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFBEB), // Amber 50 (极淡金)
                  Colors.white,
                ],
              )
                  : null,
              color: isWinning ? null : context.bgPrimary,
              borderRadius: BorderRadius.circular(16.w),
              // 2. 边框：中奖金边，普通细灰边
              border: isWinning
                  ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                  : Border.all(color: context.borderSecondary, width: 0.5),
              // 3. 阴影：中奖带金光，普通带黑影
              boxShadow: [
                BoxShadow(
                  color: isWinning
                      ? const Color(0xFFFFD700).withValues(alpha: 0.15)
                      : context.fgPrimary900.withValues(alpha: 0.04),
                  blurRadius: 20.w, // 加大模糊半径，显得更浮空
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
                      // 虚线分割
                      _DashedSeparator(color: context.borderSecondary),
                      SizedBox(height: 16.h),

                      _OrderItemInfo(item: item),

                      // 中奖/拼团信息展示区
                      _OrderItemGroupSuccess(item: item),

                      if (item.isRefunded) ...[
                        SizedBox(height: 12.h),
                        _OrderItemRefundInfo(item: item),
                      ],

                      if (!item.isRefunded) ...[
                        SizedBox(height: 20.h),
                        _OrderItemActions(
                          item: item,
                          // ... 你的回调逻辑保持不变 ...
                          onViewFriends: () {},
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
                          onTeamUp: () {},
                          onClaimPrize: () {},
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
    // 4. 动画修正：使用 slideY (从下往上) 代替 slideX
        .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
        .slideY(
      begin: 0.1, // 从下方 10% 的位置浮上来
      end: 0.0,
      duration: 400.ms,
      curve: Curves.easeOutQuad,
    )
    // 5. 中奖流光特效
        .then(delay: 200.ms)
        .shimmer(
      duration: 1500.ms,
      // 金色流光
      color: isWinning
          ? const Color(0xFFFFD700).withValues(alpha:0.4)
          : Colors.transparent,
      angle: 0.8,
    );
  }
}

/// Order item group success section
/// 修复后的中奖/拼团信息展示
class _OrderItemGroupSuccess extends StatelessWidget {
  final OrderItem item;

  const _OrderItemGroupSuccess({required this.item});

  @override
  Widget build(BuildContext context) {
    // 如果既没拼团成功也没中奖，直接隐藏
    if (!item.isGroupSuccess && !item.isWon) return const SizedBox.shrink();

    // 根据状态决定背景色
    final Color bgColor = item.isWon
        ? const Color(0xFFFFFBEB) // 中奖金底
        : context.bgSecondary;    // 普通拼团灰底

    final Color borderColor = item.isWon
        ? const Color(0xFFFCD34D).withValues(alpha:0.5) // 中奖金框
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
          // 1. 拼团成功信息
          if (item.isGroupSuccess)
            _SuccessRow(
              label: 'group-success'.tr(), // 需添加文案
              // 这里展示获得的奖励币
              value: '${item.prizeCoin ?? 0} Coins',
              icon: Icons.group_add_rounded,
              valueColor: context.textBrandSecondary700,
            ),

          if (item.isGroupSuccess && item.isWon)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.w),
              child: Divider(height: 1, color: borderColor.withValues(alpha:0.5)),
            ),

          // 2. 中奖信息 (大奖)
          if (item.isWon)
            _SuccessRow(
              label: 'common.winning.number'.tr(),
              // 这里展示奖品价值
              value: item.prizeAmount ?? '₱0.00',
              icon: Icons.emoji_events_rounded,
              valueColor: const Color(0xFFD97706), // 深金色文字
              isBold: true,
            ),
        ],
      ),
    );
  }
}

// 辅助小组件：用于展示中奖/拼团的一行信息
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

class _OrderItemStatusHeader extends StatelessWidget {
  final OrderItem item;

  const _OrderItemStatusHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    // 简单的状态映射逻辑 (根据实际业务调整)
    String statusText = 'Processing';
    Color statusColor = context.textBrandSecondary700;
    Color statusBg = context.textBrandSecondary700.withValues(alpha:0.1);

    if (item.isWon) {
      statusText = 'Winner';
      statusColor = const Color(0xFFD97706); // Amber 700
      statusBg = const Color(0xFFFFFBEB); // Amber 50
    } else if (item.isRefunded) {
      statusText = 'Refunded';
      statusColor = context.utilityError500;
      statusBg = context.utilityError500.withValues(alpha:0.1);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
      decoration: BoxDecoration(
        color: context.bgSecondary.withValues(alpha:0.5), // 浅灰底色
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.w),
          topRight: Radius.circular(16.w),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 时间显示优化
          Text(
            // 假设 item 有 createTime，没有则用 mocking
            DateFormatHelper.format(item.createdAt, 'yyyy-MM-dd HH:mm'),
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textTertiary600,
              fontFamily: 'Monospace', // 等宽字体显专业
            ),
          ),
          // 状态胶囊
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

class _OrderItemHeader extends StatelessWidget {
  final OrderItem item;

  const _OrderItemHeader({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(8.w),
          child: CachedNetworkImage(
            imageUrl: item.treasure.treasureCoverImg,
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            //CachedNetworkImage 默认会按原图解码，80×80 的视图没必要解 1000px 原图,按像素密度下采样
            memCacheWidth: (80.w * MediaQuery.of(context).devicePixelRatio)
                .round(),
            memCacheHeight: (80.w * MediaQuery.of(context).devicePixelRatio)
                .round(),
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: const Duration(milliseconds: 120),
            errorWidget: (_, _, _) => Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: context.borderSecondary,
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Icon(
                CupertinoIcons.photo,
                size: 40.w,
                color: context.textTertiary600,
              ),
            ),
            placeholder: (_, _) => Skeleton.react(
              width: 80.w,
              height: 80.w,
              borderRadius: BorderRadius.circular(8.w),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.treasure.treasureName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              SizedBox(height: 9.w),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w400,
                    color: context.textTertiary600,
                    height: context.leadingXs,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${FormatHelper.formatWithCommas(item.buyQuantity)}/${FormatHelper.formatWithCommas(item.treasure.seqShelvesQuantity)}',
                    ),
                    TextSpan(text: ' '),
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

/// Order item information section
/// 显示订单的详细信息，如开奖日期、单价、数量和总价
/// Displays detailed information about the order, such as draw date, unit price, quantity, and total price.
/// Used in order list and order details pages.
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
        // 总价加大加粗
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
                // 更大的字号
                color: context.textBrandPrimary900,
                // 品牌色
                fontWeight: FontWeight.w900,
                // 极粗
                fontFamily: 'RobotoMono',
                // 数字用等宽字体
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
          style: TextStyle(
            fontSize: 13.sp,
            color: context.textSecondary700, // 标签颜色淡一点
          ),
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
                decoration: BoxDecoration(color: color.withValues(alpha:0.3)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _OrderItemActions extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onViewFriends;
  final VoidCallback? onViewRewardDetails;
  final VoidCallback? onTeamUp;
  final VoidCallback? onClaimPrize;

  const _OrderItemActions({
    required this.item,
    this.onViewFriends,
    this.onViewRewardDetails,
    this.onTeamUp,
    this.onClaimPrize,
  });

  @override
  Widget build(BuildContext context) {
    // 逻辑保持不变
    final isStatus1Or4 = item.orderStatus == 1 || item.orderStatus == 4;
    final showRewardDetails = !isStatus1Or4;

    List<Widget> right = [
      Button(
        paddingX: 20.w,
        height: 36.w,
        //稍微调小一点高度，显得更精致
        variant: ButtonVariant.outline,
        onPressed: onViewFriends,
        child: Text('common.view.friends'.tr()),
      ),
      if (showRewardDetails)
        Button(
          paddingX: 20.w,
          variant: ButtonVariant.outline,
          height: 36.w,
          onPressed: onViewRewardDetails,
          child: Text('common.award.details'.tr()),
        )
      else
        Button(
          height: 36.w,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 16.w, // 图标也顺带调小适配
            height: 16.w,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: onTeamUp,
          child: Text('common.team.up'.tr()),
        ),

      if (item.isWon) ...[
        Button(
          paddingX: 12.w,
          height: 36.w,
          variant: ButtonVariant.primary,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 16.w,
            height: 16.w,
            colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          onPressed: onTeamUp,
          child: null, // 图标按钮
        ),
      ],
    ];

    // --- 核心修改 ---
    // 使用 Wrap 实现自动换行 + 右对齐
    return Container(
      width: double.infinity, // 占满宽度
      alignment: Alignment.centerRight, // 容器内部靠右
      child: Wrap(
        spacing: 12.w,
        // 水平间距 (左右按钮之间的空隙)
        runSpacing: 12.w,
        // 垂直间距 (如果换行了，上下两行的空隙)
        alignment: WrapAlignment.end,
        // 这一行让 Wrap 内部的元素靠右排列
        crossAxisAlignment: WrapCrossAlignment.center,
        // 垂直居中
        children: right,
      ),
    );
  }
}


/// Order item refund information section
/// 显示订单的退款信息，如退款原因
/// Displays refund information about the order, such as refund reason.
/// Used in order list and order details pages.
class _OrderItemRefundInfo extends StatefulWidget {
  final OrderItem item;

  const _OrderItemRefundInfo({required this.item});

  @override
  State<StatefulWidget> createState() => _OrderItemRefundInfoState();
}

class _OrderItemRefundInfoState extends State<_OrderItemRefundInfo>
    with SingleTickerProviderStateMixin {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => isOpen = !isOpen),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.refund.reason'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              AnimatedRotation(
                turns: isOpen ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 20.w,
                  color: context.textTertiary600,
                ),
              ),
            ],
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(
            padding: EdgeInsets.only(top: 8.w),
            child: Text(
              widget.item.refundReason ?? '----',
              style: TextStyle(
                fontSize: context.textSm,
                fontWeight: FontWeight.w600,
                color: context.textPrimary900,
                height: context.leadingSm,
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class OrderItemContainerSkeleton extends StatelessWidget {
  final bool isLast;

  const OrderItemContainerSkeleton({super.key, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isLast
          ? EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w, bottom: 32.w)
          : EdgeInsets.only(left: 16.w, right: 16.w, top: 16.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          borderRadius: BorderRadius.circular(8.w),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton.react(
                  width: 80.w,
                  height: 80.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: double.infinity, height: 14.h),
                      SizedBox(height: 9.w),
                      Skeleton.react(width: 120.w, height: 12.h),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Skeleton.react(width: double.infinity, height: 12.w),
            const SizedBox(height: 12),
            Skeleton.react(width: double.infinity, height: 12.w),
            const SizedBox(height: 12),
            Skeleton.react(width: double.infinity, height: 12.w),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SizedBox()),
                Skeleton.react(
                  width: 80.w,
                  height: 32.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
                const SizedBox(width: 8),
                Skeleton.react(
                  width: 100.w,
                  height: 32.w,
                  borderRadius: BorderRadius.circular(8.w),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
