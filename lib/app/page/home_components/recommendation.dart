import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/product_item.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
class Recommendation extends StatelessWidget {
  final List<ProductListItem>? list;
  final String title;

  const Recommendation({super.key, required this.list, required this.title});

  @override
  Widget build(BuildContext context) {
    if (list == null || list!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 22.w),
          /// title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimary900,
              ),
            ),
          ),
          SizedBox(height: 15.w),

          /// list of products
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 两列 two columns
              crossAxisSpacing: 10.w, // 主轴间距 cross axis spacing
              mainAxisSpacing: 30.w, // cross间距 main axis spacing
              childAspectRatio: 165.w / 370.w, // 宽高比 width to height ratio
            ),
            itemBuilder: (context, index) {
              final item = list![index];
              return ProductCard(item: item);
            },
            itemCount: list!.length,
          ),
        ],
      ),
    );
  }
}


/// 商品卡片 product card (图片 + 信息卡片) (image + info card)
class ProductCard extends StatelessWidget {
  final ProductListItem item;

  const ProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ProductItem(
        data: item,
        imgWidth: 165,
        imgHeight: 165,
    );
  }
}
