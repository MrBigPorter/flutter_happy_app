import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/home_components/home_featured.dart';
import 'package:flutter_app/app/page/home_components/recommendation.dart';
import 'package:flutter_app/app/page/home_components/special_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
import 'ending.dart';

class HomeTreasures extends StatelessWidget {
  final List<IndexTreasureItem>? treasures;

  const HomeTreasures({super.key, required this.treasures});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = treasures![index];
          if (item.imgStyleType == 1) {
            return Ending(list: item.treasureResp);
          } else if (item.imgStyleType == 2) {
            return SpecialArea(list: item.treasureResp);
          } else if (item.imgStyleType == 3) {
            return HomeFuture(list: item.treasureResp);
          } else if (item.imgStyleType == 4) {
            return Recommendation(list: item.treasureResp);
          }
          return SizedBox.shrink();
        }, childCount: treasures?.length ?? 0),
      ),
    );
  }
}
