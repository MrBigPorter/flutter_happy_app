// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_winners_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActWinnersMonth _$ActWinnersMonthFromJson(Map<String, dynamic> json) =>
    ActWinnersMonth(
      treasureId: (json['treasureId'] as num).toInt(),
      treasureName: json['treasureName'] as String,
      mainImageList: (json['mainImageList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      winnerName: json['winnerName'] as String,
      awardNumber: (json['awardNumber'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      lotteryTime: (json['lotteryTime'] as num).toInt(),
    );

Map<String, dynamic> _$ActWinnersMonthToJson(ActWinnersMonth instance) =>
    <String, dynamic>{
      'treasureId': instance.treasureId,
      'treasureName': instance.treasureName,
      'mainImageList': instance.mainImageList,
      'winnerName': instance.winnerName,
      'awardNumber': instance.awardNumber,
      'month': instance.month,
      'lotteryTime': instance.lotteryTime,
    };
