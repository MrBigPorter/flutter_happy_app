// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'winners_lasts_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WinnersLastsItem _$WinnersLastsItemFromJson(Map<String, dynamic> json) =>
    WinnersLastsItem(
      mainImageList: (json['mainImageList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      treasureId: (json['treasureId'] as num).toInt(),
      treasureName: json['treasureName'] as String,
      winnerName: json['winnerName'] as String?,
      treasureCoverImg: json['treasureCoverImg'] as String?,
    );

Map<String, dynamic> _$WinnersLastsItemToJson(WinnersLastsItem instance) =>
    <String, dynamic>{
      'mainImageList': instance.mainImageList,
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'winnerName': instance.winnerName,
      'treasureCoverImg': instance.treasureCoverImg,
    };
