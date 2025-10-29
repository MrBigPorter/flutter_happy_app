import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../ui/modal/radix_sheet.dart';

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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: isLast
            ? Border(
                bottom: BorderSide(color: context.borderTertiary, width: 1),
              )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Order item header section
          _OrderItemHeader(item: item),
          SizedBox(height: 8.w),

          /// Order item information section
          _OrderItemInfo(item: item),

          /// group success info, winning info
          _OrderItemGroupSuccess(item: item),
          if (item.isRefunded) ...[
            SizedBox(height: 12.w),

            /// Order item refund information section
            _OrderItemRefundInfo(item: item),
          ],
          if (item.isWon) ...[
            SizedBox(height: 12.w),

            /// tip fro other bag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.w),
                color: context.alphaBlack5,
              ),
              child: Text(
                'the-other-bag'.tr(),
                style: TextStyle(
                  fontSize: context.textXs,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary700,
                  height: context.leadingXs,
                ),
              ),
            ),
          ],

          if (!item.isRefunded) ...[
            SizedBox(height: 12.w),

            /// Order item actions section
            _OrderItemActions(
                item: item,
                onViewFriends: () {
                  RadixSheet.show(
                    builder: (ctx, close) => SizedBox(
                      width: double.infinity,
                      height: 200.w,
                      child: Center(
                        child: Text('This is a sheet dialog'),
                      ),
                    ),
                  );
                },
                onViewRewardDetails: () {
                  AppRouter.router.push('/me/order/${item.id}/reward-details');
                },
                onTeamUp: () {
                  AppRouter.router.push('/me/order/${item.id}/team-up');
                },
                onClaimPrize: () {
                  AppRouter.router.push('/me/order/${item.id}/claim-prize');
                },
            ),
          ],
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
            imageUrl: proxied(item.treasureCoverImg),
            width: 80.w,
            height: 80.w,
            fit: BoxFit.cover,
            //CachedNetworkImage 默认会按原图解码，80×80 的视图没必要解 1000px 原图,按像素密度下采样
            memCacheWidth: (80.w * MediaQuery.of(context).devicePixelRatio).round(),
            memCacheHeight: (80.w * MediaQuery.of(context).devicePixelRatio).round(),
            fadeInDuration: const Duration(milliseconds: 120),
            fadeOutDuration: const Duration(milliseconds: 120),
            errorWidget: (_, __, ___) => Container(
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
            placeholder: (_, __) => Skeleton.react(
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
                item.treasureName,
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
                          '${FormatHelper.formatWithCommas(item.purchaseCount)}/${FormatHelper.formatWithCommas(item.stockQuantity)}',
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
    Widget line(String left, String right) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: context.textSm,
              fontWeight: FontWeight.w600,
              color: context.textPrimary900,
              height: context.leadingSm,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: context.textSm,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
              height: context.leadingSm,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!item.lotteryTime.isNullOrEmpty)
          line(
            'common.draw.date'.tr(),
            DateFormatHelper.formatFull(item.lotteryTime),
          ),
        SizedBox(height: 12.w),
        line(
          'common.ticket.price'.tr(),
          FormatHelper.formatWithCommasAndDecimals(
            item.totalAmount / item.entries,
          ),
        ),
        SizedBox(height: 12.w),
        line('common.tickets.number'.tr(), '${item.entries}'),
        SizedBox(height: 12.w),
        line(
          item.isRefunded ? 'common.refund'.tr() : 'common.total.price'.tr(),
          '₱${item.totalAmount}',
        ),
      ],
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
    final isStatus1Or4 = item.orderStatus == 1 || item.orderStatus == 4;
    final showRewardDetails = !isStatus1Or4;

    List<Widget> right = [
      Button(
        paddingX: 20.w,
        height: 44.w,
        variant: ButtonVariant.outline,
        onPressed: () {
          if(onViewFriends != null){
            onViewFriends!();
          }
        },
        child: Text('common.view.friends'.tr()),
      ),
      if (showRewardDetails)
        Button(
          paddingX: 20.w,
          variant: ButtonVariant.outline,
          height: 44.w,
          onPressed: () {
            if(onViewRewardDetails != null){
              onViewRewardDetails!();
            }
          },
          child: Text('common.award.details').tr(),
        )
      else
        Button(
          height: 44.w,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(
              context.textWhite,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () {
            if(onTeamUp != null){
              onTeamUp!();
            }
          },
          child: Text('common.team.up').tr(),
        ),

      if (item.isWon) ... [
        Button(
          paddingX: 12.w,
          height: 44.w,
          variant: ButtonVariant.primary,
          trailing: SvgPicture.asset(
            'assets/images/team-up.svg',
            width: 20.w,
            height: 20.w,
            colorFilter: ColorFilter.mode(context.textWhite, BlendMode.srcIn),
          ),
          onPressed: () {
            if(onTeamUp != null){
              onTeamUp!();
            }
          },
          child: null,
        ),
        if(item.isRewardPending) ...[
          Button(
              width: double.infinity,
              onPressed: (){
                if(onClaimPrize != null){
                  onClaimPrize!();
                }
              },
              child: Text('confirm.win.receive.award'.tr())
          )
        ],
        if((item.isRewardClaim||item.isRewardCashOut)&&item.isPhysical||(item.isRewardCashOut&&item.isVirtual)) ...[
          Button(
              width: double.infinity,
              onPressed: (){
                AppRouter.router.push('/me/confirm-win/${item.id}');
              },
              child: Text('confirm.win.check.award.information'.tr())
          )
        ]

      ]
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Wrap(
              spacing: 8.w,
              runSpacing: 8.w,
              alignment: WrapAlignment.end,
              children: right
          ),
        )
      ],
    );
  }
}

/// Order item group success section
/// 显示订单的拼团成功信息和中奖信息
/// Displays group success information and winning information about the order.
/// Used in order list and order details pages.
/// Only shown when the order is part of a group purchase or has won a prize.
class _OrderItemGroupSuccess extends StatelessWidget {
  final OrderItem item;

  const _OrderItemGroupSuccess({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (item.isGroupSuccess) ...[
          SizedBox(height: 12.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'group-friend-0'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              Text(
                '${item.friend != "" ? item.friend : '----'}',
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'get-rewards'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              Column(
                children: [
                  Text(
                    'number.treasure.coin'.tr(
                      namedArgs: {'number': item.prizeCoin.toString()},
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.textBrandSecondary700,
                      fontSize: context.textSm,
                      height: context.leadingSm,
                    ),
                  ),
                  Text(
                    'redeem.worth.number'.tr(
                      namedArgs: {
                        'number': FormatHelper.formatWithCommasAndDecimals(
                          item.prizeAmount ?? 0,
                        ),
                      },
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textQuaternary500,
                      fontSize: context.textXs,
                      height: context.leadingXs,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        if (item.isWon) ...[
          SizedBox(height: 12.w),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.winning.number'.tr(),
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary900,
                  height: context.leadingSm,
                ),
              ),
              Column(
                children: [
                  Text(
                    '${item.shareCoin ?? 0} ${'common.treasureCoins'.tr()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: context.textBrandSecondary700,
                      fontSize: context.textSm,
                      height: context.leadingSm,
                    ),
                  ),
                  Text(
                    'redeem.worth.number'.tr(
                      namedArgs: {
                        'number': FormatHelper.formatWithCommasAndDecimals(
                          int.tryParse('${item.denomination}') ?? 0,
                        ),
                      },
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.textQuaternary500,
                      fontSize: context.textXs,
                      height: context.leadingXs,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
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
