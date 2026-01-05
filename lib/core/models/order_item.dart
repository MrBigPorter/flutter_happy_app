import 'package:json_annotation/json_annotation.dart';

import 'address_res.dart';

part 'order_item.g.dart';

@JsonSerializable(checked: true)
class OrderItem {
  final String orderId;
  final String orderNo;
  final num? createdAt;
  final num? updatedAt;
  final num buyQuantity;
  final String treasureId;

  // 金额字段
  final String unitPrice;
  final String originalAmount;
  final String? discountAmount; // 改为可空，兼容旧数据
  final String? couponAmount;   // 改为可空
  final String? coinAmount;     // 改为可空
  final String finalAmount;

  // 状态字段
  final int orderStatus;
  final int payStatus;
  final int refundStatus;
  final num? paidAt;

  // 关联对象
  final Treasure treasure;
  final Group? group;
  final String? addressId;
  final AddressRes? addressResp;
  final List<TicketItem>? ticketList;

  // --- 🔥 新增/增强字段 (兼容性处理) ---

  // 1. 售后原因
  final String? refundReason;

  // 2. 中奖标识 (后端未返回时默认为 false，防止报错)
  @JsonKey(defaultValue: false)
  final bool isWinner;

  // 3. 奖品信息 (中奖才有)
  final String? prizeAmount;
  final int? prizeCoin;

  const OrderItem({
    required this.orderId,
    required this.orderNo,
    this.createdAt,
    this.updatedAt,
    required this.buyQuantity,
    required this.treasureId,
    required this.unitPrice,
    required this.originalAmount,
    this.discountAmount,
    this.couponAmount,
    this.coinAmount,
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
    // 新增字段初始化
    this.isWinner = false,
    this.prizeAmount,
    this.prizeCoin,
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
class OrderDetailItem extends OrderItem {

  // 详情页流水 (若后端未返回，默认为空数组)
  @JsonKey(defaultValue: [])
  final List<WalletTransaction> transactions;

  OrderDetailItem({
    required super.orderId,
    required super.orderNo,
    super.createdAt,
    super.updatedAt,
    required super.buyQuantity,
    required super.treasureId,
    required super.unitPrice,
    required super.originalAmount,
    super.discountAmount,
    super.couponAmount,
    super.coinAmount,
    required super.finalAmount,
    required super.orderStatus,
    required super.payStatus,
    required super.refundStatus,
    required super.treasure,
    super.paidAt,
    super.addressId,
    super.addressResp,
    super.ticketList,
    super.refundReason,
    super.group,
    super.isWinner = false,
    super.prizeAmount,
    super.prizeCoin,
    required this.transactions,
  });

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$OrderDetailItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class Treasure {
  final String treasureName;
  final String treasureCoverImg;
  final String? productName;
  final int virtual;
  final String? cashAmount;
  final int? cashState;

  // 进度条相关，使用 num 兼容 int 和 double
  final num? seqShelvesQuantity;
  final num? seqBuyQuantity;

  const Treasure({
    required this.treasureName,
    required this.treasureCoverImg,
    this.productName,
    required this.virtual,
    this.cashAmount,
    this.cashState,
    this.seqShelvesQuantity,
    this.seqBuyQuantity,
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
class WalletTransaction {
  final String transactionNo;
  final String amount;

  // 🔥 改为 dynamic，兼容后端返回 int 或 string
  // 前端显示时建议用 .toString()
  final dynamic balanceType;

  final int status;
  final num createdAt;

  WalletTransaction({
    required this.transactionNo,
    required this.amount,
    required this.balanceType,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

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

  Map<String, int> asMap() {
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

// -----------------------------------------------------------------------------
// 状态枚举与扩展逻辑
// -----------------------------------------------------------------------------

enum OrderStatus {
  pending,       // 1: 未开奖/进行中
  won,           // 2: 用户中奖
  refunded,      // 4: 已退款
  groupSuccess,  // 6: 拼团达成
  ended,         // 其他: 已结束未中奖/已取消
}

extension OrderItemExtension on OrderItem {

  /// 智能状态解析 (兼容新旧字段)
  OrderStatus get orderStatusEnum {
    // 1. 优先信赖明确的 isWinner 字段
    if (isWinner) return OrderStatus.won;

    // 2. 其次检查状态码 (兼容旧后端)
    if (orderStatus == 2) return OrderStatus.won;

    // 3. 检查退款
    if (refundStatus == 2 || orderStatus == 4) return OrderStatus.refunded;

    // 4. 检查拼团
    // 假设 groupStatus: 2 是成功
    if (group?.groupStatus == 2) return OrderStatus.groupSuccess;

    // 5. 默认状态
    return OrderStatus.pending;
  }

  bool get isPending => orderStatusEnum == OrderStatus.pending;
  bool get isWon => orderStatusEnum == OrderStatus.won;
  bool get isRefunded => orderStatusEnum == OrderStatus.refunded;
  bool get isGroupSuccess => orderStatusEnum == OrderStatus.groupSuccess;

  // 这里可以根据实际 ended 状态码调整，比如 status 3 or 5
  bool get isEnded => orderStatusEnum == OrderStatus.ended;

  /// 订单 UI 显示逻辑
  /// 是否显示金色的“中奖/拼团成功”板块
  bool get showGroupSuccessSection => isGroupSuccess || isWon;

  // 是否实物订单
  bool get isPhysical => treasure.virtual == 1;
  // 是否虚拟订单
  bool get isVirtual => treasure.virtual == 2;
}