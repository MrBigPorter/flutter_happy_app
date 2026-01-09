import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// 首页未来可期 (商品列表)
class HomeFuture extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const HomeFuture({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimary900,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(list!.length, (index) {
              final item = list![index];
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: VerticalAnimatedItem(
                  uniqueKey: item.treasureId,
                  index: index,
                  child: ProductCard(item: item),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class VerticalAnimatedItem extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int index;

  const VerticalAnimatedItem({
    super.key,
    required this.child,
    required this.index,
    required this.uniqueKey,
  });

  @override
  State<VerticalAnimatedItem> createState() => _VerticalAnimatedItemState();
}

class _VerticalAnimatedItemState extends State<VerticalAnimatedItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    if (widget.index == 0) {
      _startAnimation(isFast: false, forceSync: true);
    }
  }

  void _startAnimation({required bool isFast, bool forceSync = false}) {
    if (_hasStarted) return;
    _hasStarted = true;
    if (isFast) {
      _controller.value = 1.0;
    } else {
      final delayMs = 50 * (widget.index % 5);
      if (delayMs == 0 || forceSync) {
        _controller.forward();
      } else {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key('future_item_${widget.uniqueKey}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (_hasStarted) return;
        if (info.visibleFraction > 0.01) {
          bool isTopItem = widget.index < 3;
          bool isFast = !isTopItem && (info.visibleFraction > 0.6 || info.visibleFraction == 1.0);
          _startAnimation(isFast: isFast);
        }
      },
      child: widget.child
          .animate(controller: _controller, autoPlay: false)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductListItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => appRouter.push('/product/${item.treasureId}'),
      child: Container(
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: item.treasureCoverImg!,
                width: 343.w,
                height: 288.w,
                fit: BoxFit.cover,
                memCacheWidth: (343.w * 2).toInt(),
                placeholder: (_, __) => Skeleton.react(width: 343.w, height: 288.w),
                errorWidget: (_, __, ___) => Skeleton.react(width: 343.w, height: 288.w),
              ),

              /// ✨ [新增] 左上角业务标签
              Positioned(
                top: 10.h,
                left: 10.w,
                child: Row(
                  children: [
                    if (item.groupSize != null && item.groupSize! > 1)
                      _buildTag(context, '${item.groupSize}P Group', Colors.orange),
                    if (item.shippingType == 2)
                      Padding(
                        padding: EdgeInsets.only(left: 4.w),
                        child: _buildTag(context, 'E-Voucher', Colors.blue),
                      ),
                  ],
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ProductInfoCard(item: item),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ProductInfoCard extends StatelessWidget {
  final ProductListItem item;
  const ProductInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radiusXs),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(context.radiusXs),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.treasureName??'',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black.withValues(alpha: 0.5))
                      ]
                  ),
                ),
                SizedBox(height: 15.h),
                BubbleProgress(
                  value: item.buyQuantityRate,
                  showTipBg: false,
                  tipBuilder: (v) {
                    final txt = FormatHelper.parseRate(v);
                    return Text(
                      'common.sold.upperCase'.tr(namedArgs: {'number': '$txt%'}),
                      style: TextStyle(fontSize: context.text2xs, fontWeight: FontWeight.w600, color: context.utilityBrand500),
                    );
                  },
                ),
                SizedBox(height: 10.h),
                ProductInfoCardBottom(item: item)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductInfoCardBottom extends StatefulWidget {
  final ProductListItem item;
  const ProductInfoCardBottom({super.key, required this.item});

  @override
  State<ProductInfoCardBottom> createState() => _ProductInfoCardBottomState();
}

class _ProductInfoCardBottomState extends State<ProductInfoCardBottom> {
  @override
  Widget build(BuildContext context) {
    // 每次 build 重新获取当前时间，用于计算业务状态
    final now = DateTime.now().millisecondsSinceEpoch;

    final salesStart = widget.item.salesStartAt ?? 0;
    final salesEnd = widget.item.salesEndAt ?? 0;

    // 状态判定逻辑
    final bool isSoldOut = widget.item.buyQuantityRate! >= 100;
    final bool isWaitingSale = salesStart > now;
    final bool isExpired = salesEnd != 0 && now >= salesEnd;

    return Row(
      children: [
        // --- 价格区 ---
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.ticket.price'.tr(),
              style: TextStyle(fontSize: context.textXs, color: Colors.white.withOpacity(0.8)),
            ),
            Text(
              '₱${widget.item.costAmount}',
              style: TextStyle(fontSize: context.textXs, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        const Spacer(),

        // --- 核心倒计时/End 逻辑区 ---
        if (isSoldOut)
          _buildStatusText(context, 'common.status'.tr(), 'common.sold_out'.tr())
        else if (isExpired)
          _buildStatusText(context, 'common.status'.tr(), 'common.activity_ended'.tr(), isError: true)
        else
          RenderCountdown(
            // 目标时间：预售中取开始时间，否则取结束时间
            lotteryTime: isWaitingSale ? salesStart : salesEnd,

            // ✨ 重点：倒计时归零时触发刷新，状态机重新计算
            onFinished: () {
              if (mounted) setState(() {});
            },

            renderCountdown: (time) => _buildStatusText(
              context,
              isWaitingSale ? 'common.starts_in'.tr() : 'common.countdown'.tr(),
              time,
            ),
            renderEnd: (days) => _buildStatusText(
              context,
              isWaitingSale ? 'common.pre_sale'.tr() : 'common.countdown'.tr(),
              'common.days_left'.tr(namedArgs: {'days': days}),
            ),
            renderSoldOut: () => _buildStatusText(
              context,
              'common.status'.tr(),
              'common.activity_ended'.tr(),
            ),
          ),
        const Spacer(),

        // --- 按钮区 ---
        IgnorePointer(
          ignoring: true,
          child: Button(
            height: 36.w,
            backgroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.buttonSecondaryBg : null,
            foregroundColor: (isWaitingSale || isSoldOut || isExpired) ? context.textPrimary900 : context.textWhite,
            child: Text(
              isWaitingSale
                  ? 'common.pre_sale'.tr()
                  : (isSoldOut ? 'common.sold_out'.tr() : 'common.join_group'.tr()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(BuildContext context, String label, String value, {bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white.withOpacity(0.7)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isError ? context.textErrorPrimary600 : Colors.white,
          ),
        ),
      ],
    );
  }
}