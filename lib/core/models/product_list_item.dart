import 'package:json_annotation/json_annotation.dart';

part 'product_list_item.g.dart';

@JsonSerializable(checked: true)
class ProductListItem{
  @JsonKey(name:'buy_quantity_rate')
  final String buyQuantityRate;
  @JsonKey(name:'cost_amount')
  final int costAmount;
  @JsonKey(name:'img_style_type')
  final int imgStyleType;
  @JsonKey(name:'lottery_mode')
  final int lotteryMode;
  @JsonKey(name:'lottery_time')
  final int lotteryTime;
  @JsonKey(name:'main_image_list')
  final List<String>? mainImageList;
  @JsonKey(name:'min_buy_quantity')
  final int minBuyQuantity;
  @JsonKey(name:'product_name')
  final String productName;
  @JsonKey(name:'seq_buy_quantity')
  final int seqBuyQuantity;
  @JsonKey(name:'seq_shelves_quantity')
  final int seqShelvesQuantity;
  @JsonKey(name:'treasure_id')
  final int treasureId;
  @JsonKey(name:'treasure_name')
  final String treasureName;
  @JsonKey(name:'unit_amount')
  final int unitAmount;
  @JsonKey(name:'treasure_cover_img')
  final String treasureCoverImg;
  @JsonKey(name: 'rate')
  final int? rate;

  ProductListItem({
    required this.buyQuantityRate,
    required this.costAmount,
    required this.imgStyleType,
    required this.lotteryMode,
    required this.lotteryTime,
     this.mainImageList,
    required this.minBuyQuantity,
    required this.productName,
    required this.seqBuyQuantity,
    required this.seqShelvesQuantity,
    required this.treasureId,
    required this.treasureName,
    required this.unitAmount,
    required this.treasureCoverImg,
    this.rate,
  });

  factory ProductListItem.fromJson(Map<String,dynamic> json) => _$ProductListItemFromJson(json);
}