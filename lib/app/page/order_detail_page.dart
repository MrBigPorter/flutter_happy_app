import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  final List<String> imageList;
  final double scrollOffset;   // 👈 外层 ZoomableEdgeScrollView 传进来的
  final VoidCallback onClose;  // 👈 让卡片按“从当前 item 缩回去”的动画关闭

  static const double _bannerHeight = 356.0;
  static const double _bottomBarHeight = 80.0;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.imageList,
    required this.onClose,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDetailAsyncValue = ref.watch(orderDetailProvider(orderId));

    // 👉 先用一个“很容易触发”的范围测试手感：
    // 0 开始淡，滚到 140 左右就全显
    final double fadeStart = 0;
    final double fadeEnd = 140.w; // 用 w，跟你的布局单位一致

    double t;
    if (scrollOffset <= fadeStart) {
      t = 0;
    } else if (scrollOffset >= fadeEnd) {
      t = 1;
    } else {
      t = ((scrollOffset - fadeStart) / (fadeEnd - fadeStart))
          .clamp(0.0, 1.0);
    }

    // 做一点曲线，让出现更柔和
    final eased = Curves.easeOut.transform(t);

    // header 从 0 → 1
    final double headerOpacity = eased;
    // banner 从 1 → 0（稍微保留一点点）
    final double bannerOpacity = 1.0 - eased * 0.9;

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
          child: _OrderDetailBody(
            orderDetail: orderDetail,
            bottomBarHeight: _bottomBarHeight,
          ),
        );
      },
    );
  }
}

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
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ↓↓↓ 下面这几个类我们只把类型 & 关闭回调调一下，其余保持你原来的实现风格 ↓↓↓

class _OrderDetailBody extends StatelessWidget {
  final OrderDetailItem orderDetail;
  final double bottomBarHeight;

  const _OrderDetailBody({
    super.key,
    required this.orderDetail,
    required this.bottomBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProductSection(orderDetail: orderDetail),
        _OrderInfoSection(orderDetail: orderDetail),
        // 这里你是为了撑高度测试多写了一次，我先保留
        _ProductSection(orderDetail: orderDetail),
        _OrderInfoSection(orderDetail: orderDetail),
      ],
    );
  }
}
class OrderDetailBannerSection extends ConsumerStatefulWidget {
  final List<String> imageList;
  final double height;
  final VoidCallback onClose;
  final double opacity; // 👈 新增

  const OrderDetailBannerSection({
    super.key,
    required this.imageList,
    required this.height,
    required this.onClose,
    required this.opacity,
  });

  @override
  ConsumerState<OrderDetailBannerSection> createState() => BannerSectionState();
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
    final webBaseUrl = ref.read(
      luckyProvider.select((state) => state.sysConfig.webBaseUrl),
    );

    // 用 opacity 做一点轻微上移，模拟被内容「推上去」的感觉
    final double translateY = 12.w * (1 - widget.opacity);

    return Transform.translate(
      offset: Offset(0, -translateY),
      child: Opacity(
        opacity: widget.opacity.clamp(0.0, 1.0),
        child: Stack(
          children: [
            Positioned.fill(
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
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      constraints: const BoxConstraints(),
                      onPressed: widget.onClose,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.black38,
                        child: IconButton(
                          icon: const Icon(Icons.share, color: Colors.white),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            openShareSheet(
                              context,
                              ShareData(
                                title: 'wwwww',
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
                      const CircleAvatar(
                        backgroundColor: Colors.black38,
                        child: IconButton(
                          icon: Icon(Icons.favorite_border, color: Colors.white),
                          constraints: BoxConstraints(),
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 55.w,
              right: 16.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.w),
                decoration: BoxDecoration(
                  color: context.fgPrimary900.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(8.w),
                ),
                child: Text(
                  '${currentIndex + 1}/${widget.imageList.length}',
                  style: TextStyle(
                    color: context.textWhite,
                    fontSize: context.textSm,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  final OrderDetailItem orderDetail;
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

class OrderDetailBottom extends StatelessWidget {

  final String treasureId;

  const OrderDetailBottom({
    super.key,
    required this.treasureId,
  });


  @override
  Widget build(BuildContext context) {

    return Container(
      height: 80.w,
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