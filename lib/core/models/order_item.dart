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
  final String? discountAmount;
  final String? couponAmount;
  final String? coinAmount;
  final String finalAmount;

  // 状态字段 (对应后端 int 值)
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


  // 1. 售后原因
  final String? refundReason;
  final String? refundRejectReason;

  // 2. 中奖标识 (后端未返回时默认为 false)
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
    this.isWinner = false,
    this.prizeAmount,
    this.prizeCoin,
    this.refundRejectReason
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
  final String? blurhash;
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
    this.blurhash,
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

  // 兼容后端返回 int 或 string
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

/// 对应后端 LotteryResultDto：每次开奖的中奖记录
@JsonSerializable(checked: true)
class LotteryResult {
  final String winnerId;
  final String winnerOrderId;

  const LotteryResult({
    required this.winnerId,
    required this.winnerOrderId,
  });

  factory LotteryResult.fromJson(Map<String, dynamic> json) =>
      _$LotteryResultFromJson(json);

  Map<String, dynamic> toJson() => _$LotteryResultToJson(this);
}

@JsonSerializable(checked: true)
class Group {
  final String groupId;
  final int groupStatus;
  final int currentMembers;
  final int maxMembers;

  /// 开奖时间戳（毫秒）。null = 尚未开奖
  final num? drawnAt;

  /// 开奖结果列表。为空表示尚未开奖
  @JsonKey(defaultValue: [])
  final List<LotteryResult> lotteryResults;

  Group({
    required this.groupId,
    required this.groupStatus,
    required this.currentMembers,
    required this.maxMembers,
    this.drawnAt,
    this.lotteryResults = const [],
  });

  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
  Map<String, dynamic> toJson() => _$GroupToJson(this);

  @override
  String toString() => toJson().toString();

  /// 该团已开奖
  bool get isDrawn => drawnAt != null;

  /// 该团是否成功成团
  bool get isSuccess => groupStatus == 2;

  /// 返回中奖订单 ID（没有则 null）
  String? get winnerOrderId =>
      lotteryResults.isNotEmpty ? lotteryResults.first.winnerOrderId : null;
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

  factory OrderListParams.fromJson(Map<String, dynamic> json) =>
      _$OrderListParamsFromJson(json);

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
// 1. 后端常量定义 (Backend Constants)
// -----------------------------------------------------------------------------

class OrderStatusConst {
  static const int pendingPayment = 1;    // 待支付
  static const int processingPayment = 2; // 支付中
  static const int paid = 3;              // 已支付 (待开奖)
  static const int canceled = 4;          // 已取消
  static const int refunded = 5;          // 已退款
  static const int groupFormed = 6;       // 成团待开奖
  static const int drawn = 7;             // 已开奖
  static const int completed = 8;         // 已完成（奖品已发）
  static const int drawClosed = 9;        // 开奖完结（非中奖关闭）
}

class PayStatusConst {
  static const int unpaid = 0;
  static const int paid = 1;
  static const int failed = 2;
}

class RefundStatusConst {
  static const int noRefund = 0;    // 未退款
  static const int refunding = 1;   // 退款中
  static const int refunded = 2;    // 已退款
  static const int refundFailed = 3; // 退款失败
}

// -----------------------------------------------------------------------------
// 2. 前端 UI 状态枚举 (UI Layer)
// -----------------------------------------------------------------------------
enum OrderStatus {
  pending,       // 待支付
  processing,    // 支付中
  paid,          // 已支付/进行中
  won,           // 用户中奖 (高光状态)
  refunded,      // 已退款
  cancelled,     // 已取消
  groupSuccess,  // 拼团成功（成团待开奖）
  ended,         // 已结束未中奖
}

// -----------------------------------------------------------------------------
// 3. 业务扩展逻辑 (Business Logic)
// -----------------------------------------------------------------------------
extension OrderItemExtension on OrderItem {

  /// 通过 group.lotteryResults 判断本订单是否中奖（比 isWinner 字段更准确）
  bool get didIWinByGroup =>
      group?.lotteryResults.any((r) => r.winnerOrderId == orderId) ?? false;

  /// 该团是否已开奖
  bool get isGroupDrawn => group?.isDrawn ?? false;

  /// 开奖时间（毫秒时间戳）
  num? get drawnAt => group?.drawnAt;

