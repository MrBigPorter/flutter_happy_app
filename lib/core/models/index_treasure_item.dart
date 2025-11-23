
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_app/core/models/product_list_item.dart';
part 'index_treasure_item.g.dart';

@JsonSerializable(checked: true)
class IndexTreasureItem {
  final int actId;
  final int imgStyleType;
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

