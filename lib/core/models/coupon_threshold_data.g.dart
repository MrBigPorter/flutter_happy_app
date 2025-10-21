// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coupon_threshold_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CouponThresholdData _$CouponThresholdDataFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CouponThresholdData',
  json,
  ($checkedConvert) {
    final val = CouponThresholdData(
      couponId: $checkedConvert('coupon_id', (v) => (v as num).toInt()),
      getCoupons: $checkedConvert('get_coupons', (v) => (v as num).toInt()),
      rewardAmount: $checkedConvert(
        'reward_amount',
        (v) => (v as num).toDouble(),
      ),
      id: $checkedConvert('id', (v) => v as String),
      couponName: $checkedConvert('coupon_name', (v) => v as String),
      couponStatus: $checkedConvert(
        'coupon_status',
        (v) => CouponStatus.fromJson(v),
      ),
      treasureId: $checkedConvert('treasure_id', (v) => (v as num?)?.toInt()),
      useAtEnd: $checkedConvert('use_at_end', (v) => (v as num?)?.toInt()),
      useAtStart: $checkedConvert('use_at_start', (v) => (v as num?)?.toInt()),
      thresholdStart: $checkedConvert(
        'threshold_start',
        (v) => (v as num?)?.toDouble(),
      ),
      buyThresholdStart: $checkedConvert(
        'buy_threshold_start',
        (v) => (v as num?)?.toDouble(),
      ),
      currency: $checkedConvert('currency', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'couponId': 'coupon_id',
    'getCoupons': 'get_coupons',
    'rewardAmount': 'reward_amount',
    'couponName': 'coupon_name',
    'couponStatus': 'coupon_status',
    'treasureId': 'treasure_id',
    'useAtEnd': 'use_at_end',
    'useAtStart': 'use_at_start',
    'thresholdStart': 'threshold_start',
    'buyThresholdStart': 'buy_threshold_start',
  },
);

Map<String, dynamic> _$CouponThresholdDataToJson(
  CouponThresholdData instance,
) => <String, dynamic>{
  'buy_threshold_start': instance.buyThresholdStart,
  'coupon_id': instance.couponId,
  'currency': instance.currency,
  'get_coupons': instance.getCoupons,
  'reward_amount': instance.rewardAmount,
  'id': instance.id,
  'coupon_name': instance.couponName,
  'coupon_status': CouponStatus.toJson(instance.couponStatus),
  'treasure_id': instance.treasureId,
  'use_at_end': instance.useAtEnd,
  'use_at_start': instance.useAtStart,
  'threshold_start': instance.thresholdStart,
};

CouponThresholdResponse _$CouponThresholdResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CouponThresholdResponse',
  json,
  ($checkedConvert) {
    final val = CouponThresholdResponse(
      couponThreshold: $checkedConvert(
        'coupon_threshold',
        (v) => (v as List<dynamic>)
            .map((e) => CouponThresholdData.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      desc: $checkedConvert('desc', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {'couponThreshold': 'coupon_threshold'},
);

Map<String, dynamic> _$CouponThresholdResponseToJson(
  CouponThresholdResponse instance,
) => <String, dynamic>{
  'coupon_threshold': instance.couponThreshold,
  'desc': instance.desc,
};
