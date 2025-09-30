import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/models/product_list_item.dart';

class ProductItem extends StatelessWidget {
  final ProductListItem data;
  final int width = 157;
  const ProductItem({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        // Navigator.pushNamed(context, '/productDetail', arguments: data.id);
      },
      child: Container(
        width: width.w,
        margin: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
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
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}