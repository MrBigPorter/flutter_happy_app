// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_coupon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCoupon _$UserCouponFromJson(Map<String, dynamic> json) => $checkedCreate(
      'UserCoupon',
      json,
      ($checkedConvert) {
        final val = UserCoupon(
          userCouponId: $checkedConvert('userCouponId', (v) => v as String),
          status: $checkedConvert('status', (v) => (v as num?)?.toInt() ?? 0),
          validStartAt:
              $checkedConvert('validStartAt', (v) => (v as num).toInt()),
          validEndAt: $checkedConvert('validEndAt', (v) => (v as num).toInt()),
          couponName: $checkedConvert('couponName', (v) => v as String? ?? ''),
          couponType:
              $checkedConvert('couponType', (v) => (v as num?)?.toInt() ?? 1),
          discountValue:
              $checkedConvert('discountValue', (v) => v as String? ?? '0.00'),
          minPurchase:
              $checkedConvert('minPurchase', (v) => v as String? ?? '0.00'),
          ruleDesc: $checkedConvert('ruleDesc', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$UserCouponToJson(UserCoupon instance) =>
    <String, dynamic>{
      'userCouponId': instance.userCouponId,
      'status': instance.status,
      'validStartAt': instance.validStartAt,
      'validEndAt': instance.validEndAt,
      'couponName': instance.couponName,
      'couponType': instance.couponType,
      'discountValue': instance.discountValue,
      'minPurchase': instance.minPurchase,
      'ruleDesc': instance.ruleDesc,
    };

ClaimableCoupon _$ClaimableCouponFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ClaimableCoupon',
      json,
      ($checkedConvert) {
        final val = ClaimableCoupon(
          couponId: $checkedConvert('couponId', (v) => v as String),
          couponName: $checkedConvert('couponName', (v) => v as String),
          couponType: $checkedConvert('couponType', (v) => (v as num).toInt()),
          discountValue: $checkedConvert('discountValue', (v) => v as String),
          minPurchase: $checkedConvert('minPurchase', (v) => v as String),
          totalQuantity:
              $checkedConvert('totalQuantity', (v) => (v as num).toInt()),
          issuedQuantity:
              $checkedConvert('issuedQuantity', (v) => (v as num).toInt()),
          progress: $checkedConvert('progress', (v) => v as String),
          canClaim: $checkedConvert('canClaim', (v) => v as bool),
          hasReachedLimit: $checkedConvert('hasReachedLimit', (v) => v as bool),
          isClaimed: $checkedConvert('isClaimed', (v) => v as bool?),
          isSoldOut: $checkedConvert('isSoldOut', (v) => v as bool?),
        );
        return val;
      },
    );

Map<String, dynamic> _$ClaimableCouponToJson(ClaimableCoupon instance) =>
    <String, dynamic>{
      'couponId': instance.couponId,
      'couponName': instance.couponName,
      'couponType': instance.couponType,
      'discountValue': instance.discountValue,
      'minPurchase': instance.minPurchase,
      'totalQuantity': instance.totalQuantity,
      'issuedQuantity': instance.issuedQuantity,
      'isClaimed': instance.isClaimed,
      'isSoldOut': instance.isSoldOut,
      'progress': instance.progress,
      'canClaim': instance.canClaim,
      'hasReachedLimit': instance.hasReachedLimit,
    };
