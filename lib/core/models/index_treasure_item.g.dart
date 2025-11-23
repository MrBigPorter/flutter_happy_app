// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_treasure_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndexTreasureItem _$IndexTreasureItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('IndexTreasureItem', json, ($checkedConvert) {
      final val = IndexTreasureItem(
        actId: $checkedConvert('actId', (v) => (v as num).toInt()),
        imgStyleType: $checkedConvert(
          'imgStyleType',
          (v) => (v as num).toInt(),
        ),
        treasureResp: $checkedConvert(
          'treasureResp',
          (v) => (v as List<dynamic>?)
              ?.map((e) => ProductListItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$IndexTreasureItemToJson(IndexTreasureItem instance) =>
    <String, dynamic>{
      'actId': instance.actId,
      'imgStyleType': instance.imgStyleType,
      'treasureResp': instance.treasureResp,
    };
