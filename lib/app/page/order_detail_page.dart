import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/models/index.dart'; 
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/features/share/services/share_service.dart';
import 'package:flutter_app/features/share/widgets/share_post.dart';
import 'package:flutter_app/ui/modal/sheet/radix_sheet.dart';
import 'package:flutter_app/utils/date_helper.dart';

import 'package:flutter_app/components/swiper_banner.dart';


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
  double _scrollOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final orderDetailAsyncValue = ref.watch(orderDetailProvider(widget.orderId));
    final double bottomBarHeight = 80.w;

    return orderDetailAsyncValue.when(
      loading: () =>  Scaffold(
        backgroundColor:context.bgPrimary,
        body: Center(child: OrderDetailSkeleton()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor:context.bgPrimary,
        body: Center(child: OrderDetailSkeleton()),
      ),
      data: (orderDetail) {
        return DraggableScrollableScaffold(
          heroTag: 'order_card_${widget.orderId}',
          onDismiss: widget.onClose,

          // 底部按钮栏
          bottomBar: _buildBottomBar(context, orderDetail.group?.groupId ?? '', bottomBarHeight),

          // 悬浮 Header (重点！)
          // 传入当前的 scrollOffset 以便内部计算透明度和颜色
          headerBuilder: (context, dragProgress, scrollController) {
            return AnimatedHeader(
              scrollController: scrollController,
              title: orderDetail.treasure.treasureName,
              imageList: widget.imageList,
              onClose: widget.onClose,
            );
          },

          // 页面主体内容
          bodyBuilder: (context, scrollController, physics) {
            final scrollOffset = scrollController.hasClients ? scrollController.offset : 0.0;
            final opacity = 1.0 - ( scrollOffset / 356.w).clamp(0.0, 1.0);
            return SingleChildScrollView(
              controller: scrollController,
              physics: physics,
              padding: EdgeInsets.zero, // 顶部不要留白，Banner 要顶头
              child: Material(
                color: context.bgPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Banner 区域
                   AnimatedBuilder(
                       animation: scrollController,
                       builder: (context, child) {
                         double offset = 0;
                         if(scrollController.hasClients){
                           offset = scrollController.offset;
                         }
                         final double opacity = 1.0 - ( offset / 356.w).clamp(0.0, 1.0);
                         return  SizedBox(
                           height: 356.w,
                           child: Opacity(
                             opacity: opacity,
                             child: SwiperBanner(
                               banners: widget.imageList,
                               height: 356.w,
                               showIndicator: false,
                               borderRadius: 0,
                               physics: physics,
                             ),
                           ),
                         );
                       },
                   ),
                    // 详情内容
                    Transform.translate(
                      offset: Offset(0, -32.w),
                      child:  Container(
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32.w),
                            topRight: Radius.circular(32.w),
                          ),
                        ),
                        child:  _OrderDetailBody(orderDetail: orderDetail),
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

  Widget _buildBottomBar(BuildContext context, String groupId, double height) {
    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(top: BorderSide(color: context.fgPrimary900.withValues(alpha: 0.1), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Button(
            width: 150.w,
            onPressed: () {
              appRouter
                  .push('/product/$groupId/group');
            },
            child: Text('common.view.friends'.tr()),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------
/// Airbnb 风格的动态 Header
/// ---------------------------------------------------------
///

class AnimatedHeader extends ConsumerStatefulWidget {
  final  ScrollController scrollController;
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

  void openShareSheet(BuildContext context, ShareData data) {
    final webBaseUrl = ref.read(
      luckyProvider.select((state) => state.sysConfig.webBaseUrl),
    );

    ShareService.openSystemOrSheet(
      data,
          () async {
        RadixSheet.show(
          headerBuilder: (context) => Padding(
            padding: EdgeInsets.only(bottom: 20.w),
            child: SharePost(
              data: ShareData(
                title: data.title,
                url: data.url,
                text: data.text,
                imageUrl: data.imageUrl,
              ),
            ),
          ),
          builder: (context, close) {
            return ShareSheet(
              showDownButton: true,
              data: ShareData(
                title: data.title,
                url: '$webBaseUrl/${widget.imageList.first}',
                text: data.text,
                imageUrl: widget.imageList.first,
              ),
              onDownloadPoster: () async {
                sharePosterKey.currentState?.saveToGallery();
                HapticFeedback.mediumImpact();
                close();
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paddingTop = MediaQuery.of(context).padding.top;
    const height = kToolbarHeight;

    final scrollOffset = widget.scrollController.offset;
    final webBaseUrl = ref.read(
      luckyProvider.select((state) => state.sysConfig.webBaseUrl),
    );


    return AnimatedBuilder(
        animation: widget.scrollController,
        builder: (context, child){

          double offset = 0;
          if(widget.scrollController.hasClients){
            offset = widget.scrollController.offset;
          }

          double opacity = (offset / 120.0).clamp(0.0, 1.0);
          final double iconBgOpacity = 1.0 - opacity;

          // 阴影：只有在白色图标时(顶部)才需要阴影，变黑后阴影消失
          final List<Shadow>? iconShadow = opacity < 0.5
              ? [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))]
              : null;

          // 颜色插值：从白色变为黑色
          // 0.0 (顶部) -> 白色
          // 1.0 (滚动后) -> 黑色
          final Color iconColor = Color.lerp(context.bgPrimary, context.fgPrimary900, opacity)!;


          return Container(
            height: paddingTop + height,
            padding: EdgeInsets.only(top: paddingTop, right: 16.w),
            decoration: BoxDecoration(
              color: context.bgPrimary.withValues(alpha: opacity), // 背景逐渐变白
              border: Border(
                bottom: BorderSide(
                  color: context.fgSecondary700.withValues(alpha: 0.1 * opacity), // 分割线也渐显
                  width: 1,
                ),
              ),
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
                      icon:  Icon(Icons.arrow_back, color: context.fgSecondary700),
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                    child: IconButton(
                      icon:  Icon(Icons.share_outlined, color: context.fgSecondary700),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        openShareSheet(
                          context,
                          ShareData(
                            title: widget.title,
                            url: '$webBaseUrl/${widget.imageList.first}',
                            text:
                            'Amazing product I just ordered. Highly recommend it!',
                            imageUrl: widget.imageList.first,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor:context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                    child: IconButton(
                      icon: Icon(
                          Icons.favorite_border,
                          color: context.fgSecondary700
                      ),
                      constraints: BoxConstraints(),
                      onPressed: null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
}

/// ---------------------------------------------------------
/// 商品内容展示组件 (保持不变或微调)
/// ---------------------------------------------------------
class _OrderDetailBody extends StatelessWidget {
  final OrderDetailItem orderDetail;

  const _OrderDetailBody({
    super.key,
    required this.orderDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSection(orderDetail: orderDetail),
        _OrderInfoSection(orderDetail: orderDetail),
      ],
    );
  }
}

class _ProductSection extends StatelessWidget {
  final OrderItem orderDetail;
  const _ProductSection({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Text(
            orderDetail.treasure.treasureName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: context.textLg,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${orderDetail.buyQuantity}/${orderDetail.treasure.seqShelvesQuantity} ${'common.sold.lowercase'.tr()}',
            style: TextStyle(
              fontSize: context.textSm,
              color: context.textSecondary700,
            ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          _OrderInfoRow(
            title: 'common.ticket.price'.tr(),
            value: orderDetail.unitPrice,
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'common.tickets.number'.tr(),
            value: ' ${orderDetail.buyQuantity} ',
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'common.total.price'.tr(),
            value: orderDetail.originalAmount,
          ),
          const SizedBox(height: 12),
          Divider(color: context.borderSecondary, thickness: 1),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'order.detail.treasure.coupon'.tr(),
            value: '- ${orderDetail.coinAmount} ',
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'common.total.payment'.tr(),
            value: orderDetail.finalAmount,
          ),
          const SizedBox(height: 12),
          Divider(color: context.borderSecondary, thickness: 1),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'order-id'.tr(),
            value: orderDetail.orderNo,
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'payment-time'.tr(),
            value: DateFormatHelper.formatFull(
              DateTime.fromMillisecondsSinceEpoch(
                orderDetail.createdAt!.toInt(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: context.borderSecondary, thickness: 1),
          const SizedBox(height: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: orderDetail.transactions.map((item) {
              return Column(
                children: [
                  _OrderInfoRow(
                    title: 'transactionNo',
                    value: item.transactionNo,
                  ),
                  const SizedBox(height: 12),
                  _OrderInfoRow(title: 'amount', value: item.amount),
                  const SizedBox(height: 12),
                  _OrderInfoRow(
                    title: 'payment method',
                    value: '${item.balanceType}',
                  ),
                  const SizedBox(height: 12),
                  Divider(color: context.borderSecondary, thickness: 1),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Widget? trailing;

  const _OrderInfoRow({
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.textSm,
            color: context.textPrimary900,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          trailing!
        else
          Text(
            value,
            style: TextStyle(
              fontSize: context.textSm,
              color: context.textSecondary700,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}


/// ---------------------------------------------------------
/// 订单详情加载占位骨架屏 - Skeleton
/// ---------------------------------------------------------
class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner 占位
        Skeleton.react(width: double.infinity, height: 356.w),

        // 详情内容占位
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
                children: List.generate(8, (index) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Skeleton.react(width: 100.w, height: 16.w),
                          Spacer(),
                          Skeleton.react(width: 80.w, height: 16.w),
                        ],
                      ),
                      SizedBox(height: 12.w),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          height: 80.w,
          decoration: BoxDecoration(
            color: context.bgPrimary,
            border: Border(top: BorderSide(color: context.fgPrimary900.withValues(alpha: 0.1), width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Skeleton.react(
                  width: 150.w,
                  height: 40.w
              )
            ],
          ),
        )
      ],
    );
  }
}