// 商品项组件，用于展示单个商品的卡片视图
// Product item component for displaying individual product card view
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/render_countdown.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/ui/enter_button.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
class ProductItem extends StatelessWidget {
  // 商品数据
  // Product data
  final ProductListItem data;

  // 卡片宽度
  // Card width
  final int? cardWidth;
  final int? imgWidth;
  final int? imgHeight;

  const ProductItem({
    super.key,
    required this.data,
    this.cardWidth = 157,
    this.imgWidth = 157,
    this.imgHeight = 157,
  });

  @override
  Widget build(BuildContext context) {
    // 获取购买比率
    // Get purchase rate
    final double rate = FormatHelper.parseRate(data.buyQuantityRate);

    /// 倒计时 Countdown

    return Container(
      key: ValueKey(data.treasureId),
      child: SizedBox(
        width: cardWidth!.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // 商品图片
                // Product image
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8.w),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: proxied(data.treasureCoverImg),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Skeleton.react(
                        width: double.infinity,
                        height: imgWidth!.w,
                      ),
                      errorWidget: (_, __, ___) => Skeleton.react(
                        width: double.infinity,
                        height: imgHeight!.w,
                      ),
                    ),
                  ),
                ),

                /// 倒计时 Countdown
                Positioned(
                  top: -10.w,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: RenderCountdown(
                      lotteryTime: data.lotteryTime,
                      renderSoldOut: () => SizedBox.shrink(),
                      renderEnd: (days) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 2.w,
                              ),
                              height: 22.w,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(
                                  context.radius2xl,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'reffle end ',
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    '$days days',
                                    style: TextStyle(
                                      fontSize: 12.w,
                                      fontWeight: FontWeight.w600,
                                      color: context.textErrorPrimary600,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      renderCountdown: (timeDilation) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15.w,
                              vertical: 2.w,
                            ),
                            alignment: Alignment.center,
                            height: 22.w,
                            decoration: BoxDecoration(
                              color: context.utilityError500,
                              borderRadius: BorderRadius.circular(
                                context.radius2xl,
                              ),
                            ),
                            child: Text(
                              timeDilation,
                              style: TextStyle(
                                fontSize: 12.w,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // 商品信息容器
            // Product info container
            Flexible(
              fit: FlexFit.loose,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12.w),
                decoration: BoxDecoration(
                  color: context.bgPrimary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8.w),
                  ),
                ),
                child: Column(
                  children: [
                    // 商品标题
                    // Product title
                    Container(
                      alignment: Alignment.center,
                      height: 40.w,
                      child: Text(
                        data.treasureName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.w,
                          height: context.leadingSm,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary900,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.w),

                    // 价格标签
                    // Price tag
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 22.w,
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.utilityBrand500,
                            borderRadius: BorderRadius.circular(4.w),
                          ),
                          child: Text(
                            FormatHelper.formatCurrency(
                              data.unitAmount,
                              symbol: "₱ ",
                            ),
                            style: TextStyle(
                              fontSize:10.w,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              color: context.textPrimaryOnBrand,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.w),

                    // 销售进度条
                    // Sales progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// 进度条 Progress bar
                        BubbleProgress(
                          value: rate,
                          showTip: true,
                          showTipBg: false,
                          color: context.utilityBrand500,
                          trackHeight: 4,
                          thumbSize: 8,
                          tipBuilder: (v) {
                            final txt = v
                                .toStringAsFixed(2)
                                .replaceFirst(RegExp(r'\.00$'), '');
                            return RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "$txt%",
                                    style: TextStyle(
                                      fontSize: 10.w,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary900,
                                      height: 1.4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " Sold",
                                    style: TextStyle(
                                      fontSize: 10.w,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary900,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        ///  倒计时 Countdown
                        RenderCountdown(
                          lotteryTime: data.lotteryTime,
                          renderSoldOut: () => Text(
                            'Draw once sold out',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10.w,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary900,
                            ),
                          ),
                          renderEnd: (days) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'reffle end',
                                style: TextStyle(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary900,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '$days days',
                                style: TextStyle(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w800,
                                  color: context.textErrorPrimary600,
                                ),
                              ),
                            ],
                          ),
                          renderCountdown: (time) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Countdown',
                                style: TextStyle(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary900,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10.w,
                                  fontWeight: FontWeight.w800,
                                  color: context.textErrorPrimary600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 底部间距 Bottom spacing
                        SizedBox(height: 8.w),
                        EnterButton(
                          child: Text('common.enter.now'.tr()),
                          onPressed: () {
                            /// 进入商品详情 Enter product details
                            AppRouter.router.push(
                              '/product/${data.treasureId}',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