  /// 当前订单是否已进入开奖后的最终态
  bool get isDrawResolved => isWon || isEnded;

  /// 智能状态解析
  OrderStatus get orderStatusEnum {
    // 1. 优先判断退款（无论什么阶段退款都是最终态之一）
    if (orderStatus == OrderStatusConst.refunded ||
        refundStatus == RefundStatusConst.refunded) {
      return OrderStatus.refunded;
    }

    // 2. 取消
    if (orderStatus == OrderStatusConst.canceled) {
      return OrderStatus.cancelled;
    }

    // 3. 已开奖状态（7 / 8 / 9）：用 lotteryResults + isWinner 双重判断
    final isDrawnStatus = orderStatus == OrderStatusConst.drawn ||
        orderStatus == OrderStatusConst.completed ||
        orderStatus == OrderStatusConst.drawClosed;
    if (isDrawnStatus || isGroupDrawn) {
      if (didIWinByGroup || isWinner) return OrderStatus.won;
      return OrderStatus.ended; // 已开奖但未中
    }

    // 4. 成团待开奖（6）
    if (orderStatus == OrderStatusConst.groupFormed ||
        group?.groupStatus == 2) {
      return OrderStatus.groupSuccess;
    }

    // 5. 基础状态映射
    switch (orderStatus) {
      case OrderStatusConst.pendingPayment:
        return OrderStatus.pending;
      case OrderStatusConst.processingPayment:
        return OrderStatus.processing;
      case OrderStatusConst.paid:
        return OrderStatus.paid;
      default:
        return OrderStatus.pending;
    }
  }

  // --- 便捷 Getter ---
  bool get isPending => orderStatusEnum == OrderStatus.pending;
  bool get isWon => orderStatusEnum == OrderStatus.won;
  bool get isRefunded => orderStatusEnum == OrderStatus.refunded;
  bool get isGroupSuccess => orderStatusEnum == OrderStatus.groupSuccess;
  bool get isCancelled => orderStatusEnum == OrderStatus.cancelled;
  bool get isEnded => orderStatusEnum == OrderStatus.ended;

  // --- UI 逻辑 ---
  bool get showGroupSuccessSection => isGroupSuccess || isWon || isEnded;
  bool get isPhysical => treasure.virtual == 1;
  bool get isVirtual => treasure.virtual == 2;

  /// --- 核心业务：能否申请退款？---
  /// 规则：
  /// 1. 订单状态必须是 PAID(3) 或 GROUP_FORMED(6)（开奖前都可退）
  /// 2. 支付状态必须是 PAID (1)
  /// 3. 退款状态必须是 NO_REFUND (0) 或 REFUND_FAILED (3)
  /// 4. 不是中奖订单
  bool get canRequestRefund {
    final isRefundableStatus = orderStatus == OrderStatusConst.paid ||
        orderStatus == OrderStatusConst.groupFormed;
    final isPaySuccess = payStatus == PayStatusConst.paid;
    final isNoRefund = refundStatus == RefundStatusConst.noRefund ||
        refundStatus == RefundStatusConst.refundFailed;

    return isRefundableStatus && isPaySuccess && isNoRefund && !isWon;
  }
}

@JsonSerializable(createFactory: false)
class RefundApplyReq {
  final String orderId;
  final String reason;

  RefundApplyReq({
    required this.orderId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => _$RefundApplyReqToJson(this);
}

@JsonSerializable(checked: true)
class RefundOrderResp {
  final String orderId;
  final String orderNo;

  // 使用后端定义的 int 值: 0-无 1-退款中 2-成功 3-失败
  @JsonKey(defaultValue: 0)
  final int refundStatus;

  // 后端返回的是 String 金额
  final String? refundAmount;

  final String? refundReason;

  // 只有被拒绝时才有值
  final String? refundRejectReason;

  final num? refundedAt;

  RefundOrderResp({
    required this.orderId,
    required this.orderNo,
    required this.refundStatus,
    this.refundAmount,
    this.refundReason,
    this.refundRejectReason,
    this.refundedAt,
  });

  factory RefundOrderResp.fromJson(Map<String, dynamic> json) =>
      _$RefundOrderRespFromJson(json);

  Map<String, dynamic> toJson() => _$RefundOrderRespToJson(this);
}