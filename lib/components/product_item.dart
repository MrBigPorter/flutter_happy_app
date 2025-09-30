import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/bubble_progress.dart';
import 'package:flutter_app/utils/format_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int width = 157;
  const ProductItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final double rate = FormatHelper.parseRate(data.buyQuantityRate);
    print('===>$rate');
    return GestureDetector(
      onTap: (){
        // Navigator.pushNamed(context, '/productDetail', arguments: data.id);
      },
      child: Container(
        width: width.w,
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                      child: CachedNetworkImage(
                        imageUrl: proxied(data.treasureCoverImg),
                        fit: BoxFit.cover,
                        placeholder: (_,__) => Skeleton.react(
                            width: double.infinity,
                            height: 157.h
                        ),
                        errorWidget: (_, __, ___) =>Skeleton.react(
                            width: double.infinity,
                            height: 157.h
                        ),
                      ),
                    ),
                ),
                Container(
                  height: 187.h,
                  padding: EdgeInsets.symmetric(horizontal: 6.w,vertical: 12.w),
                  decoration: BoxDecoration(
                    color: context.bgPrimary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// title
                      Container(
                        height: 40.h,
                        alignment: Alignment.center,
                        child: Text(
                          data.treasureName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.textSm,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary900
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h,),
                      /// price
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 22.h,
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:context.utilityBrand500,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              FormatHelper.formatCurrency(data.unitAmount,symbol: "₱ "),
                              style: TextStyle(
                                fontSize: context.text2xs,
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                color: context.textPrimaryOnBrand,
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 28.h,),
                      /// sold
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BubbleProgress(
                            value: rate,
                            showTip: true,
                            showTipBg: false,
                            color: context.utilityBrand500,
                            trackHeight: 4,
                            thumbSize: 8,
                            tipTextBuilder: (v){
                              final txt = v.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
                              return "$txt% ${'common.sold'.tr()}";
                            },
                          )
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}