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
      addressId: $checkedConvert('address_id', (v) => v as String?),
      addressResp: $checkedConvert(
        'address_resp',
        (v) =>
            v == null ? null : AddressRes.fromJson(v as Map<String, dynamic>),
      ),
      amountCoin: $checkedConvert(
        'amount_coin',
        (v) => (v as num?)?.toDouble(),
      ),
      awardTicket: $checkedConvert('award_ticket', (v) => v as String?),
      betAmount: $checkedConvert('bet_amount', (v) => (v as num?)?.toDouble()),
      currentStatus: $checkedConvert(
        'current_status',
        (v) => (v as num?)?.toDouble(),
      ),
      denomination: $checkedConvert('denomination', (v) => v as String?),
      entries: $checkedConvert('entries', (v) => (v as num).toDouble()),
      friend: $checkedConvert('friend', (v) => v as String?),
      friendTicket: $checkedConvert('friend_ticket', (v) => v as String?),
      groupId: $checkedConvert('group_id', (v) => v as String?),
      handleStatus: $checkedConvert(
        'handle_status',
        (v) => (v as num?)?.toDouble(),
      ),
      id: $checkedConvert('id', (v) => v as String),
      isOwn: $checkedConvert('is_own', (v) => (v as num?)?.toDouble()),
      lotteryTime: $checkedConvert('lottery_time', (v) => (v as num?)?.toInt()),
      mainImages: $checkedConvert('main_images', (v) => v as String?),
      myTicket: $checkedConvert('my_ticket', (v) => v as String?),
      orderStatus: $checkedConvert('order_status', (v) => (v as num).toInt()),
      payTime: $checkedConvert('pay_time', (v) => (v as num?)?.toInt()),
      paymentMethod: $checkedConvert(
        'payment_method',
        (v) => (v as num?)?.toDouble(),
      ),
      prizeAmount: $checkedConvert(
        'prize_amount',
        (v) => (v as num?)?.toDouble(),
      ),
      prizeCoin: $checkedConvert('prize_coin', (v) => (v as num?)?.toDouble()),
      productActualId: $checkedConvert(
        'product_actual_id',
        (v) => (v as num?)?.toDouble(),
      ),
      productName: $checkedConvert('product_name', (v) => v as String),
      purchaseCount: $checkedConvert(
        'purchase_count',
        (v) => (v as num).toDouble(),
      ),
      shareAmount: $checkedConvert(
        'share_amount',
        (v) => (v as num?)?.toDouble(),
      ),
      shareCoin: $checkedConvert('share_coin', (v) => (v as num?)?.toInt()),
      stockQuantity: $checkedConvert(
        'stock_quantity',
        (v) => (v as num).toDouble(),
      ),
      ticketList: $checkedConvert(
        'ticket_list',
        (v) => (v as List<dynamic>?)
            ?.map((e) => TicketItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      totalAmount: $checkedConvert(
        'total_amount',
        (v) => (v as num).toDouble(),
      ),
      treasureId: $checkedConvert('treasure_id', (v) => (v as num).toDouble()),
      userId: $checkedConvert('user_id', (v) => v as String?),
      userPhone: $checkedConvert('user_phone', (v) => v as String?),
      virtual: $checkedConvert('virtual', (v) => (v as num).toInt()),
      virtualAccount: $checkedConvert('virtual_account', (v) => v as String?),
      virtualCode: $checkedConvert('virtual_code', (v) => v as String?),
      treasureCoverImg: $checkedConvert(
        'treasure_cover_img',
        (v) => v as String,
      ),
      treasureName: $checkedConvert('treasure_name', (v) => v as String),
      refundReason: $checkedConvert('refund_reason', (v) => v as String?),
      cashState: $checkedConvert('cash_state', (v) => (v as num?)?.toInt()),
      cashAmount: $checkedConvert(
        'cash_amount',
        (v) => (v as num?)?.toDouble(),
      ),
      cashEmail: $checkedConvert('cash_email', (v) => v as String?),
      confirmState: $checkedConvert(
        'confirm_state',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'addressId': 'address_id',
    'addressResp': 'address_resp',
    'amountCoin': 'amount_coin',
    'awardTicket': 'award_ticket',
    'betAmount': 'bet_amount',
    'currentStatus': 'current_status',
    'friendTicket': 'friend_ticket',
    'groupId': 'group_id',
    'handleStatus': 'handle_status',
    'isOwn': 'is_own',
    'lotteryTime': 'lottery_time',
    'mainImages': 'main_images',
    'myTicket': 'my_ticket',
    'orderStatus': 'order_status',
    'payTime': 'pay_time',
    'paymentMethod': 'payment_method',
    'prizeAmount': 'prize_amount',
    'prizeCoin': 'prize_coin',
    'productActualId': 'product_actual_id',
    'productName': 'product_name',
    'purchaseCount': 'purchase_count',
    'shareAmount': 'share_amount',
    'shareCoin': 'share_coin',
    'stockQuantity': 'stock_quantity',
    'ticketList': 'ticket_list',
    'totalAmount': 'total_amount',
    'treasureId': 'treasure_id',
    'userId': 'user_id',
    'userPhone': 'user_phone',
    'virtualAccount': 'virtual_account',
    'virtualCode': 'virtual_code',
    'treasureCoverImg': 'treasure_cover_img',
    'treasureName': 'treasure_name',
    'refundReason': 'refund_reason',
    'cashState': 'cash_state',
    'cashAmount': 'cash_amount',
    'cashEmail': 'cash_email',
    'confirmState': 'confirm_state',
  },
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'address_id': instance.addressId,
  'address_resp': instance.addressResp,
  'amount_coin': instance.amountCoin,
  'award_ticket': instance.awardTicket,
  'bet_amount': instance.betAmount,
  'current_status': instance.currentStatus,
  'denomination': instance.denomination,
  'entries': instance.entries,
  'friend': instance.friend,
  'friend_ticket': instance.friendTicket,
  'group_id': instance.groupId,
  'handle_status': instance.handleStatus,
  'id': instance.id,
  'is_own': instance.isOwn,
  'lottery_time': instance.lotteryTime,
  'main_images': instance.mainImages,
  'my_ticket': instance.myTicket,
  'order_status': instance.orderStatus,
  'pay_time': instance.payTime,
  'payment_method': instance.paymentMethod,
  'prize_amount': instance.prizeAmount,
  'prize_coin': instance.prizeCoin,
  'product_actual_id': instance.productActualId,
  'product_name': instance.productName,
  'purchase_count': instance.purchaseCount,
  'share_amount': instance.shareAmount,
  'share_coin': instance.shareCoin,
  'stock_quantity': instance.stockQuantity,
  'ticket_list': instance.ticketList,
  'total_amount': instance.totalAmount,
  'treasure_id': instance.treasureId,
  'user_id': instance.userId,
  'user_phone': instance.userPhone,
  'virtual': instance.virtual,
  'virtual_account': instance.virtualAccount,
  'virtual_code': instance.virtualCode,
  'treasure_cover_img': instance.treasureCoverImg,
  'treasure_name': instance.treasureName,
  'refund_reason': instance.refundReason,
  'cash_state': instance.cashState,
  'cash_amount': instance.cashAmount,
  'cash_email': instance.cashEmail,
  'confirm_state': instance.confirmState,
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
      activeCount: $checkedConvert(
        'active_count',
        (v) => (v as num).toDouble(),
      ),
      endCount: $checkedConvert('end_count', (v) => (v as num).toDouble()),
      refundCount: $checkedConvert(
        'refund_count',
        (v) => (v as num).toDouble(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'activeCount': 'active_count',
    'endCount': 'end_count',
    'refundCount': 'refund_count',
  },
);

Map<String, dynamic> _$OrderCountToJson(OrderCount instance) =>
    <String, dynamic>{
      'active_count': instance.activeCount,
      'end_count': instance.endCount,
      'refund_count': instance.refundCount,
    };

OrderListParams _$OrderListParamsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OrderListParams', json, ($checkedConvert) {
      final val = OrderListParams(
        orderState: $checkedConvert('order_state', (v) => (v as num).toInt()),
        page: $checkedConvert('page', (v) => (v as num).toInt()),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'orderState': 'order_state'});

Map<String, dynamic> _$OrderListParamsToJson(OrderListParams instance) =>
    <String, dynamic>{
      'order_state': instance.orderState,
      'page': instance.page,
      'size': instance.size,
    };
