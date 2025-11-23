// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrdersCheckoutParams _$OrdersCheckoutParamsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OrdersCheckoutParams', json, ($checkedConvert) {
  final val = OrdersCheckoutParams(
    treasureId: $checkedConvert('treasureId', (v) => v as String),
    entries: $checkedConvert('entries', (v) => (v as num).toInt()),
    groupId: $checkedConvert('groupId', (v) => v as String?),
    couponId: $checkedConvert('couponId', (v) => v as String?),
    paymentMethod: $checkedConvert('paymentMethod', (v) => (v as num).toInt()),
    addressId: $checkedConvert('addressId', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$OrdersCheckoutParamsToJson(
  OrdersCheckoutParams instance,
) => <String, dynamic>{
  'treasureId': instance.treasureId,
  'entries': instance.entries,
  'groupId': instance.groupId,
  'couponId': instance.couponId,
  'paymentMethod': instance.paymentMethod,
  'addressId': instance.addressId,
};

OrderCheckoutResponse _$OrderCheckoutResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OrderCheckoutResponse', json, ($checkedConvert) {
  final val = OrderCheckoutResponse(
    orderId: $checkedConvert('orderId', (v) => v as String),
    orderNo: $checkedConvert('orderNo', (v) => v as String),
    groupId: $checkedConvert('groupId', (v) => v as String?),
    lotteryTickets: $checkedConvert(
      'lotteryTickets',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    activityCoin: $checkedConvert('activityCoin', (v) => (v as num).toInt()),
    treasureId: $checkedConvert('treasureId', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$OrderCheckoutResponseToJson(
  OrderCheckoutResponse instance,
) => <String, dynamic>{
  'orderId': instance.orderId,
  'orderNo': instance.orderNo,
  'groupId': instance.groupId,
  'lotteryTickets': instance.lotteryTickets,
  'activityCoin': instance.activityCoin,
  'treasureId': instance.treasureId,
};
