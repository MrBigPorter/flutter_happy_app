import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/page/lucky_draw/lucky_draw_helpers.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/providers/lucky_draw_provider.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/features/share/services/share_service.dart';
import 'package:flutter_app/features/share/widgets/share_post.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/ui/index.dart';

import 'package:flutter_app/core/services/customer_service/customer_service_helper.dart';
import 'package:flutter_app/core/store/config_store.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  final List<String> imageList;
  final VoidCallback onClose;
  final String? blurhash;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.imageList,
    required this.onClose,
    this.blurhash,
  });

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  @override
  Widget build(BuildContext context) {
    final orderDetailAsyncValue = ref.watch(orderDetailProvider(widget.orderId));
    final double bottomBarHeight = 80.w;

    return orderDetailAsyncValue.when(
      loading: () => Scaffold(
        backgroundColor: context.bgPrimary,
        body: const OrderDetailSkeleton(),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: context.bgPrimary,
        appBar: AppBar(
          backgroundColor: context.bgPrimary,
          elevation: 0,
          leading: BackButton(
            color: context.textPrimary900,
            onPressed: widget.onClose,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48.w, color: context.textSecondary700),
              SizedBox(height: 16.w),
              Text(
                "order.detail.error_load".tr(),
                style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
              ),
              SizedBox(height: 24.w),
              Button(
                width: 120.w,
                height: 36.w,
                onPressed: () => ref.refresh(orderDetailProvider(widget.orderId)),
                child: Text(
                  "order.detail.retry".tr(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
      data: (orderDetail) {
        return DraggableScrollableScaffold(
          heroTag: 'order_card_${widget.orderId}',
          onDismiss: widget.onClose,
          bottomBar: _buildDynamicBottomBar(context, orderDetail, bottomBarHeight),
          headerBuilder: (context, dragProgress, scrollController) {
            return AnimatedHeader(
              scrollController: scrollController,
              title: orderDetail.treasure.treasureName,
              imageList: widget.imageList,
              onClose: widget.onClose,
            );
          },
          bodyBuilder: (context, scrollController, physics) {
            return SingleChildScrollView(
              controller: scrollController,
              physics: physics,
              padding: EdgeInsets.zero,
              child: Material(
                color: context.bgPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildParallaxBanner(context, scrollController),
                    Transform.translate(
                      offset: Offset(0, -24.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.w),
                            topRight: Radius.circular(24.w),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            )
                          ],
                        ),
                        padding: EdgeInsets.only(top: 24.w, bottom: bottomBarHeight),
                        child: _OrderDetailBody(orderDetail: orderDetail),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParallaxBanner(BuildContext context, ScrollController scrollController) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double offset = 0;
        // 修复多视图绑定：必须使用 positions.first.pixels
        if (scrollController.hasClients && scrollController.positions.isNotEmpty) {
          offset = scrollController.positions.first.pixels;
        }
        double scale = offset < 0 ? 1.0 + (offset.abs() / 356.w) * 0.5 : 1.0;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 356.h,
            child: widget.imageList.isEmpty
                ? Container(color: context.bgSecondary)
                : SwiperBanner(
              banners: widget.imageList,
              height: 356.w,
              showIndicator: true,
              borderRadius: 0,
              blurhash: widget.blurhash,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicBottomBar(BuildContext context, OrderDetailItem orderDetail, double height) {
    Widget? actionButton;
    final isUnpaid = orderDetail.payStatus == 0;
    final isRefunded = orderDetail.refundStatus != 0;
    final canViewGroup = orderDetail.payStatus == 1 &&
        !orderDetail.isRefunded &&
        !orderDetail.isCancelled &&
        orderDetail.group?.groupId != null;

    if (isRefunded) {
      actionButton = null;
    } else if (isUnpaid) {
      actionButton = Button(
        width: 200.w,
        height: 44.w,
        onPressed: () => RadixToast.success("order.detail.msg_pay".tr()),
        child: Text("order.detail.btn_pay".tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (canViewGroup) {
      actionButton = Button(
        width: 200.w,
        height: 44.w,
        onPressed: () {
          if (orderDetail.group?.groupId != null) {
            appRouter.push('/group-room?groupId=${orderDetail.group!.groupId}');
          }
        },
        trailing: Icon(Icons.group_outlined, size: 18.w, color: Colors.white),
        child: Text("order.detail.btn_friends".tr()),
      );
    }

    if (actionButton == null) return const SizedBox.shrink();

    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        top: 10.w,
        bottom: MediaQuery.of(context).padding.bottom + 10.w,
      ),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(top: BorderSide(color: context.fgPrimary900.withValues(alpha: 0.05), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), offset: const Offset(0, -4), blurRadius: 10)],
      ),
      child: Center(child: actionButton),
    );
  }
}

class AnimatedHeader extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String title;
  final List<String> imageList;
  final VoidCallback onClose;

  const AnimatedHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.imageList,
    required this.scrollController,
  });

  @override
  ConsumerState<AnimatedHeader> createState() => _AnimatedHeaderState();
}

class _AnimatedHeaderState extends ConsumerState<AnimatedHeader> {
  final sharePosterKey = GlobalKey<SharePostState>();
  String get _firstImage => widget.imageList.isNotEmpty ? widget.imageList.first : '';

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final webBaseUrl = ref.read(configProvider.select((state) => state.webBaseUrl));

    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (context, child) {
        double offset = 0;
        //  关键修复：不再直接使用 .offset，防止 Multiple Positions 断言崩溃
        if (widget.scrollController.hasClients && widget.scrollController.positions.isNotEmpty) {
          offset = widget.scrollController.positions.first.pixels;
        }

        double opacity = (offset / 120.0).clamp(0.0, 1.0);
        final double iconBgOpacity = 1.0 - opacity;

        return Container(
          height: paddingTop + kToolbarHeight,
          padding: EdgeInsets.only(top: paddingTop, right: 16.w),
          decoration: BoxDecoration(
            color: context.bgPrimary.withValues(alpha: opacity),
            border: Border(bottom: BorderSide(color: context.fgSecondary700.withValues(alpha: 0.1 * opacity), width: 1)),
          ),
          child: NavigationToolbar(
            leading: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  backgroundColor: context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: context.fgSecondary700),
                    onPressed: widget.onClose,
                  ),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 新增：官方客服入口
                CircleAvatar(
                  backgroundColor: context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                  child: IconButton(
                    icon: Icon(Icons.headset_mic_outlined, color: context.fgSecondary700),
                    onPressed: () {
                      // 极其优雅的 1 行代码调用
                      CustomerServiceHelper.startChat();
                    },
                  ),
                ),
                SizedBox(width: 8.w), // 间距
                if (widget.imageList.isNotEmpty)
                  CircleAvatar(
                    backgroundColor: context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                    child: IconButton(
                      icon: Icon(Icons.share_outlined, color: context.fgSecondary700),
                      onPressed: () {
                        ShareService.openSystemOrSheet(
                          ShareData(title: widget.title, url: '$webBaseUrl/$_firstImage', imageUrl: _firstImage),
                              () => RadixSheet.show(
                            headerBuilder: (context) => SharePost(data: ShareData(title: widget.title, url: '$webBaseUrl/$_firstImage', imageUrl: _firstImage)),
                            builder: (context, close) => ShareSheet(data: ShareData(title: widget.title, url: '$webBaseUrl/$_firstImage', imageUrl: _firstImage)),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderDetailItem orderDetail;
  const _OrderDetailBody({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSection(orderDetail: orderDetail).animate().fadeIn().slideY(begin: 0.1, end: 0),
        Divider(color: context.borderSecondary, thickness: 8.w),
        _OrderInfoSection(orderDetail: orderDetail).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
      ],
    );
  }
}

class _ProductSection extends StatelessWidget {
  final OrderItem orderDetail;
  const _ProductSection({required this.orderDetail});

  (String, Color, Color) _getStatusStyle(BuildContext context) {
    if (orderDetail.refundStatus != 0) {
      return ("order.detail.status.refund".tr(), context.utilityError500, context.utilityError50);
    }

    switch (orderDetail.orderStatusEnum) {
      case OrderStatus.won:
        return ('Winner', context.textPrimary900, context.bgBrandSecondary);
      case OrderStatus.groupSuccess:
        return ('Group Success', context.utilitySuccess500, context.utilitySuccess50);
      case OrderStatus.ended:
        return ('Draw Ended', context.textSecondary700, context.bgSecondary);
      case OrderStatus.paid:
        return ("order.detail.status.paid".tr(), context.utilitySuccess500, context.utilitySuccess50);
      case OrderStatus.processing:
        return ("order.detail.status.processing".tr(), context.utilityBrand500, context.utilityBrand50);
      case OrderStatus.cancelled:
        return ('Cancelled', context.textSecondary700, context.bgSecondary);
      case OrderStatus.refunded:
        return ("order.detail.status.refund".tr(), context.utilityError500, context.utilityError50);
      case OrderStatus.pending:
        return ("order.detail.status.pending".tr(), context.utilityWarning500, context.utilityWarning50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, fgColor, bgColor) = _getStatusStyle(context);
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
            margin: EdgeInsets.only(bottom: 12.w),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4.w)),
            child: Text(statusText, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: fgColor)),
          ),
          Text(orderDetail.treasure.treasureName, maxLines: 2, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w800, color: context.textPrimary900, height: 1.3)),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
            decoration: BoxDecoration(color: context.bgSecondary, borderRadius: BorderRadius.circular(4.w)),
            child: Text('${orderDetail.buyQuantity}/${orderDetail.treasure.seqShelvesQuantity} ${'common.sold.lowercase'.tr()}', style: TextStyle(fontSize: 12.sp, color: context.textSecondary700)),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoSection extends ConsumerWidget {
  final OrderDetailItem orderDetail;
  const _OrderInfoSection({required this.orderDetail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentTimeStr = orderDetail.createdAt != null ? DateFormatHelper.formatFull(DateTime.fromMillisecondsSinceEpoch(orderDetail.createdAt!.toInt())) : '-';

    // 将金额安全解析为 double，用于判断“抵扣额是否大于0”，避免出现 "- 0.00" 的尴尬 UI
    final double couponAmt = double.tryParse(orderDetail.couponAmount.toString()) ?? 0.0;
    final double coinAmt = double.tryParse(orderDetail.coinAmount.toString()) ?? 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (orderDetail.refundStatus != 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 24.w),
              decoration: BoxDecoration(color: context.utilityError50, borderRadius: BorderRadius.circular(8.w), border: Border.all(color: context.utilityError200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("order.detail.after_sales".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: context.utilityError700)),
                  Text("order.detail.refund_notice".tr(), style: TextStyle(fontSize: 12.sp, color: context.textSecondary700)),
                ],
              ),
            ),
          if (orderDetail.showGroupSuccessSection) ...[
            _OrderDrawResultCard(orderDetail: orderDetail),
            SizedBox(height: 24.w),
          ],
          _OrderLuckyDrawSection(orderId: orderDetail.orderId),
          Text("order.detail.summary".tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
          SizedBox(height: 16.w),
          _OrderInfoRow(title: "order.detail.item_price".tr(), value: orderDetail.unitPrice),
          _OrderInfoRow(title: "order.detail.quantity".tr(), value: 'x${orderDetail.buyQuantity}'),
          _OrderInfoRow(title: "order.detail.total_price".tr(), value: orderDetail.originalAmount),

          // ========================================================
          // 核心修复 1 & 2：准确分离并映射 优惠券(Coupon) 和 金币(Coin)
          // ========================================================
          if (couponAmt > 0)
            _OrderInfoRow(
              title: "order.detail.coupon".tr(),
              value: '- ${orderDetail.couponAmount}',
              valueColor: context.utilityError500,
            ),

          if (coinAmt > 0)
            _OrderInfoRow(
              title: "common.total.discount".tr(),
              value: '- ${orderDetail.coinAmount}',
              valueColor: context.utilityError500,
            ),

          Divider(color: context.borderSecondary, height: 32.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("order.detail.total_payment".tr(), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
              Text(orderDetail.finalAmount, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, color: context.textPrimary900)),
            ],
          ),
          SizedBox(height: 24.w),
          Text("order.detail.info_title".tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
          SizedBox(height: 16.w),
          _OrderInfoRow(title: "order.detail.order_id".tr(), value: orderDetail.orderNo, isCopyable: true),
          _OrderInfoRow(title: "order.detail.pay_time".tr(), value: paymentTimeStr),

          if (orderDetail.transactions.isNotEmpty) ...[
            SizedBox(height: 20.w),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: context.bgSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12.w), border: Border.all(color: context.borderSecondary, width: 0.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("order.detail.tx_history".tr(), style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: context.textSecondary700)),
                  ...orderDetail.transactions.map((item) {
                    // ========================================================
                    // balanceType: 1=现金余额(Wallet), 2=金币(Coin)
                    // ========================================================
                    final String payMethodName = item.balanceType == 2 ? 'COIN' : 'WALLET';

                    return Column(
                      children: [
                        _OrderInfoRow(
                            title: "order.detail.tx_no".tr(),
                            value: item.transactionNo.length > 20 ? '${item.transactionNo.substring(0, 20)}...' : item.transactionNo,
                            isSmall: true,
                            isCopyable: true
                        ),
                        _OrderInfoRow(
                            title: "order.detail.pay_method".tr(),
                            value: payMethodName,
                            isSmall: true
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _OrderLuckyDrawSection extends ConsumerWidget {
  const _OrderLuckyDrawSection({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(luckyDrawOrderTicketProvider(orderId));

    return asyncValue.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Padding(
        padding: EdgeInsets.only(bottom: 24.w),
        child: _OrderLuckyDrawMessageCard(
          title: 'Lucky Draw unavailable',
          subtitle: 'Unable to check this order ticket right now. Pull to refresh and try again.',
          icon: Icons.error_outline_rounded,
          accentColor: context.textErrorPrimary600,
          action: Button(
            width: 108.w,
            height: 32.h,
            variant: ButtonVariant.outline,
            onPressed: () => ref.invalidate(luckyDrawOrderTicketProvider(orderId)),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (response) {
        if (!response.hasTicket || response.ticket == null) {
          return const SizedBox.shrink();
        }

        final ticket = response.ticket!;

        if (ticket.result != null) {
          return Padding(
            padding: EdgeInsets.only(bottom: 24.w),
            child: _OrderLuckyDrawResultBanner(
              ticket: ticket,
              result: ticket.result!,
              onViewResults: openLuckyDrawResultsPage,
            ),
          );
        }

        if (ticket.isExpired) {
          return Padding(
            padding: EdgeInsets.only(bottom: 24.w),
            child: _OrderLuckyDrawMessageCard(
              title: 'Lucky Draw ticket expired',
              subtitle: ticket.expiredAt != null
                  ? 'This ticket expired on ${_formatLuckyDrawTime(ticket.expiredAt)}.'
                  : 'This ticket can no longer be used.',
              icon: Icons.timer_off_rounded,
              accentColor: context.textSecondary700,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 24.w),
          child: _OrderLuckyDrawEntryBanner(
            ticket: ticket,
            onDrawNow: () async {
              final result = await openLuckyDrawWheelForOrder(
                ref: ref,
                orderId: orderId,
                ticketId: ticket.ticketId,
              );
              if (result == luckyDrawWheelReturnToResults) {
                await openLuckyDrawResultsPage();
              }
            },
          ),
        );
      },
    );
  }
}

class _OrderLuckyDrawEntryBanner extends StatelessWidget {
  const _OrderLuckyDrawEntryBanner({
    required this.ticket,
    required this.onDrawNow,
  });

  final LuckyDrawTicket ticket;
  final Future<void> Function() onDrawNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.bgPrimary, context.bgBrandPrimary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: const Color(0xFFFFC789)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Icon(
              Icons.local_activity_rounded,
              color: const Color(0xFFFC7701),
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.activityName ?? 'This order has a Lucky Draw ticket',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8A3D00),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  ticket.expiredAt != null
                      ? 'Use it before ${_formatLuckyDrawTime(ticket.expiredAt)}'
                      : 'Draw now to win coupons, coins, or balance',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textBrandPrimary900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Button(
            width: 100.w,
            height: 32.h,
            onPressed: onDrawNow,
            child: const Text('Draw Now'),
          ),
        ],
      ),
    );
  }
}

class _OrderLuckyDrawResultBanner extends StatelessWidget {
  const _OrderLuckyDrawResultBanner({
    required this.ticket,
    required this.result,
    required this.onViewResults,
  });

  final LuckyDrawTicket ticket;
  final LuckyDrawResolvedResult result;
  final Future<void> Function() onViewResults;

  @override
  Widget build(BuildContext context) {
    final prizeType = result.prizeTypeEnum;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: context.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: prizeType.bgColor(context),
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Icon(
                  prizeType.icon,
                  color: prizeType.color(context),
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.prizeName ?? prizeType.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      ticket.activityName ?? 'Lucky Draw result',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.textSecondary700,
                      ),
                    ),
                  ],
                ),
              ),
              Button(
                width: 118.w,
                height: 32.h,
                variant: ButtonVariant.outline,
                onPressed: onViewResults,
                child: const Text('My Results'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _OrderInfoRow(title: 'Lucky Draw', value: 'Already drawn'),
          if (result.prizeValue != null)
            _OrderInfoRow(
              title: 'Prize Value',
              value: result.prizeValue.toString(),
              valueColor: prizeType.color(context),
            ),
          _OrderInfoRow(
            title: 'Result Time',
            value: _formatLuckyDrawTime(result.drawnAt ?? result.createdAt),
          ),
        ],
      ),
    );
  }
}

class _OrderLuckyDrawMessageCard extends StatelessWidget {
  const _OrderLuckyDrawMessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.action,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: context.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Icon(icon, color: accentColor, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondary700,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            SizedBox(width: 8.w),
            action!,
          ],
        ],
      ),
    );
  }
}

String _formatLuckyDrawTime(int? timestamp) {
  if (timestamp == null || timestamp <= 0) return '--';
  return DateFormatHelper.format(timestamp, 'yyyy-MM-dd HH:mm');
}

class _OrderDrawResultCard extends StatelessWidget {
  final OrderDetailItem orderDetail;

  const _OrderDrawResultCard({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    final isWon = orderDetail.isWon;
    final isEnded = orderDetail.isEnded;
    final isGroupSuccess = orderDetail.isGroupSuccess;
    final drawnAt = orderDetail.drawnAt;

    final bgColor = context.bgPrimary;
    final borderColor = context.borderPrimary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGroupSuccess)
            _OrderInfoRow(
              title: 'Group Status',
              value: 'Success · Waiting for draw',
              valueColor: context.utilitySuccess500,
            ),
          if (isWon)
            _OrderInfoRow(
              title: 'Draw Result',
              value: 'Congratulations, you won',
              valueColor: const Color(0xFFD97706),
            ),
          if (isEnded)
            _OrderInfoRow(
              title: 'Draw Result',
              value: 'Better luck next time',
              valueColor: context.textSecondary700,
            ),
          if (orderDetail.prizeAmount != null && isWon)
            _OrderInfoRow(
              title: 'Prize',
              value: orderDetail.prizeAmount!,
              valueColor: const Color(0xFFD97706),
            ),
          if (drawnAt != null)
            _OrderInfoRow(
              title: 'Draw Time',
              value: DateFormatHelper.format(drawnAt, 'yyyy-MM-dd HH:mm'),
            ),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool isCopyable;
  final bool isSmall;

  const _OrderInfoRow({required this.title, required this.value, this.valueColor, this.isCopyable = false, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    Widget valWidget = Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isSmall ? 12.sp : 14.sp, color: valueColor ?? (isSmall ? context.textSecondary700 : context.textPrimary900), fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600));
    if (isCopyable) {
      valWidget = GestureDetector(
        onTap: () { Clipboard.setData(ClipboardData(text: value)); RadixToast.success(value); },
        child: Row(mainAxisSize: MainAxisSize.min, children: [valWidget, SizedBox(width: 4.w), Icon(Icons.copy, size: 12.w, color: context.textTertiary600)]),
      );
    }
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(title, style: TextStyle(fontSize: isSmall ? 12.sp : 14.sp, color: context.textSecondary700)), Flexible(child: valWidget)],
      ),
    );
  }
}

class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Skeleton.react(width: double.infinity, height: 356.w),
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.react(width: double.infinity, height: 24.w),
                      SizedBox(height: 12.w),
                      Skeleton.react(width: 120.w, height: 16.w),
                      SizedBox(height: 24.w),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(6, (index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.w),
                            child: Row(
                              children: [
                                Skeleton.react(width: 80.w, height: 16.w),
                                Spacer(),
                                Skeleton.react(width: 100.w, height: 16.w),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          height: 80.w + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            top: 10.w,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: context.bgPrimary,
            border: Border(
              top: BorderSide(
                color: context.fgPrimary900.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Skeleton.react(
              width: 200.w,
              height: 44.w,
              borderRadius: BorderRadius.circular(22.w),
            ),
          ),
        )
      ],
    );
  }
}