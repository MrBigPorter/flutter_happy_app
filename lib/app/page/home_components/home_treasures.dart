import 'package:flutter/cupertino.dart';
import 'package:flutter_app/app/page/home_components/home_featured.dart';
import 'package:flutter_app/app/page/home_components/recommendation.dart';
import 'package:flutter_app/app/page/home_components/special_area.dart';
import 'package:flutter_app/common.dart';

import 'ending.dart';

class HomeTreasures extends StatelessWidget{
  final List<IndexTreasureItem>? treasures;
  const HomeTreasures({super.key, required this.treasures});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: treasures!.map((item){
        if(item.imgStyleType == 1){
          return Ending(list: item.treasureResp);
        }else if(item.imgStyleType == 2) {
          return SpecialArea(list: item.treasureResp);
        }else if(item.imgStyleType == 3) {
          return HomeFuture(list: item.treasureResp,);
        }else if(item.imgStyleType == 4) {
          return Recommendation(list: item.treasureResp,);
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}