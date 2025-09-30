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
                      (e) =>
                          ProductListItem.fromJson(e as Map<String, dynamic>),
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
