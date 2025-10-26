import 'package:json_annotation/json_annotation.dart';

import 'address_res.dart';

part 'order_item.g.dart';

@JsonSerializable(checked: true)
class OrderItem {
  @JsonKey(name: 'address_id')
  final String? addressId;
  @JsonKey(name: 'address_resp')
  final AddressRes? addressResp;
  @JsonKey(name: 'amount_coin')
  final double? amountCoin;
  @JsonKey(name: 'award_ticket')
  final String? awardTicket;
  @JsonKey(name: 'bet_amount')
  final double? betAmount;
  @JsonKey(name: 'current_status')
  final double? currentStatus;
  @JsonKey(name: 'denomination')
  final String? denomination;
  @JsonKey(name: 'entries')
  final double entries;
  @JsonKey(name: 'friend')
  final String? friend;
  @JsonKey(name: 'friend_ticket')
  final String? friendTicket;
  @JsonKey(name: 'group_id')
  final String? groupId;
  @JsonKey(name: 'handle_status')
  final double? handleStatus;
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'is_own')
  final double? isOwn;
  @JsonKey(name: 'lottery_time')
  final int? lotteryTime;
  @JsonKey(name: 'main_images')
  final String? mainImages;
  @JsonKey(name: 'my_ticket')
  final String? myTicket;
  @JsonKey(name: 'order_status')
  final int orderStatus;
  @JsonKey(name: 'pay_time')
  final int? payTime;
  @JsonKey(name: 'payment_method')
  final double? paymentMethod;
  @JsonKey(name: 'prize_amount')
  final double? prizeAmount;
  @JsonKey(name: 'prize_coin')
  final double? prizeCoin;
  @JsonKey(name: 'product_actual_id')
  final double? productActualId;
  @JsonKey(name: 'product_name')
  final String productName;
  @JsonKey(name: 'purchase_count')
  final double purchaseCount;
  @JsonKey(name: 'share_amount')
  final double? shareAmount;
  @JsonKey(name: 'share_coin')
  final double? shareCoin;
  @JsonKey(name: 'stock_quantity')
  final double stockQuantity;
  @JsonKey(name: 'ticket_list')
  final List<TicketItem>? ticketList;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @JsonKey(name: 'treasure_id')
  final double treasureId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'user_phone')
  final String? userPhone;
  @JsonKey(name: 'virtual')
  final double virtual;
  @JsonKey(name: 'virtual_account')
  final String? virtualAccount;
  @JsonKey(name: 'virtual_code')
  final String? virtualCode;
  @JsonKey(name: 'treasure_cover_img')
  final String treasureCoverImg;
  @JsonKey(name: 'treasure_name')
  final String treasureName;
  @JsonKey(name: 'refund_reason')
  final String? refundReason;
  @JsonKey(name: 'cash_state')
  final double? cashState;
  @JsonKey(name: 'cash_amount')
  final double? cashAmount;
  @JsonKey(name: 'cash_email')
  final String? cashEmail;
  @JsonKey(name: 'confirm_state')
  final double? confirmState;

  const OrderItem({
    required this.addressId,
    required this.addressResp,
    required this.amountCoin,
    required this.awardTicket,
    required this.betAmount,
    required this.currentStatus,
    required this.denomination,
    required this.entries,
    required this.friend,
    required this.friendTicket,
    required this.groupId,
    required this.handleStatus,
    required this.id,
    required this.isOwn,
    required this.lotteryTime,
    required this.mainImages,
    required this.myTicket,
    required this.orderStatus,
    required this.payTime,
    required this.paymentMethod,
    required this.prizeAmount,
    required this.prizeCoin,
    required this.productActualId,
    required this.productName,
    required this.purchaseCount,
    required this.shareAmount,
    required this.shareCoin,
    required this.stockQuantity,
    required this.ticketList,
    required this.totalAmount,
    required this.treasureId,
    required this.userId,
    required this.userPhone,
    required this.virtual,
    required this.virtualAccount,
    required this.virtualCode,
    required this.treasureCoverImg,
    required this.treasureName,
    this.refundReason,
    this.cashState,
    this.cashAmount,
    this.cashEmail,
    required this.confirmState,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class TicketItem {
  @JsonKey(name: 'status')
  final double status;
  @JsonKey(name: 'ticket')
  final String ticket;

  const TicketItem({required this.status, required this.ticket});

  factory TicketItem.fromJson(Map<String, dynamic> json) =>
      _$TicketItemFromJson(json);

  Map<String, dynamic> toJson() => _$TicketItemToJson(this);
}

@JsonSerializable(checked: true)
class OrderCount {
  @JsonKey(name: 'active_count')
  final double activeCount;
  @JsonKey(name: 'end_count')
  final double endCount;
  @JsonKey(name: 'refund_count')
  final double refundCount;

  const OrderCount({
    required this.activeCount,
    required this.endCount,
    required this.refundCount,
  });

  factory OrderCount.fromJson(Map<String, dynamic> json) =>
      _$OrderCountFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCountToJson(this);
}


@JsonSerializable(checked: true)
class OrderListParams {
  @JsonKey(name: 'order_state')
  final String orderState;
  @JsonKey(name: 'current')
  final int current;
  @JsonKey(name: 'size')
  final int size;

  const OrderListParams({
    required this.orderState,
    required this.current,
    required this.size,
  });


  Map<String, dynamic> toJson() => _$OrderListParamsToJson(this);

}

/// model for tab item in order screen
class TabItem {
  final String name;
  final double value;
  final double total;

  TabItem({required this.name, required this.value, required this.total});
}

enum OrderStatus {
  pending,// 未开奖
  won,// 用户中奖
  refunded,// 已退款
  groupSuccess, // 拼团达成
  ended,// 已结束未中奖
}

OrderStatus parseOrderStatus(int status) {
  switch (status) {
    case 2: return OrderStatus.won;
    case 4: return OrderStatus.refunded;
    case 6: return OrderStatus.groupSuccess;
    default: return OrderStatus.pending;
  }
}