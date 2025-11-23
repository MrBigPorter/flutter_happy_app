import 'package:json_annotation/json_annotation.dart';

import 'address_res.dart';

part 'order_item.g.dart';

@JsonSerializable(checked: true)
class OrderItem {
  final String? addressId;
  final AddressRes? addressResp;
  final double? amountCoin;
  final String? awardTicket;
  final double? betAmount;
  final double? currentStatus;
  final String? denomination;
  final double entries;
  final String? friend;
  final String? friendTicket;
  final String? groupId;
  final double? handleStatus;
  final String id;
  final double? isOwn;
  final int? lotteryTime;
  final String? mainImages;
  final String? myTicket;
  final int orderStatus;
  final int? payTime;
  final double? paymentMethod;
  final double? prizeAmount;
  final double? prizeCoin;
  final double? productActualId;
  final String productName;
  final double purchaseCount;
  final double? shareAmount;
  final int? shareCoin;
  final double stockQuantity;
  final List<TicketItem>? ticketList;
  final double totalAmount;
  final double treasureId;
  final String? userId;
  final String? userPhone;
  final int virtual;
  final String? virtualAccount;
  final String? virtualCode;
  final String treasureCoverImg;
  final String treasureName;
  final String? refundReason;
  final int? cashState;
  final double? cashAmount;
  final String? cashEmail;
  final int? confirmState;

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
  final double status;
  final String ticket;

  const TicketItem({required this.status, required this.ticket});

  factory TicketItem.fromJson(Map<String, dynamic> json) =>
      _$TicketItemFromJson(json);

  Map<String, dynamic> toJson() => _$TicketItemToJson(this);
}

@JsonSerializable(checked: true)
class OrderCount {
  final double activeCount;
  final double endCount;
  final double refundCount;

  const OrderCount({
    required this.activeCount,
    required this.endCount,
    required this.refundCount,
  });

  Map<String, dynamic> asMap() {
    return {
      'activeCount': activeCount,
      'endCount': endCount,
      'refundCount': refundCount,
    };
  }


  factory OrderCount.fromJson(Map<String, dynamic> json) =>
      _$OrderCountFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCountToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class OrderListParams {
  final int orderState;
  final int page;
  final int size;

  const OrderListParams({
    required this.orderState,
    required this.page,
    required this.size,
  });


  Map<String, dynamic> toJson() => _$OrderListParamsToJson(this);

}

/// model for tab item in order screen
class TabItem {
  final String name;
  final int value;
  final int total;
  final String key;

  TabItem({required this.name, required this.value, required this.total, required this.key});

  TabItem copyWith({
    String? name,
    int? value,
    int? total,
    String? key,
  }) {
    return TabItem(
      name: name ?? this.name,
      value: value ?? this.value,
      total: total ?? this.total,
      key: key ?? this.key,
    );
  }
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

extension OrderItemExtension on OrderItem {
  OrderStatus get orderStatusEnum => parseOrderStatus(orderStatus);

  bool get isPending => orderStatusEnum == OrderStatus.pending;
  /// 是否中奖
  bool get isWon => orderStatusEnum == OrderStatus.won;
  /// 是否已经退款
  bool get isRefunded => orderStatusEnum == OrderStatus.refunded;
  /// 是否拼团成功
  bool get isGroupSuccess => orderStatusEnum == OrderStatus.groupSuccess;
  bool get isEnded => orderStatusEnum == OrderStatus.ended;

  /// 订单显示逻辑
  bool get showGroupSuccessSection =>
      isGroupSuccess || isWon;

  // 是否实物订单
  bool get isPhysical => virtual == 1;
  // 是否虚拟订单
  bool get isVirtual => virtual == 2;

  /// 奖励状态语义
  bool get isRewardClaim => confirmState == 2;
  bool get isRewardCashOut => confirmState == 3;
  bool get isRewardPending => confirmState == 1;


  /// 处理状态语义
  bool get isHandlePending => handleStatus == 1;
  bool get isHandleConfirmed => handleStatus == 2;
  bool get isHandleProcessed => handleStatus == 3;
  bool get isHandleShipped => handleStatus == 4;
  bool get isHandleDelivered => handleStatus == 5;
  bool get isHandleCanceled => handleStatus == 6;

  /// 物流状态语义
  bool get isShipping => currentStatus == 3 || currentStatus == 4;
  bool get isCurrentDelivered => currentStatus == 5;
  bool get isCurrentCanceled => currentStatus == 7;
  bool get isShippingFailed => currentStatus == 6;

  /// 配送方式
  //bool get isSelfPickup => deliveryWay== 1;
  //bool get isExpress => deliveryWay == 2;

  /// 合并（强业务逻辑）
  //bool get shouldShowTracking =>
  //    isExpress && isHandleShipped && !isCurrentDelivered;
}