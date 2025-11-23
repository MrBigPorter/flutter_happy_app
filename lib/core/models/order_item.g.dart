// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OrderItem', json, ($checkedConvert) {
  final val = OrderItem(
    addressId: $checkedConvert('addressId', (v) => v as String?),
    addressResp: $checkedConvert(
      'addressResp',
      (v) => v == null ? null : AddressRes.fromJson(v as Map<String, dynamic>),
    ),
    amountCoin: $checkedConvert('amountCoin', (v) => (v as num?)?.toDouble()),
    awardTicket: $checkedConvert('awardTicket', (v) => v as String?),
    betAmount: $checkedConvert('betAmount', (v) => (v as num?)?.toDouble()),
    currentStatus: $checkedConvert(
      'currentStatus',
      (v) => (v as num?)?.toDouble(),
    ),
    denomination: $checkedConvert('denomination', (v) => v as String?),
    entries: $checkedConvert('entries', (v) => (v as num).toDouble()),
    friend: $checkedConvert('friend', (v) => v as String?),
    friendTicket: $checkedConvert('friendTicket', (v) => v as String?),
    groupId: $checkedConvert('groupId', (v) => v as String?),
    handleStatus: $checkedConvert(
      'handleStatus',
      (v) => (v as num?)?.toDouble(),
    ),
    id: $checkedConvert('id', (v) => v as String),
    isOwn: $checkedConvert('isOwn', (v) => (v as num?)?.toDouble()),
    lotteryTime: $checkedConvert('lotteryTime', (v) => (v as num?)?.toInt()),
    mainImages: $checkedConvert('mainImages', (v) => v as String?),
    myTicket: $checkedConvert('myTicket', (v) => v as String?),
    orderStatus: $checkedConvert('orderStatus', (v) => (v as num).toInt()),
    payTime: $checkedConvert('payTime', (v) => (v as num?)?.toInt()),
    paymentMethod: $checkedConvert(
      'paymentMethod',
      (v) => (v as num?)?.toDouble(),
    ),
    prizeAmount: $checkedConvert('prizeAmount', (v) => (v as num?)?.toDouble()),
    prizeCoin: $checkedConvert('prizeCoin', (v) => (v as num?)?.toDouble()),
    productActualId: $checkedConvert(
      'productActualId',
      (v) => (v as num?)?.toDouble(),
    ),
    productName: $checkedConvert('productName', (v) => v as String),
    purchaseCount: $checkedConvert(
      'purchaseCount',
      (v) => (v as num).toDouble(),
    ),
    shareAmount: $checkedConvert('shareAmount', (v) => (v as num?)?.toDouble()),
    shareCoin: $checkedConvert('shareCoin', (v) => (v as num?)?.toInt()),
    stockQuantity: $checkedConvert(
      'stockQuantity',
      (v) => (v as num).toDouble(),
    ),
    ticketList: $checkedConvert(
      'ticketList',
      (v) => (v as List<dynamic>?)
          ?.map((e) => TicketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    totalAmount: $checkedConvert('totalAmount', (v) => (v as num).toDouble()),
    treasureId: $checkedConvert('treasureId', (v) => (v as num).toDouble()),
    userId: $checkedConvert('userId', (v) => v as String?),
    userPhone: $checkedConvert('userPhone', (v) => v as String?),
    virtual: $checkedConvert('virtual', (v) => (v as num).toInt()),
    virtualAccount: $checkedConvert('virtualAccount', (v) => v as String?),
    virtualCode: $checkedConvert('virtualCode', (v) => v as String?),
    treasureCoverImg: $checkedConvert('treasureCoverImg', (v) => v as String),
    treasureName: $checkedConvert('treasureName', (v) => v as String),
    refundReason: $checkedConvert('refundReason', (v) => v as String?),
    cashState: $checkedConvert('cashState', (v) => (v as num?)?.toInt()),
    cashAmount: $checkedConvert('cashAmount', (v) => (v as num?)?.toDouble()),
    cashEmail: $checkedConvert('cashEmail', (v) => v as String?),
    confirmState: $checkedConvert('confirmState', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'addressId': instance.addressId,
  'addressResp': instance.addressResp,
  'amountCoin': instance.amountCoin,
  'awardTicket': instance.awardTicket,
  'betAmount': instance.betAmount,
  'currentStatus': instance.currentStatus,
  'denomination': instance.denomination,
  'entries': instance.entries,
  'friend': instance.friend,
  'friendTicket': instance.friendTicket,
  'groupId': instance.groupId,
  'handleStatus': instance.handleStatus,
  'id': instance.id,
  'isOwn': instance.isOwn,
  'lotteryTime': instance.lotteryTime,
  'mainImages': instance.mainImages,
  'myTicket': instance.myTicket,
  'orderStatus': instance.orderStatus,
  'payTime': instance.payTime,
  'paymentMethod': instance.paymentMethod,
  'prizeAmount': instance.prizeAmount,
  'prizeCoin': instance.prizeCoin,
  'productActualId': instance.productActualId,
  'productName': instance.productName,
  'purchaseCount': instance.purchaseCount,
  'shareAmount': instance.shareAmount,
  'shareCoin': instance.shareCoin,
  'stockQuantity': instance.stockQuantity,
  'ticketList': instance.ticketList,
  'totalAmount': instance.totalAmount,
  'treasureId': instance.treasureId,
  'userId': instance.userId,
  'userPhone': instance.userPhone,
  'virtual': instance.virtual,
  'virtualAccount': instance.virtualAccount,
  'virtualCode': instance.virtualCode,
  'treasureCoverImg': instance.treasureCoverImg,
  'treasureName': instance.treasureName,
  'refundReason': instance.refundReason,
  'cashState': instance.cashState,
  'cashAmount': instance.cashAmount,
  'cashEmail': instance.cashEmail,
  'confirmState': instance.confirmState,
};

TicketItem _$TicketItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TicketItem', json, ($checkedConvert) {
      final val = TicketItem(
        status: $checkedConvert('status', (v) => (v as num).toDouble()),
        ticket: $checkedConvert('ticket', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TicketItemToJson(TicketItem instance) =>
    <String, dynamic>{'status': instance.status, 'ticket': instance.ticket};

OrderCount _$OrderCountFromJson(Map<String, dynamic> json) => $checkedCreate(
  'OrderCount',
  json,
  ($checkedConvert) {
    final val = OrderCount(
      activeCount: $checkedConvert('activeCount', (v) => (v as num).toDouble()),
      endCount: $checkedConvert('endCount', (v) => (v as num).toDouble()),
      refundCount: $checkedConvert('refundCount', (v) => (v as num).toDouble()),
    );
    return val;
  },
);

Map<String, dynamic> _$OrderCountToJson(OrderCount instance) =>
    <String, dynamic>{
      'activeCount': instance.activeCount,
      'endCount': instance.endCount,
      'refundCount': instance.refundCount,
    };

OrderListParams _$OrderListParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderListParams', json, ($checkedConvert) {
      final val = OrderListParams(
        orderState: $checkedConvert('orderState', (v) => (v as num).toInt()),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$OrderListParamsToJson(OrderListParams instance) =>
    <String, dynamic>{
      'orderState': instance.orderState,
      'page': instance.page,
      'size': instance.size,
    };
