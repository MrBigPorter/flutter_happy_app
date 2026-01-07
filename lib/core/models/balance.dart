import 'package:json_annotation/json_annotation.dart';

import '../json/json_num_converters.dart';

part 'balance.g.dart';

@JsonSerializable(checked: true)
class Balance {
  @JsonKey(
    fromJson: JsonNumConverter.toDouble,
    toJson: JsonNumConverter.doubleToString,
  )
  final double realBalance;
  @JsonKey(
    fromJson: JsonNumConverter.toDouble,
    toJson: JsonNumConverter.doubleToString,
  )
  final double coinBalance;

  Balance({required this.realBalance, required this.coinBalance});

  factory Balance.fromJson(Map<String, dynamic> json) =>
      _$BalanceFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class CreateRechargeDto {
  final num amount;
  final int channelId;

  CreateRechargeDto({
    required this.amount,
    required this.channelId,
  });

  factory CreateRechargeDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRechargeDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRechargeDtoToJson(this);
}

@JsonSerializable(checked: true)
class RechargeResponse {
  final String rechargeNo;
  final String rechargeAmount;
  final String payUrl;
  final int rechargeStatus;

  RechargeResponse({
    required this.rechargeNo,
    required this.rechargeAmount,
    required this.payUrl,
    required this.rechargeStatus,
  });

  factory RechargeResponse.fromJson(Map<String, dynamic> json) =>
      _$RechargeResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RechargeResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

// ==========================================
//  Wallet Transaction (流水/余额变动) - 保持不变
// ==========================================

@JsonSerializable(checked: true)
class WalletTransactionsDto {
  final int page;
  final int pageSize;
  final int? balanceType;
  final int? transactionType;

  WalletTransactionsDto({
    required this.page,
    required this.pageSize,
    this.balanceType,
    this.transactionType,
  });

  factory WalletTransactionsDto.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionsDtoToJson(this);
}

@JsonSerializable(checked: true)
class WalletTransactionItem {
  final String transactionNo;
  final int transactionType;
  final String amount;
  final int balanceType; //1 for Cash, 2 for Coin
  final num createdAt;
  final String? relatedId;
  final String? description;

  WalletTransactionItem({
    required this.transactionNo,
    required this.transactionType,
    required this.amount,
    required this.balanceType,
    required this.createdAt,
    this.relatedId,
    this.description,
  });

  factory WalletTransactionItem.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionItemFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTransactionItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

// ==========================================
//  Withdraw (提现) - 保持不变
// ==========================================

@JsonSerializable(checked: true)
class WalletWithdrawApplyDto {
  final num amount;
  final int channelId;

  final String account;
  final String accountName;
  final String? bankName;

  WalletWithdrawApplyDto({
    required this.amount,
    required this.account,
    required this.accountName,
    required this.channelId,
    this.bankName,
  });

  factory WalletWithdrawApplyDto.fromJson(Map<String, dynamic> json) =>
      _$WalletWithdrawApplyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletWithdrawApplyDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class WalletWithdrawResponse {
  final String withdrawId;
  final String withdrawNo;
  final String withdrawAmount;
  final int withdrawStatus;

  WalletWithdrawResponse({
    required this.withdrawId,
    required this.withdrawNo,
    required this.withdrawAmount,
    required this.withdrawStatus,
  });

  factory WalletWithdrawResponse.fromJson(Map<String, dynamic> json) =>
      _$WalletWithdrawResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WalletWithdrawResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class WalletWithdrawHistoryDto {
  final int page;
  final int pageSize;
  final int? status; // [ 1, 2, 3 ] for [Pending, Approved, Rejected]

  WalletWithdrawHistoryDto({
    required this.page,
    required this.pageSize,
    this.status,
  });

  factory WalletWithdrawHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$WalletWithdrawHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletWithdrawHistoryDtoToJson(this);
}

@JsonSerializable(checked: true)
class WalletWithdrawHistoryItem {
  final String withdrawNo;
  final String amount;
  final String actualAmount;
  final String withdrawAmount;
  final String feeAmount;
  final int withdrawStatus;
  final num createdAt;
  final num? auditedAt;
  final num? completedAt;
  final String? rejectReason;
  final String accountName;
  final String withdrawAccount;

  final String? channelName;
  final String? channelCode;

  WalletWithdrawHistoryItem({
    required this.withdrawNo,
    required this.amount,
    required this.actualAmount,
    required this.withdrawAmount,
    required this.feeAmount,
    required this.withdrawStatus,
    required this.createdAt,
    this.auditedAt,
    this.completedAt,
    this.rejectReason,
    required this.accountName,
    required this.withdrawAccount,
    this.channelName,
    this.channelCode,
  });

  factory WalletWithdrawHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$WalletWithdrawHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$WalletWithdrawHistoryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

// ==========================================
//  Recharge History (充值订单列表) - 新增
// ==========================================

/// 充值记录查询参数
@JsonSerializable(checked: true)
class WalletRechargeHistoryDto {
  final int page;
  final int pageSize;

  /// 状态筛选: 1-Pending, 2-Processing, 3-Success, 4-Failed, 5-Canceled
  final int? status;

  WalletRechargeHistoryDto({
    required this.page,
    required this.pageSize,
    this.status,
  });

  factory WalletRechargeHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$WalletRechargeHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WalletRechargeHistoryDtoToJson(this);
}

/// 充值订单项
@JsonSerializable(checked: true)
class WalletRechargeHistoryItem {
  final String rechargeNo;

  /// 充值金额 (后端返回 String)
  final String rechargeAmount;

  /// 实际到账金额 (后端返回 String)
  final String actualAmount;

  /// 状态: 1-Pending, 2-Processing, 3-Success, 4-Failed, 5-Canceled
  final int rechargeStatus;

  /// 支付方式: 1-GCash 2-PayMaya...
  final int paymentMethod;
  final String? paymentChannel;

  final num createdAt;
  final num? paidAt;
  final String? channelName;
  final String? channelCode;


  WalletRechargeHistoryItem({
    required this.rechargeNo,
    required this.rechargeAmount,
    required this.actualAmount,
    required this.rechargeStatus,
    required this.paymentMethod,
    required this.createdAt,
    this.paidAt,
    this.channelName,
    this.channelCode,
    this.paymentChannel,
  });

  factory WalletRechargeHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$WalletRechargeHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$WalletRechargeHistoryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

// ==========================================
//  Payment Channel Config (收银台配置) - 新增
// ==========================================

@JsonSerializable(checked: true)
class PaymentChannelConfigItem {
  /// 渠道ID (下单传此ID)
  final int id;

  /// 渠道编码 (e.g. PH_GCASH, PH_BDO)
  final String code;

  /// 渠道名称 (e.g. GCash)
  final String name;

  /// 图标 URL
  final String? icon;

  /// 单笔最小限额
  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double minAmount;

  /// 单笔最大限额
  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double maxAmount;

  /// 快捷金额卡片 (仅充值有效, e.g. [100, 200, 500])
  final List<num>? fixedAmounts;

  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double feeRate;

  @JsonKey(fromJson: JsonNumConverter.toDouble)
  final double feeFixed;

  /// 是否允许输入自定义金额
  final bool isCustom;

  PaymentChannelConfigItem({
    required this.id,
    required this.code,
    required this.name,
     this.icon,
    required this.minAmount,
    required this.maxAmount,
    required this.feeRate,
    required this.feeFixed,
    this.fixedAmounts,
    required this.isCustom,
  });

  factory PaymentChannelConfigItem.fromJson(Map<String, dynamic> json) =>
      _$PaymentChannelConfigItemFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentChannelConfigItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}