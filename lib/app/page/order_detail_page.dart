import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; // 务必引入 flutter_animate
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// --- 项目内部引用 (根据你的实际路径调整) ---
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/share_sheet.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/core/providers/order_provider.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/features/share/services/share_service.dart';
import 'package:flutter_app/features/share/widgets/share_post.dart';
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
  @override
  Widget build(BuildContext context) {
    final orderDetailAsyncValue = ref.watch(orderDetailProvider(widget.orderId));
    final double bottomBarHeight = 80.w;

    return orderDetailAsyncValue.when(
      // 1. Loading 状态：使用修复后的骨架屏
      loading: () => Scaffold(
        backgroundColor: context.bgPrimary,
        body: const OrderDetailSkeleton(),
      ),
      // 2. Error 状态
      error: (e, s) => Scaffold(
        backgroundColor: context.bgPrimary,
        body: Center(child: Text("Error loading order details")),
      ),
      // 3. Data 状态：显示完整页面
      data: (orderDetail) {
        return DraggableScrollableScaffold(
          heroTag: 'order_card_${widget.orderId}',
          onDismiss: widget.onClose,

          // 底部固定按钮栏
          bottomBar: _buildBottomBar(
            context,
            orderDetail.group?.groupId ?? '',
            bottomBarHeight,
          ),

          // 顶部悬浮渐变 Header
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
            return SingleChildScrollView(
              controller: scrollController,
              physics: physics,
              padding: EdgeInsets.zero,
              child: Material(
                color: context.bgPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // A. 顶部 Banner (带视差效果)
                    AnimatedBuilder(
                      animation: scrollController,
                      builder: (context, child) {
                        double offset = 0;
                        if (scrollController.hasClients) {
                          offset = scrollController.offset;
                        }
                        // 向下拉动时放大图片 (Parallax Effect)
                        double scale = 1.0;
                        if (offset < 0) {
                          scale = 1.0 + (offset.abs() / 356.w) * 0.5;
                        }

                        return Transform.scale(
                          scale: scale,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: 356.h,
                            child: SwiperBanner(
                              banners: widget.imageList,
                              height: 356.w,
                              showIndicator: true,
                              borderRadius: 0,
                              physics: physics,
                            ),
                          ),
                        );
                      },
                    ),

                    // B. 详情内容卡片 (向上平移，盖住一点 Banner)
                    Transform.translate(
                      offset: Offset(0, -24.w),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.bgPrimary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24.w),
                            topRight: Radius.circular(24.w),
                          ),
                          // 顶部阴影，增加层次感
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            )
                          ],
                        ),
                        // 底部留白给 BottomBar
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

  // 构建底部按钮栏
  Widget _buildBottomBar(BuildContext context, String groupId, double height) {
    return Container(
      height: height + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        top: 10.w,
        bottom: MediaQuery.of(context).padding.bottom + 10.w,
      ),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          top: BorderSide(
            color: context.fgPrimary900.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Center(
        child: Button(
          width: 200.w,
          height: 44.w,
          onPressed: () {
            appRouter.push('/product/$groupId/group');
          },
          trailing: Icon(Icons.group_outlined, size: 18.w, color: Colors.white),
          child: Text('common.view.friends'.tr()),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------
/// 动态渐变 Header (仿 Airbnb)
/// ---------------------------------------------------------
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

    final webBaseUrl = ref.read(
      luckyProvider.select((state) => state.sysConfig.webBaseUrl),
    );

    return AnimatedBuilder(
      animation: widget.scrollController,
      builder: (context, child) {
        double offset = 0;
        if (widget.scrollController.hasClients) {
          offset = widget.scrollController.offset;
        }

        // 计算透明度：滚动 120px 变全白
        double opacity = (offset / 120.0).clamp(0.0, 1.0);
        final double iconBgOpacity = 1.0 - opacity;

        return Container(
          height: paddingTop + height,
          padding: EdgeInsets.only(top: paddingTop, right: 16.w),
          decoration: BoxDecoration(
            color: context.bgPrimary.withValues(alpha: opacity),
            border: Border(
              bottom: BorderSide(
                color: context.fgSecondary700.withValues(alpha: 0.1 * opacity),
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
                  backgroundColor:
                  context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: context.fgSecondary700),
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
                  backgroundColor:
                  context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, color: context.fgSecondary700),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      openShareSheet(
                        context,
                        ShareData(
                          title: widget.title,
                          url: '$webBaseUrl/${widget.imageList.first}',
                          text: 'Check out this lucky item!',
                          imageUrl: widget.imageList.first,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor:
                  context.bgPrimary.withValues(alpha: 0.8 * iconBgOpacity),
                  child: IconButton(
                    icon: Icon(Icons.favorite_border, color: context.fgSecondary700),
                    constraints: const BoxConstraints(),
                    onPressed: null,
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

/// ---------------------------------------------------------
/// 详情页主体内容
/// ---------------------------------------------------------
class _OrderDetailBody extends StatelessWidget {
  final OrderDetailItem orderDetail;

  const _OrderDetailBody({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 商品信息先入场
        _ProductSection(orderDetail: orderDetail)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

        Divider(color: context.borderSecondary, thickness: 8.w),

        // 2. 订单明细延迟入场 (错落感)
        _OrderInfoSection(orderDetail: orderDetail)
            .animate(delay: 100.ms) // 延迟 100ms
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
      ],
    );
  }
}

class _OrderInfoSection extends StatelessWidget {
  final OrderDetailItem orderDetail;
  const _OrderInfoSection({required this.orderDetail});

  // 辅助方法：格式化支付方式
  String _formatPaymentMethod(dynamic type) {
    // 这里可以根据后端定义的 type (int/string) 返回可读文案
    // 比如 1 -> Wallet, 2 -> GCash
    return type.toString().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 16.w),

          _OrderInfoRow(
            title: 'common.ticket.price'.tr(),
            value: orderDetail.unitPrice,
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'common.tickets.number'.tr(),
            value: 'x${orderDetail.buyQuantity}',
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'common.total.price'.tr(),
            value: orderDetail.originalAmount,
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(
            title: 'order.detail.treasure.coupon'.tr(),
            value: '- ${orderDetail.coinAmount}',
            valueColor: context.utilityError500, // 高亮显示优惠
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.w),
            child: Divider(color: context.borderSecondary, thickness: 1),
          ),

          // 总价高亮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'common.total.payment'.tr(),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary900,
                ),
              ),
              Text(
                orderDetail.finalAmount,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary900,
                ),
              ),
            ],
          ),

          SizedBox(height: 24.w),
          Text(
            'Order Details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: context.textPrimary900,
            ),
          ),
          SizedBox(height: 16.w),

          // 订单号 (可复制)
          _OrderInfoRow(
            title: 'order-id'.tr(),
            value: orderDetail.orderNo,
            isCopyable: true,
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

          // 交易流水区域优化
          if (orderDetail.transactions.isNotEmpty) ...[
            SizedBox(height: 20.w),
            Container(
              padding: EdgeInsets.all(16.w), // 增加内边距
              decoration: BoxDecoration(
                color: context.bgSecondary.withValues(alpha: 0.3), // 更淡的背景
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: context.borderSecondary, width: 0.5), // 加个细边框
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 加个小标题
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.w),
                    child: Text(
                      "Transaction History",
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary700
                      ),
                    ),
                  ),
                  ...orderDetail.transactions.map((item) {
                    return Column(
                      children: [
                        _OrderInfoRow(
                          title: 'Transaction No.',
                          value: item.transactionNo,
                          isSmall: true,
                          isCopyable: true,
                        ),
                        const SizedBox(height: 8),
                        _OrderInfoRow(
                          title: 'Payment Method',
                          // ✅ 修复：动态显示支付方式
                          value: _formatPaymentMethod(item.balanceType),
                          isSmall: true,
                        ),
                        if (item != orderDetail.transactions.last)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.w),
                            child: Divider(
                                color: context.borderSecondary.withValues(alpha: 0.5),
                                thickness: 0.5
                            ),
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

class _ProductSection extends StatelessWidget {
  final OrderItem orderDetail;
  const _ProductSection({required this.orderDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            orderDetail.treasure.treasureName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20.sp, // 标题加大
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // 销量胶囊
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
            decoration: BoxDecoration(
              color: context.bgSecondary,
              borderRadius: BorderRadius.circular(4.w),
            ),
            child: Text(
              '${orderDetail.buyQuantity}/${orderDetail.treasure.seqShelvesQuantity} ${'common.sold.lowercase'.tr()}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.textSecondary700,
                fontWeight: FontWeight.w500,
              ),
            ),
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

  const _OrderInfoRow({
    required this.title,
    required this.value,
    this.valueColor,
    this.isCopyable = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget valueWidget = Text(
      value,
      style: TextStyle(
        fontSize: isSmall ? 12.sp : 14.sp,
        color: valueColor ??
            (isSmall ? context.textSecondary700 : context.textPrimary900),
        fontWeight: isSmall ? FontWeight.w500 : FontWeight.w600,
        fontFamily: isCopyable ? 'Monospace' : null, // 复制内容用等宽字体
      ),
    );

    // 如果可复制，包裹手势检测
    if (isCopyable) {
      valueWidget = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          HapticFeedback.lightImpact(); // 震动反馈
          RadixToast.success(value);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            valueWidget,
            SizedBox(width: 6.w),
            Icon(Icons.copy, size: 12.w, color: context.textTertiary600),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isSmall ? 12.sp : 14.sp,
            color: context.textSecondary700,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (!isCopyable) Expanded(child: SizedBox()),
        // 防止文字过长溢出
        Flexible(child: valueWidget),
      ],
    );
  }
}

/// ---------------------------------------------------------
/// 修复后的骨架屏 (解决小屏溢出问题)
/// ---------------------------------------------------------
class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    // 关键修复：使用 Column + Expanded(SingleChildScrollView)
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
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

        // 底部固定占位
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