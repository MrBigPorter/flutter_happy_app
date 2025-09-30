// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductListItem _$ProductListItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ProductListItem',
  json,
  ($checkedConvert) {
    final val = ProductListItem(
      buyQuantityRate: $checkedConvert('buy_quantity_rate', (v) => v as String),
      costAmount: $checkedConvert('cost_amount', (v) => (v as num).toInt()),
      imgStyleType: $checkedConvert(
        'img_style_type',
        (v) => (v as num).toInt(),
      ),
      lotteryMode: $checkedConvert('lottery_mode', (v) => (v as num).toInt()),
      lotteryTime: $checkedConvert('lottery_time', (v) => (v as num).toInt()),
      mainImageList: $checkedConvert(
        'main_image_list',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      minBuyQuantity: $checkedConvert(
        'min_buy_quantity',
        (v) => (v as num).toInt(),
      ),
      productName: $checkedConvert('product_name', (v) => v as String),
      seqBuyQuantity: $checkedConvert(
        'seq_buy_quantity',
        (v) => (v as num).toInt(),
      ),
      seqShelvesQuantity: $checkedConvert(
        'seq_shelves_quantity',
        (v) => (v as num).toInt(),
      ),
      treasureId: $checkedConvert('treasure_id', (v) => (v as num).toInt()),
      treasureName: $checkedConvert('treasure_name', (v) => v as String),
      unitAmount: $checkedConvert('unit_amount', (v) => (v as num).toInt()),
      treasureCoverImg: $checkedConvert(
        'treasure_cover_img',
        (v) => v as String,
      ),
      rate: $checkedConvert('rate', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'buyQuantityRate': 'buy_quantity_rate',
    'costAmount': 'cost_amount',
    'imgStyleType': 'img_style_type',
    'lotteryMode': 'lottery_mode',
    'lotteryTime': 'lottery_time',
    'mainImageList': 'main_image_list',
    'minBuyQuantity': 'min_buy_quantity',
    'productName': 'product_name',
    'seqBuyQuantity': 'seq_buy_quantity',
    'seqShelvesQuantity': 'seq_shelves_quantity',
    'treasureId': 'treasure_id',
    'treasureName': 'treasure_name',
    'unitAmount': 'unit_amount',
    'treasureCoverImg': 'treasure_cover_img',
  },
);

Map<String, dynamic> _$ProductListItemToJson(ProductListItem instance) =>
    <String, dynamic>{
      'buy_quantity_rate': instance.buyQuantityRate,
      'cost_amount': instance.costAmount,
      'img_style_type': instance.imgStyleType,
      'lottery_mode': instance.lotteryMode,
      'lottery_time': instance.lotteryTime,
      'main_image_list': instance.mainImageList,
      'min_buy_quantity': instance.minBuyQuantity,
      'product_name': instance.productName,
      'seq_buy_quantity': instance.seqBuyQuantity,
      'seq_shelves_quantity': instance.seqShelvesQuantity,
      'treasure_id': instance.treasureId,
      'treasure_name': instance.treasureName,
      'unit_amount': instance.unitAmount,
      'treasure_cover_img': instance.treasureCoverImg,
      'rate': instance.rate,
    };
