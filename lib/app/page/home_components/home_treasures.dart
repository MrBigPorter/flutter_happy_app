import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/home_components/home_featured.dart';
import 'package:flutter_app/app/page/home_components/recommendation.dart';
import 'package:flutter_app/app/page/home_components/special_area.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_app/core/models/index.dart';
import 'ending.dart';
import 'group_buying_section.dart';

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
          // Dart 3 Switch 表达式：清晰、简洁
          return switch (item.imgStyleType) {
            // 1 => Ending(list: item.treasureResp, title: item.title),
            2 => SpecialArea(list: item.treasureResp, title: item.title),
            3 => HomeFuture(list: item.treasureResp, title: item.title),
            4 => Recommendation(list: item.treasureResp, title: item.title),
            1 => GroupBuyingSection(list: item.treasureResp, title: item.title),
            _ => const SizedBox.shrink(),
          };
        }, childCount: treasures?.length ?? 0),
      ),
    );
  }
}
