import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
/// 首页未来可期 (商品列表) Home Future (list of products)
class HomeFuture extends StatelessWidget {
  final List<ProductListItem>? list;

  const HomeFuture({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'common.featured'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ),
        ),
        // list of products
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = list![index];
              return ProductCard(item: item);
            },
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemCount: list!.length,
          ),
        ),
      ],
    );
  }
}

/// 商品卡片 product card (图片 + 信息卡片) (image + info card)
class ProductCard extends StatelessWidget {
  final ProductListItem item;
  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.all(Radius.circular(8.r)),
      ),
      child: Stack(
        children: [
          /// image
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8.r)),
            child: CachedNetworkImage(
              imageUrl: item.treasureCoverImg,
              width: 343.w,
              height: 288.w,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Skeleton.react(width: 343.w, height: 343.w),
              errorWidget: (_, __, ___) =>
                  Skeleton.react(width: 343.w, height: 343.w),
            ),
          ),
          /// info card: title, progress, price, countdown, button
          ProductInfoCard(item: item)
        ],
      ),
    );
  }
}

/// 商品信息卡片 (标题 进度条 价格 倒计时 按钮) product info card (title, progress bar, price, countdown, button)
class ProductInfoCard extends StatelessWidget {
  final ProductListItem item;
  const ProductInfoCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
          vertical: 6.w,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 8.w,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 70),
            borderRadius: BorderRadius.all(
              Radius.circular(context.radiusXs),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// title
              Text(
                item.treasureName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.textSm,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 15.h),

              /// 进度条 bubble and progress
              BubbleProgress(
                value: item.buyQuantityRate,
                showTipBg: false,
                tipBuilder: (v) {
                  final txt = FormatHelper.parseRate(v);
                  return Text(
                    'common.sold.upperCase'.tr(
                      namedArgs: {'number': '$txt%'},
                    ),
                    style: TextStyle(
                      fontSize: context.text2xs,
                      fontWeight: FontWeight.w600,
                      color: context.utilityBrand500,
                    ),
                  );
                },
              ),
              SizedBox(height: 10.h),
              /// price countdown button
              ProductInfoCardBottom(item: item)
            ],
          ),
        ),
      ),
    );
  }
}

/// 商品信息卡片底部 (价格 倒计时 按钮) product info card bottom (price, countdown, button)
class ProductInfoCardBottom extends StatelessWidget {
  final ProductListItem item;
  const ProductInfoCardBottom({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return
      /// price countdown button
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'common.ticket.price'.tr(),
                style: TextStyle(
                  fontSize: context.textXs,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(
                    alpha: 80,
                  ),
                ),
              ),
              Text(
                ' ₱${item.costAmount}',
                style: TextStyle(
                  fontSize: context.textXs,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Spacer(),
          RenderCountdown(
            lotteryTime: item.lotteryTime,
            renderSoldOut: () => Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Draw once',
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(
                      alpha: 80,
                    ),
                  ),
                ),
                Text(
                  'sold out',
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            renderEnd: (days) => Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'refile end',
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(
                      alpha: 80,
                    ),
                  ),
                ),
                Text(
                  '$days days',
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                    color: context.textErrorPrimary600,
                  ),
                ),
              ],
            ),
            renderCountdown: (time) => Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Countdown',
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(
                      alpha: 80,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: context.textXs,
                    fontWeight: FontWeight.w800,
                    color: context.textErrorPrimary600,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Button(
            child: Text('common.enter.now'.tr()),
            onPressed: ()=>{
              AppRouter.router.push('/product/${item.treasureId}')
            },
          ),
        ],
      );
  }
}
