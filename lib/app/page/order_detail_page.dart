import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/features/share/services/share_service.dart';
import 'package:flutter_app/features/share/widgets/share_post.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/ui/index.dart';

import '../../core/store/config_store.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  final List<String> imageList;
  final VoidCallback onClose;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.imageList,
    required this.onClose,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildDynamicBottomBar(BuildContext context, OrderDetailItem orderDetail, double height) {
    Widget? actionButton;
    final isPaid = orderDetail.payStatus == 1 && orderDetail.orderStatus == 1;
    final isUnpaid = orderDetail.payStatus == 0;
    final isRefunded = orderDetail.refundStatus != 0;

    if (isRefunded) {
      actionButton = null;
    } else if (isUnpaid) {
      actionButton = Button(
        width: 200.w,
        height: 44.w,
        onPressed: () => RadixToast.success("order.detail.msg_pay".tr()),
        child: Text("order.detail.btn_pay".tr(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    } else if (isPaid) {
      actionButton = Button(
        width: 200.w,
        height: 44.w,
        onPressed: () {
          if (orderDetail.group?.groupId != null) {
            appRouter.push('/product/${orderDetail.group!.groupId}/group');
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
    if (orderDetail.refundStatus != 0) return ("order.detail.status.refund".tr(), context.utilityError500, context.utilityError50);
    if (orderDetail.payStatus == 1) return ("order.detail.status.paid".tr(), context.utilitySuccess500, context.utilitySuccess50);
    return ("order.detail.status.pending".tr(), context.utilityWarning500, context.utilityWarning50);
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

class _OrderInfoSection extends StatelessWidget {
  final OrderDetailItem orderDetail;
  const _OrderInfoSection({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    final paymentTimeStr = orderDetail.createdAt != null ? DateFormatHelper.formatFull(DateTime.fromMillisecondsSinceEpoch(orderDetail.createdAt!.toInt())) : '-';

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
          Text("order.detail.summary".tr(), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
          SizedBox(height: 16.w),
          _OrderInfoRow(title: "order.detail.item_price".tr(), value: orderDetail.unitPrice),
          _OrderInfoRow(title: "order.detail.quantity".tr(), value: 'x${orderDetail.buyQuantity}'),
          _OrderInfoRow(title: "order.detail.total_price".tr(), value: orderDetail.originalAmount),
          _OrderInfoRow(title: "order.detail.coupon".tr(), value: '- ${orderDetail.coinAmount}', valueColor: context.utilityError500),
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
                  ...orderDetail.transactions.map((item) => Column(
                    children: [
                      _OrderInfoRow(title: "order.detail.tx_no".tr(), value: item.transactionNo.length > 20 ? '${item.transactionNo.substring(0, 20)}...' : item.transactionNo, isSmall: true, isCopyable: true),
                      _OrderInfoRow(title: "order.detail.pay_method".tr(), value: item.balanceType.toString().toUpperCase(), isSmall: true),
                    ],
                  )),
                ],
              ),
            ),
          ]
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
      padding: EdgeInsets.only(bottom: 12.w),
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