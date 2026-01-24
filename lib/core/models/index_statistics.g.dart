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
          charityFundNum:
              $checkedConvert('charityFundNum', (v) => (v as num).toInt()),
          totalAmount:
              $checkedConvert('totalAmount', (v) => (v as num).toInt()),
          totalUserAmount:
              $checkedConvert('totalUserAmount', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$IndexStatisticsToJson(IndexStatistics instance) =>
    <String, dynamic>{
      'charityFundNum': instance.charityFundNum,
      'totalAmount': instance.totalAmount,
      'totalUserAmount': instance.totalUserAmount,
    };
