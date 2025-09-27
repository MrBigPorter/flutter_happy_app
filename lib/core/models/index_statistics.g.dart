// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndexStatistics _$IndexStatisticsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IndexStatistics',
      json,
      ($checkedConvert) {
        final val = IndexStatistics(
          charityFundNum: $checkedConvert(
            'charity_fund_num',
            (v) => (v as num).toInt(),
          ),
          totalAmount: $checkedConvert(
            'total_amount',
            (v) => (v as num).toInt(),
          ),
          totalUserAmount: $checkedConvert(
            'total_user_amount',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'charityFundNum': 'charity_fund_num',
        'totalAmount': 'total_amount',
        'totalUserAmount': 'total_user_amount',
      },
    );

Map<String, dynamic> _$IndexStatisticsToJson(IndexStatistics instance) =>
    <String, dynamic>{
      'charity_fund_num': instance.charityFundNum,
      'total_amount': instance.totalAmount,
      'total_user_amount': instance.totalUserAmount,
    };
