
import 'package:flutter_app/common.dart';
import 'package:json_annotation/json_annotation.dart';
part 'index_treasure_item.g.dart';

@JsonSerializable(checked: true)
class IndexTreasureItem {
  @JsonKey(name: 'act_id')
  final int actId;
  @JsonKey(name: 'img_style_type')
  final int imgStyleType;
  @JsonKey(name: 'treasure_resp',defaultValue: [])
  final List<ProductListItem>? treasureResp;

  IndexTreasureItem({
    required this.actId,
    required this.imgStyleType,
     this.treasureResp,
  });

  factory IndexTreasureItem.fromJson(Map<String,dynamic> json){
    try{
      return _$IndexTreasureItemFromJson(json);
    }catch(e){
      throw Exception('IndexTreasureItem fromJson error: $e');
    }
  }
}

