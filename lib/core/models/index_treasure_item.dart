
import 'package:json_annotation/json_annotation.dart';
part 'index_treasure_item.g.dart';

@JsonSerializable(checked: true)
class IndexTreasureItem {
  @JsonKey(name: 'act_id')
  final int actId;
  @JsonKey(name: 'img_style_type')
  final int imgStyleType;
  @JsonKey(name: 'treasure_resp',defaultValue: [])
  final List<TreasureProps>? treasureResp;

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

@JsonSerializable(checked: true)
class TreasureProps {
  @JsonKey(name: 'treasure_id')
  final int treasureId;
  @JsonKey(name: 'lottery_time')
  final int lotteryTime;
  @JsonKey(name: 'treasure_name')
  final String treasureName;
  @JsonKey(name: 'img_style_type')
  final int imgStyleType;
  @JsonKey(name: 'lottery_mode')
  final int lotteryMode;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'cost_amount')
  final int costAmount;
  @JsonKey(name: 'main_image_list')
  final List<String> mainImageList;
  @JsonKey(name: 'seq_shelves_quantity')
  final int seqShelvesQuantity;
  @JsonKey(name: 'seq_buy_quantity')
  final int seqBuyQuantity;
  @JsonKey(name: 'min_buy_quantity')
  final int minBuyQuantity;
  @JsonKey(name: 'buy_quantity_rate')
  final String buyQuantityRate;
  @JsonKey(name: 'unit_amount')
  final int unitAmount;
  @JsonKey(name: 'rate')
  final int? rate;

  TreasureProps({
    required this.treasureId,
    required this.lotteryTime,
    required this.treasureName,
    required this.imgStyleType,
    required this.lotteryMode,
    required this.productName,
    required this.costAmount,
    required this.mainImageList,
    required this.seqShelvesQuantity,
    required this.seqBuyQuantity,
    required this.minBuyQuantity,
    required this.buyQuantityRate,
    required this.unitAmount,
     this.rate,
});

  factory TreasureProps.fromJson(Map<String,dynamic> json){
    try{
      return _$TreasurePropsFromJson(json);
    }catch(e){
      throw Exception('TreasureProps fromJson error: $e');
    }
  }
}