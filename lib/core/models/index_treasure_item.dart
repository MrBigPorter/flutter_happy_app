
import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_app/core/models/product_list_item.dart';
part 'index_treasure_item.g.dart';

@JsonSerializable(checked: true)
class IndexTreasureItem {
  final String actId;
  final int imgStyleType;
  final String title;
  final List<ProductListItem>? treasureResp;

  IndexTreasureItem({
    required this.actId,
      required this.title,
    required this.imgStyleType,
     this.treasureResp,
  });

  factory IndexTreasureItem.fromJson(Map<String,dynamic> json) => _$IndexTreasureItemFromJson(json);

  Map<String,dynamic> toJson() => _$IndexTreasureItemToJson(this);

  @override
  String toString() {
   return toJson().toString();
  }
}

