// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_threshold_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponThresholdData _$CouponThresholdDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CouponThresholdData',
      json,
      ($checkedConvert) {
        final val = CouponThresholdData(
          couponId: $checkedConvert('couponId', (v) => (v as num).toInt()),
          getCoupons: $checkedConvert('getCoupons', (v) => (v as num).toInt()),
          rewardAmount:
              $checkedConvert('rewardAmount', (v) => (v as num).toDouble()),
          id: $checkedConvert('id', (v) => v as String),
          couponName: $checkedConvert('couponName', (v) => v as String),
          couponStatus:
              $checkedConvert('couponStatus', (v) => CouponStatus.fromJson(v)),
          treasureId:
              $checkedConvert('treasureId', (v) => (v as num?)?.toInt()),
          useAtEnd: $checkedConvert('useAtEnd', (v) => (v as num?)?.toInt()),
          useAtStart:
              $checkedConvert('useAtStart', (v) => (v as num?)?.toInt()),
          thresholdStart:
              $checkedConvert('thresholdStart', (v) => (v as num?)?.toDouble()),
          buyThresholdStart: $checkedConvert(
              'buyThresholdStart', (v) => (v as num?)?.toDouble()),
          currency: $checkedConvert('currency', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$CouponThresholdDataToJson(
        CouponThresholdData instance) =>
    <String, dynamic>{
      'buyThresholdStart': instance.buyThresholdStart,
      'couponId': instance.couponId,
      'currency': instance.currency,
      'getCoupons': instance.getCoupons,
      'rewardAmount': instance.rewardAmount,
      'id': instance.id,
      'couponName': instance.couponName,
      'couponStatus': CouponStatus.toJson(instance.couponStatus),
      'treasureId': instance.treasureId,
      'useAtEnd': instance.useAtEnd,
      'useAtStart': instance.useAtStart,
      'thresholdStart': instance.thresholdStart,
    };

CouponThresholdResponse _$CouponThresholdResponseFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'CouponThresholdResponse',
      json,
      ($checkedConvert) {
        final val = CouponThresholdResponse(
          couponThreshold: $checkedConvert(
              'couponThreshold',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      CouponThresholdData.fromJson(e as Map<String, dynamic>))
                  .toList()),
          desc: $checkedConvert('desc', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CouponThresholdResponseToJson(
        CouponThresholdResponse instance) =>
    <String, dynamic>{
      'couponThreshold': instance.couponThreshold,
      'desc': instance.desc,
    };
