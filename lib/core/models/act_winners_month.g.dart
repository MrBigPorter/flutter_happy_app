// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_winners_month.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActWinnersMonth _$ActWinnersMonthFromJson(Map<String, dynamic> json) =>
    ActWinnersMonth(
      treasureId: (json['treasure_id'] as num).toInt(),
      treasureName: json['treasure_name'] as String,
      mainImageList: (json['main_image_list'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      winnerName: json['winner_name'] as String,
      awardNumber: (json['award_number'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      lotteryTime: (json['lottery_time'] as num).toInt(),
    );

Map<String, dynamic> _$ActWinnersMonthToJson(ActWinnersMonth instance) =>
    <String, dynamic>{
      'treasure_id': instance.treasureId,
      'treasure_name': instance.treasureName,
      'main_image_list': instance.mainImageList,
      'winner_name': instance.winnerName,
      'award_number': instance.awardNumber,
      'month': instance.month,
      'lottery_time': instance.lotteryTime,
    };
