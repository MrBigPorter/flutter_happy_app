// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'winners_lasts_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WinnersLastsItem _$WinnersLastsItemFromJson(Map<String, dynamic> json) =>
    WinnersLastsItem(
      mainImageList:
          (json['main_image_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      treasureId: (json['treasure_id'] as num?)?.toInt() ?? 0,
      treasureName: json['treasure_name'] as String? ?? '',
      winnerName: json['winner_name'] as String? ?? '',
      treasureCoverImg: json['treasure_cover_img'] as String? ?? '',
    );

Map<String, dynamic> _$WinnersLastsItemToJson(WinnersLastsItem instance) =>
    <String, dynamic>{
      'main_image_list': instance.mainImageList,
      'treasure_id': instance.treasureId,
      'treasure_name': instance.treasureName,
      'winner_name': instance.winnerName,
      'treasure_cover_img': instance.treasureCoverImg,
    };
