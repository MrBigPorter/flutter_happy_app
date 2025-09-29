import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';

class HomeAd extends StatelessWidget {
  final List<AdRes> list;
  const HomeAd({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    if(list.isEmpty) return const SizedBox.shrink();

    final openAds = list.where((item) => item.state == 1).toList();
    return Column(
      children: openAds.map((item){
        if(item.sortType == 1){
          return Text('SingleAd');
        }else{
          return Text("GridAd");
        }
      }).toList(),
    );
  }
}