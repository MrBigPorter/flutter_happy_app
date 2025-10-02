import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Ending extends StatelessWidget {
  final List<ProductListItem>? list;
  const Ending({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'common.ending.soon'.tr(),
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary900
              ),
            ),
          ),
        ),
        SizedBox(
          width: 375.w,
          height: 366.w,
          child: ListView.separated(
              padding: EdgeInsets.only(left: 16.w,top: 12.h,right: 16.w),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemBuilder:(context,index){
                final item = list![index];
                return ProductItem(data: item );
              },
              separatorBuilder: (_,__)=> SizedBox(width: 8.w,),
              itemCount: list!.length
          ),
        ),
      ],
    );
  }
}