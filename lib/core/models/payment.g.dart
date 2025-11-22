// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrdersCheckoutParams _$OrdersCheckoutParamsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'OrdersCheckoutParams',
  json,
  ($checkedConvert) {
    final val = OrdersCheckoutParams(
      treasureId: $checkedConvert('treasure_id', (v) => v as String),
      entries: $checkedConvert('entries', (v) => (v as num).toInt()),
      groupId: $checkedConvert('group_id', (v) => v as String?),
      couponId: $checkedConvert('coupon_id', (v) => v as String?),
      paymentMethod: $checkedConvert(
        'payment_method',
        (v) => (v as num).toInt(),
      ),
      addressId: $checkedConvert('address_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'treasureId': 'treasure_id',
    'groupId': 'group_id',
    'couponId': 'coupon_id',
    'paymentMethod': 'payment_method',
    'addressId': 'address_id',
  },
);

Map<String, dynamic> _$OrdersCheckoutParamsToJson(
  OrdersCheckoutParams instance,
) => <String, dynamic>{
  'treasure_id': instance.treasureId,
  'entries': instance.entries,
  'group_id': instance.groupId,
  'coupon_id': instance.couponId,
  'payment_method': instance.paymentMethod,
  'address_id': instance.addressId,
};

OrderCheckoutResponse _$OrderCheckoutResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'OrderCheckoutResponse',
  json,
  ($checkedConvert) {
    final val = OrderCheckoutResponse(
      orderId: $checkedConvert('order_id', (v) => v as String),
      orderNo: $checkedConvert('order_no', (v) => v as String),
      groupId: $checkedConvert('group_id', (v) => v as String?),
      lotteryTickets: $checkedConvert(
        'lottery_tickets',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      activityCoin: $checkedConvert('activity_coin', (v) => (v as num).toInt()),
      treasureId: $checkedConvert('treasure_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orderId': 'order_id',
    'orderNo': 'order_no',
    'groupId': 'group_id',
    'lotteryTickets': 'lottery_tickets',
    'activityCoin': 'activity_coin',
    'treasureId': 'treasure_id',
  },
);

Map<String, dynamic> _$OrderCheckoutResponseToJson(
  OrderCheckoutResponse instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'order_no': instance.orderNo,
  'group_id': instance.groupId,
  'lottery_tickets': instance.lotteryTickets,
  'activity_coin': instance.activityCoin,
  'treasure_id': instance.treasureId,
};
