import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/page/order_components/zoom_scroll_view.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/components/swiper_banner.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/index.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/modal/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/providers/order_provider.dart';

/// 订单详情页：
/// - 顶部 Header 固定 + 渐入
/// - Banner 跟随滚动渐隐
/// - 内容可滚
/// - 底部按钮固定（上滑时贴底，下拉整卡片时一起动）
class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  final List<String> imageList;
  final VoidCallback onClose; // 从当前卡片缩回的关闭动画

  static const double _bannerHeight = 356.0;

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

    // header 渐入 / banner 渐隐的滚动范围
    final double fadeStart = 0;
    final double fadeEnd = 140.w;

    double t;
    if (_scrollOffset <= fadeStart) {
      t = 0;
    } else if (_scrollOffset >= fadeEnd) {
      t = 1;
    } else {
      t = ((_scrollOffset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
    }

    final eased = Curves.easeOut.transform(t);
    final double headerOpacity = eased; // header 0 → 1
    final double bannerOpacity = 1.0 - eased * .9; // banner 1 → 0.1

    final double bottomBarHeight = 80.w; // 底部按钮高度

    return orderDetailAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (orderDetail) {
        return Container(
          decoration: BoxDecoration(
            color: context.bgPrimary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // 整个内容区域（含可滚内容 + 固定底部 + 顶部 Header）
              Expanded(
                child: Stack(
                  children: [
                    /// ① 背后是可滚区域 + 底部按钮（都在 ZoomScrollView 里）
                    ZoomScrollView(
                      onDismiss: widget.onClose,
                      onScrollOffsetChanged: (offset) {
                        setState(() {
                          _scrollOffset = offset;
                        });
                      },
                      bottomBar: OrderDetailBottom(
                        treasureId: orderDetail.treasureId,
                        height: bottomBarHeight,
                      ),
                      bodyBuilder: (context, scrollController, scrollOffset) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OrderDetailBannerSection(
                              imageList: widget.imageList,
                              height: OrderDetailPage._bannerHeight,
                              onClose: widget.onClose,
                              opacity: bannerOpacity,
                            ),
                            _OrderDetailBody(orderDetail: orderDetail),
                            // 给一点垫底空间，避免内容顶在 bottomBar 上
                            SizedBox(height: bottomBarHeight + 16.w),
                          ],
                        );
                      },
                    ),

                    /// ② 顶部固定 Header（不跟内容一起滚，只根据 scrollOffset 渐入）
                    OrderDetailToHeader(
                      opacity: headerOpacity,
                      title: orderDetail.treasure.treasureName,
                      onClose: widget.onClose,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 顶部随滚动慢慢出现的 Header（标题 + 返回 + 分享）
class OrderDetailToHeader extends StatelessWidget {
  final double opacity;
  final String title;
  final VoidCallback onClose;

  const OrderDetailToHeader({
    super.key,
    required this.opacity,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    const double toolbarHeight = kToolbarHeight;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: opacity,
      child: Container(
        height: padding.top + toolbarHeight,
        padding: EdgeInsets.only(
          top: padding.top,
          left: 16.w,
          right: 16.w,
        ),
        decoration: BoxDecoration(
          color: context.bgPrimary,
          boxShadow: opacity > 0.95
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.arrow_back,
                size: 22.w,
                color: context.textPrimary900,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.textMd,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary900,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.ios_share,
                size: 20.w,
                color: context.textSecondary700,
              ),
              onPressed: () {
                // TODO: 接分享
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 订单详情 Body（商品信息 + 金额信息）
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

        // 为了拉高内容，你之前多写了一遍，我也先保留
        _ProductSection(orderDetail: orderDetail),
        _OrderInfoSection(orderDetail: orderDetail),
      ],
    );
  }
}

/// 顶部 Banner Swiper + 分享逻辑
class OrderDetailBannerSection extends ConsumerStatefulWidget {
  final List<String> imageList;
  final double height;
  final VoidCallback onClose;
  final double opacity; // 根据滚动变化

  const OrderDetailBannerSection({
    super.key,
    required this.imageList,
    required this.height,
    required this.onClose,
    required this.opacity,
  });

  @override
  ConsumerState<OrderDetailBannerSection> createState() =>
      BannerSectionState();
}

class BannerSectionState extends ConsumerState<OrderDetailBannerSection> {
  final sharePosterKey = GlobalKey<SharePostState>();
  int currentIndex = 0;

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
              key: sharePosterKey,
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
    // 用 opacity 做一点上移，模拟被内容「推上去」
    final double translateY = 12.w * (1 - widget.opacity);

    return Transform.translate(
      offset: Offset(0, -translateY),
      child: Opacity(
        opacity: widget.opacity.clamp(0.0, 1.0),
        child: SwiperBanner(
          banners: widget.imageList,
          height: widget.height,
          showIndicator: false,
          borderRadius: 0,
          onIndexChanged: (index) {
            if (mounted && index != currentIndex) {
              setState(() {
                currentIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}

/// 商品信息区域
class _ProductSection extends StatelessWidget {
  final OrderDetailItem orderDetail;

  const _ProductSection({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          SizedBox(height: 12.w),
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

/// 订单明细区域
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
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'common.tickets.number'.tr(),
            value: ' ${orderDetail.buyQuantity} ',
          ),
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'common.total.price'.tr(),
            value: orderDetail.originalAmount,
          ),
          SizedBox(height: 12.w),
          Divider(color: context.borderSecondary, thickness: 1),
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'order.detail.treasure.coupon'.tr(),
            value: '- ${orderDetail.coinAmount} ',
          ),
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'common.total.payment'.tr(),
            value: orderDetail.finalAmount,
          ),
          SizedBox(height: 12.w),
          Divider(color: context.borderSecondary, thickness: 1),
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'order-id'.tr(),
            value: orderDetail.orderNo,
          ),
          SizedBox(height: 12.w),
          _OrderInfoRow(
            title: 'payment-time'.tr(),
            value: DateFormatHelper.formatFull(
              DateTime.fromMillisecondsSinceEpoch(
                orderDetail.createdAt!.toInt(),
              ),
            ),
          ),
          SizedBox(height: 12.w),
          Divider(color: context.borderSecondary, thickness: 1),
          SizedBox(height: 12.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: orderDetail.transactions.map((item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderInfoRow(
                    title: 'transactionNo',
                    value: item.transactionNo,
                  ),
                  SizedBox(height: 12.w),
                  _OrderInfoRow(title: 'amount', value: item.amount),
                  SizedBox(height: 12.w),
                  _OrderInfoRow(
                    title: 'payment method',
                    value: '${item.balanceType}',
                  ),
                  SizedBox(height: 12.w),
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

/// 行展示组件（左标题 + 右侧 value / 自定义 trailing）
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

/// 底部固定按钮栏：查看商品 / 拼团
class OrderDetailBottom extends StatelessWidget {
  final String treasureId;
  final double height;

  const OrderDetailBottom({
    super.key,
    required this.treasureId,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.w),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        boxShadow: [
          BoxShadow(
            color: context.fgPrimary900.withValues(alpha: .1),
            blurRadius: 10.w,
            offset: Offset(0, -2.w),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Button(
            width: 150.w,
            onPressed: () {
              appRouter.push(
                '/product/$treasureId',
              );
            },
            child: Text('common.view.friends'.tr()),
          ),
        ],
      ),
    );
  }
}