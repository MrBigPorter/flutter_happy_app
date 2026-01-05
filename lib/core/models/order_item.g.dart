// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => $checkedCreate(
  'OrderItem',
  json,
  ($checkedConvert) {
    final val = OrderItem(
      orderId: $checkedConvert('orderId', (v) => v as String),
      orderNo: $checkedConvert('orderNo', (v) => v as String),
      createdAt: $checkedConvert('createdAt', (v) => v as num?),
      updatedAt: $checkedConvert('updatedAt', (v) => v as num?),
      buyQuantity: $checkedConvert('buyQuantity', (v) => v as num),
      treasureId: $checkedConvert('treasureId', (v) => v as String),
      unitPrice: $checkedConvert('unitPrice', (v) => v as String),
      originalAmount: $checkedConvert('originalAmount', (v) => v as String),
      discountAmount: $checkedConvert('discountAmount', (v) => v as String),
      couponAmount: $checkedConvert('couponAmount', (v) => v as String),
      coinAmount: $checkedConvert('coinAmount', (v) => v as String),
      finalAmount: $checkedConvert('finalAmount', (v) => v as String),
      orderStatus: $checkedConvert('orderStatus', (v) => (v as num).toInt()),
      payStatus: $checkedConvert('payStatus', (v) => (v as num).toInt()),
      refundStatus: $checkedConvert('refundStatus', (v) => (v as num).toInt()),
      treasure: $checkedConvert(
        'treasure',
        (v) => Treasure.fromJson(v as Map<String, dynamic>),
      ),
      paidAt: $checkedConvert('paidAt', (v) => v as num?),
      addressId: $checkedConvert('addressId', (v) => v as String?),
      addressResp: $checkedConvert(
        'addressResp',
        (v) =>
            v == null ? null : AddressRes.fromJson(v as Map<String, dynamic>),
      ),
      ticketList: $checkedConvert(
        'ticketList',
        (v) => (v as List<dynamic>?)
            ?.map((e) => TicketItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      refundReason: $checkedConvert('refundReason', (v) => v as String?),
      group: $checkedConvert(
        'group',
        (v) => v == null ? null : Group.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'orderId': instance.orderId,
  'orderNo': instance.orderNo,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'buyQuantity': instance.buyQuantity,
  'treasureId': instance.treasureId,
  'unitPrice': instance.unitPrice,
  'originalAmount': instance.originalAmount,
  'discountAmount': instance.discountAmount,
  'couponAmount': instance.couponAmount,
  'coinAmount': instance.coinAmount,
  'finalAmount': instance.finalAmount,
  'orderStatus': instance.orderStatus,
  'payStatus': instance.payStatus,
  'refundStatus': instance.refundStatus,
  'paidAt': instance.paidAt,
  'treasure': instance.treasure,
  'group': instance.group,
  'addressId': instance.addressId,
  'addressResp': instance.addressResp,
  'ticketList': instance.ticketList,
  'refundReason': instance.refundReason,
};

OrderDetailItem _$OrderDetailItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderDetailItem', json, ($checkedConvert) {
      final val = OrderDetailItem(
        orderId: $checkedConvert('orderId', (v) => v as String),
        orderNo: $checkedConvert('orderNo', (v) => v as String),
        createdAt: $checkedConvert('createdAt', (v) => v as num?),
        updatedAt: $checkedConvert('updatedAt', (v) => v as num?),
        buyQuantity: $checkedConvert('buyQuantity', (v) => v as num),
        treasureId: $checkedConvert('treasureId', (v) => v as String),
        unitPrice: $checkedConvert('unitPrice', (v) => v as String),
        originalAmount: $checkedConvert('originalAmount', (v) => v as String),
        discountAmount: $checkedConvert('discountAmount', (v) => v as String),
        couponAmount: $checkedConvert('couponAmount', (v) => v as String),
        coinAmount: $checkedConvert('coinAmount', (v) => v as String),
        finalAmount: $checkedConvert('finalAmount', (v) => v as String),
        orderStatus: $checkedConvert('orderStatus', (v) => (v as num).toInt()),
        payStatus: $checkedConvert('payStatus', (v) => (v as num).toInt()),
        refundStatus: $checkedConvert(
          'refundStatus',
          (v) => (v as num).toInt(),
        ),
        treasure: $checkedConvert(
          'treasure',
          (v) => Treasure.fromJson(v as Map<String, dynamic>),
        ),
        paidAt: $checkedConvert('paidAt', (v) => v as num?),
        addressId: $checkedConvert('addressId', (v) => v as String?),
        addressResp: $checkedConvert(
          'addressResp',
          (v) =>
              v == null ? null : AddressRes.fromJson(v as Map<String, dynamic>),
        ),
        ticketList: $checkedConvert(
          'ticketList',
          (v) => (v as List<dynamic>?)
              ?.map((e) => TicketItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        refundReason: $checkedConvert('refundReason', (v) => v as String?),
        group: $checkedConvert(
          'group',
          (v) => v == null ? null : Group.fromJson(v as Map<String, dynamic>),
        ),
        transactions: $checkedConvert(
          'transactions',
          (v) => (v as List<dynamic>)
              .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OrderDetailItemToJson(OrderDetailItem instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'orderNo': instance.orderNo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'buyQuantity': instance.buyQuantity,
      'treasureId': instance.treasureId,
      'unitPrice': instance.unitPrice,
      'originalAmount': instance.originalAmount,
      'discountAmount': instance.discountAmount,
      'couponAmount': instance.couponAmount,
      'coinAmount': instance.coinAmount,
      'finalAmount': instance.finalAmount,
      'orderStatus': instance.orderStatus,
      'payStatus': instance.payStatus,
      'refundStatus': instance.refundStatus,
      'paidAt': instance.paidAt,
      'treasure': instance.treasure,
      'group': instance.group,
      'addressId': instance.addressId,
      'addressResp': instance.addressResp,
      'ticketList': instance.ticketList,
      'refundReason': instance.refundReason,
      'transactions': instance.transactions,
    };

Treasure _$TreasureFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('Treasure', json, ($checkedConvert) {
  final val = Treasure(
    treasureName: $checkedConvert('treasureName', (v) => v as String),
    treasureCoverImg: $checkedConvert('treasureCoverImg', (v) => v as String),
    productName: $checkedConvert('productName', (v) => v as String?),
    virtual: $checkedConvert('virtual', (v) => (v as num).toInt()),
    cashAmount: $checkedConvert('cashAmount', (v) => v as String?),
    cashState: $checkedConvert('cashState', (v) => (v as num?)?.toInt()),
    seqShelvesQuantity: $checkedConvert('seqShelvesQuantity', (v) => v as num?),
    seqBuyQuantity: $checkedConvert('seqBuyQuantity', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$TreasureToJson(Treasure instance) => <String, dynamic>{
  'treasureName': instance.treasureName,
  'treasureCoverImg': instance.treasureCoverImg,
  'productName': instance.productName,
  'virtual': instance.virtual,
  'cashAmount': instance.cashAmount,
  'cashState': instance.cashState,
  'seqShelvesQuantity': instance.seqShelvesQuantity,
  'seqBuyQuantity': instance.seqBuyQuantity,
};

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('WalletTransaction', json, ($checkedConvert) {
      final val = WalletTransaction(
        transactionNo: $checkedConvert('transactionNo', (v) => v as String),
        amount: $checkedConvert('amount', (v) => v as String),
        balanceType: $checkedConvert('balanceType', (v) => (v as num).toInt()),
        status: $checkedConvert('status', (v) => (v as num).toInt()),
        createdAt: $checkedConvert('createdAt', (v) => v as num),
      );
      return val;
    });

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'transactionNo': instance.transactionNo,
      'amount': instance.amount,
      'balanceType': instance.balanceType,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

Group _$GroupFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Group', json, ($checkedConvert) {
      final val = Group(
        groupId: $checkedConvert('groupId', (v) => v as String),
        groupStatus: $checkedConvert('groupStatus', (v) => (v as num).toInt()),
        currentMembers: $checkedConvert(
          'currentMembers',
          (v) => (v as num).toInt(),
        ),
        maxMembers: $checkedConvert('maxMembers', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$GroupToJson(Group instance) => <String, dynamic>{
  'groupId': instance.groupId,
  'groupStatus': instance.groupStatus,
  'currentMembers': instance.currentMembers,
  'maxMembers': instance.maxMembers,
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

OrderCount _$OrderCountFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderCount', json, ($checkedConvert) {
      final val = OrderCount(
        paid: $checkedConvert('paid', (v) => (v as num).toInt()),
        unpaid: $checkedConvert('unpaid', (v) => (v as num).toInt()),
        refunded: $checkedConvert('refunded', (v) => (v as num).toInt()),
        cancelled: $checkedConvert('cancelled', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$OrderCountToJson(OrderCount instance) =>
    <String, dynamic>{
      'paid': instance.paid,
      'unpaid': instance.unpaid,
      'refunded': instance.refunded,
      'cancelled': instance.cancelled,
    };

OrderListParams _$OrderListParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderListParams', json, ($checkedConvert) {
      final val = OrderListParams(
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        pageSize: $checkedConvert('pageSize', (v) => (v as num).toInt()),
        status: $checkedConvert('status', (v) => v as String),
        treasureId: $checkedConvert('treasureId', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$OrderListParamsToJson(OrderListParams instance) =>
    <String, dynamic>{
      'status': instance.status,
      'treasureId': instance.treasureId,
      'page': instance.page,
      'pageSize': instance.pageSize,
    };
