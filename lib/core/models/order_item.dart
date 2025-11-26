import 'package:json_annotation/json_annotation.dart';

import 'address_res.dart';

part 'order_item.g.dart';

@JsonSerializable(checked: true)
class OrderItem {
  final String orderId;
  final String orderNo;
  final num? createAt;
  final num? updateAt;
  final num buyQuantity;
  final num? stockQuantity;
  final String treasureId;
  final String unitPrice;
  final String originalAmount;
  final String discountAmount;
  final String couponAmount;
  final String coinAmount;
  final String finalAmount;
  final int orderStatus;
  final int payStatus;
  final int refundStatus;
  final num? paidAt;
  final Treasure treasure;
  final Group? group;


  final String? addressId;
  final AddressRes? addressResp;
  final List<TicketItem>? ticketList;
  final String? refundReason;

  const OrderItem( {
    required this.orderId,
    required this.orderNo,
     this.createAt,
     this.updateAt,
    required this.buyQuantity,
     this.stockQuantity,
    required this.treasureId,
    required this.unitPrice,
    required this.originalAmount,
    required this.discountAmount,
    required this.couponAmount,
    required this.coinAmount,
    required this.finalAmount,
    required this.orderStatus,
    required this.payStatus,
    required this.refundStatus,
    required this.treasure,
    this.paidAt,
    this.addressId,
    this.addressResp,
    this.ticketList,
    this.refundReason,
    this.group,
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
class Treasure {
  final String treasureName;
  final String treasureCoverImg;
  final String productName;
  final int virtual;
  final String? cashAmount;
  final int? cashState;

  const Treasure({
    required this.treasureName,
    required this.treasureCoverImg,
    required this.productName,
    required this.virtual,
     this.cashAmount,
     this.cashState,
  });

  factory Treasure.fromJson(Map<String, dynamic> json) =>
      _$TreasureFromJson(json);

  Map<String, dynamic> toJson() => _$TreasureToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Group {
  final String groupId;
  final int groupStatus;
  final int currentMembers;
  final int maxMembers;

  Group({
    required this.groupId,
    required this.groupStatus,
    required this.currentMembers,
    required this.maxMembers,
  });

  factory Group.fromJson(Map<String, dynamic> json) =>
      _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

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
  final int paid;
  final int unpaid;
  final int refunded;
  final int cancelled;

  const OrderCount({
    required this.paid,
    required this.unpaid,
    required this.refunded,
    required this.cancelled,
  });

  Map<String,int> asMap() {
    return {
      'paid': paid,
      'unpaid': unpaid,
      'refunded': refunded,
      'cancelled': cancelled,
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
  final String status;
  final String? treasureId;
  final int page;
  final int pageSize;

  const OrderListParams({
    required this.page,
    required this.pageSize,
    required this.status,
    this.treasureId,
  });


  Map<String, dynamic> toJson() => _$OrderListParamsToJson(this);

}

/// model for tab item in order screen
class TabItem {
  final String name;
  final int total;
  final String key;

  TabItem({required this.name, required this.total, required this.key});

  TabItem copyWith({
    String? name,
    int? value,
    int? total,
    String? key,
  }) {
    return TabItem(
      name: name ?? this.name,
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
  bool get isPhysical => treasure?.virtual == 1;
  // 是否虚拟订单
  bool get isVirtual => treasure?.virtual == 2;

  /// 奖励状态语义
/*  bool get isRewardClaim => confirmState == 2;
  bool get isRewardCashOut => confirmState == 3;
  bool get isRewardPending => confirmState == 1;*/


  /// 处理状态语义
/*  bool get isHandlePending => handleStatus == 1;
  bool get isHandleConfirmed => handleStatus == 2;
  bool get isHandleProcessed => handleStatus == 3;
  bool get isHandleShipped => handleStatus == 4;
  bool get isHandleDelivered => handleStatus == 5;
  bool get isHandleCanceled => handleStatus == 6;*/

  /// 物流状态语义
/*  bool get isShipping => currentStatus == 3 || currentStatus == 4;
  bool get isCurrentDelivered => currentStatus == 5;
  bool get isCurrentCanceled => currentStatus == 7;
  bool get isShippingFailed => currentStatus == 6;*/

  /// 配送方式
  //bool get isSelfPickup => deliveryWay== 1;
  //bool get isExpress => deliveryWay == 2;

  /// 合并（强业务逻辑）
  //bool get shouldShowTracking =>
  //    isExpress && isHandleShipped && !isCurrentDelivered;
}