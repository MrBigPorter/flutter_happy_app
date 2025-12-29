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
    // 1. 安全检查
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
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

        // 2. 性能优化：移除 shrinkWrap ListView，改用 Column 生成
        // 因为外层通常已经是 ScrollView，这样做性能最好且无冲突
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: List.generate(list!.length, (index) {
              final item = list![index];
              return Padding(
                padding: EdgeInsets.only(bottom: 8.h), // 替代 separatorBuilder
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

/// 垂直动画包装器 (复用之前的旗舰级逻辑)
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

    // Index 0 同步启动
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
      // 瀑布流：每项延迟 50ms
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
          bool isTopItem = widget.index < 3; // 大卡片一屏也就2-3个
          bool isFast = !isTopItem && (info.visibleFraction > 0.6 || info.visibleFraction == 1.0);
          _startAnimation(isFast: isFast);
        }
      },
      child: widget.child
          .animate(controller: _controller, autoPlay: false)
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuart), // 上浮效果
    );
  }
}

/// 商品卡片
class ProductCard extends StatelessWidget {
  final ProductListItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // 3. 交互优化：整个卡片可点击
    return GestureDetector(
      onTap: () => appRouter.push('/product/${item.treasureId}'),
      child: Container(
        // 给一个背景色防止图片加载前透视
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(8.r),
          // 可选：加个轻微的阴影提升立体感
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
              /// Image Layer
              CachedNetworkImage(
                imageUrl: item.treasureCoverImg!,
                width: 343.w,
                height: 288.w, // 这里的宽高比需要根据设计稿确认
                fit: BoxFit.cover,
                // 4. 内存优化：指定内存缓存大小，防止大图撑爆内存
                memCacheWidth: (343.w * 2).toInt(), // 2倍像素密度
                placeholder: (_, __) =>
                    Skeleton.react(width: 343.w, height: 288.w),
                errorWidget: (_, __, ___) =>
                    Skeleton.react(width: 343.w, height: 288.w),
              ),

              /// Info Layer
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
}

/// 商品信息卡片 (带毛玻璃效果)
class ProductInfoCard extends StatelessWidget {
  final ProductListItem item;
  const ProductInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(6.w),
      // 5. 视觉优化：毛玻璃效果 (Glassmorphism)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radiusXs),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 高斯模糊
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              // 颜色调淡一点，配合模糊效果更通透
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(context.radiusXs),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), // 1像素的微光边框
                  width: 0.5,
                )
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Title
                Text(
                  item.treasureName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withValues(alpha: 0.5),
                        )
                      ]
                  ),
                ),
                SizedBox(height: 15.h),

                /// Progress
                BubbleProgress(
                  value: item.buyQuantityRate,
                  showTipBg: false,
                  tipBuilder: (v) {
                    final txt = FormatHelper.parseRate(v);
                    return Text(
                      'common.sold.upperCase'.tr(namedArgs: {'number': '$txt%'}),
                      style: TextStyle(
                        fontSize: context.text2xs,
                        fontWeight: FontWeight.w600,
                        color: context.utilityBrand500,
                      ),
                    );
                  },
                ),
                SizedBox(height: 10.h),

                /// Bottom Area
                ProductInfoCardBottom(item: item)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductInfoCardBottom extends StatelessWidget {
  final ProductListItem item;
  const ProductInfoCardBottom({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'common.ticket.price'.tr(),
              style: TextStyle(
                fontSize: context.textXs,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '₱${item.costAmount}', // 建议使用 FormatHelper.formatCurrency
              style: TextStyle(
                fontSize: context.textXs,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Spacer(),

        // Countdown / Status
        // 6. 国际化优化：修复硬编码字符串
        RenderCountdown(
          lotteryTime: item.lotteryTime,
          renderSoldOut: () => _buildStatusText(
              context,
              'common.draw_once'.tr(),
              'common.sold'.tr(),
              isError: false
          ),
          renderEnd: (days) => _buildStatusText(
            context,
            'common.refile_end'.tr(),
            'common.days'.tr(namedArgs: {'days': days.toString()}),
            isError: true,
          ),
          renderCountdown: (time) => _buildStatusText(
            context,
            'common.countdown'.tr(),
            time,
            isError: true,
          ),
        ),
        const Spacer(),

        // Button
        // 因为外层 GestureDetector 已经处理了点击，这里的按钮只做视觉展示
        // 或者保留点击，视交互需求而定
        IgnorePointer(
          ignoring: true, // 让点击穿透到整个卡片
          child: Button(
            height: 36.w, // 稍微调小一点，显得精致
            child: Text('common.enter.now'.tr()),
            onPressed: () {},
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
          style: TextStyle(
            fontSize: context.textXs,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.textXs,
            fontWeight: FontWeight.w800,
            color: isError ? context.textErrorPrimary600 : Colors.white,
          ),
        ),
      ],
    );
  }
}