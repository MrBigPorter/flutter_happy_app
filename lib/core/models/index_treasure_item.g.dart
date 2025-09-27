// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_treasure_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndexTreasureItem _$IndexTreasureItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IndexTreasureItem',
      json,
      ($checkedConvert) {
        final val = IndexTreasureItem(
          actId: $checkedConvert('act_id', (v) => (v as num).toInt()),
          imgStyleType: $checkedConvert(
            'img_style_type',
            (v) => (v as num).toInt(),
          ),
          treasureResp: $checkedConvert(
            'treasure_resp',
            (v) =>
                (v as List<dynamic>?)
                    ?.map(
                      (e) => TreasureProps.fromJson(e as Map<String, dynamic>),
                    )
                    .toList() ??
                [],
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'actId': 'act_id',
        'imgStyleType': 'img_style_type',
        'treasureResp': 'treasure_resp',
      },
    );

Map<String, dynamic> _$IndexTreasureItemToJson(IndexTreasureItem instance) =>
    <String, dynamic>{
      'act_id': instance.actId,
      'img_style_type': instance.imgStyleType,
      'treasure_resp': instance.treasureResp,
    };

TreasureProps _$TreasurePropsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TreasureProps',
  json,
  ($checkedConvert) {
    final val = TreasureProps(
      treasureId: $checkedConvert('treasure_id', (v) => (v as num).toInt()),
      lotteryTime: $checkedConvert('lottery_time', (v) => (v as num).toInt()),
      treasureName: $checkedConvert('treasure_name', (v) => v as String),
      imgStyleType: $checkedConvert(
        'img_style_type',
        (v) => (v as num).toInt(),
      ),
      lotteryMode: $checkedConvert('lottery_mode', (v) => (v as num).toInt()),
      productName: $checkedConvert('product_name', (v) => v as String),
      costAmount: $checkedConvert('cost_amount', (v) => (v as num).toInt()),
      mainImageList: $checkedConvert(
        'main_image_list',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      seqShelvesQuantity: $checkedConvert(
        'seq_shelves_quantity',
        (v) => (v as num).toInt(),
      ),
      seqBuyQuantity: $checkedConvert(
        'seq_buy_quantity',
        (v) => (v as num).toInt(),
      ),
      minBuyQuantity: $checkedConvert(
        'min_buy_quantity',
        (v) => (v as num).toInt(),
      ),
      buyQuantityRate: $checkedConvert('buy_quantity_rate', (v) => v as String),
      unitAmount: $checkedConvert('unit_amount', (v) => (v as num).toInt()),
      rate: $checkedConvert('rate', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'treasureId': 'treasure_id',
    'lotteryTime': 'lottery_time',
    'treasureName': 'treasure_name',
    'imgStyleType': 'img_style_type',
    'lotteryMode': 'lottery_mode',
    'productName': 'product_name',
    'costAmount': 'cost_amount',
    'mainImageList': 'main_image_list',
    'seqShelvesQuantity': 'seq_shelves_quantity',
    'seqBuyQuantity': 'seq_buy_quantity',
    'minBuyQuantity': 'min_buy_quantity',
    'buyQuantityRate': 'buy_quantity_rate',
    'unitAmount': 'unit_amount',
  },
);

Map<String, dynamic> _$TreasurePropsToJson(TreasureProps instance) =>
    <String, dynamic>{
      'treasure_id': instance.treasureId,
      'lottery_time': instance.lotteryTime,
      'treasure_name': instance.treasureName,
      'img_style_type': instance.imgStyleType,
      'lottery_mode': instance.lotteryMode,
      'product_name': instance.productName,
      'cost_amount': instance.costAmount,
      'main_image_list': instance.mainImageList,
      'seq_shelves_quantity': instance.seqShelvesQuantity,
      'seq_buy_quantity': instance.seqBuyQuantity,
      'min_buy_quantity': instance.minBuyQuantity,
      'buy_quantity_rate': instance.buyQuantityRate,
      'unit_amount': instance.unitAmount,
      'rate': instance.rate,
    };
