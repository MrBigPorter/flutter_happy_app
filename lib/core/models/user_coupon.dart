import 'package:json_annotation/json_annotation.dart';

part 'user_coupon.g.dart';

@JsonSerializable(checked: true)
class UserCoupon {
  /// 用户领取的这张券的唯一 ID (支付时传这个)
  final String userCouponId;

  /// 状态: 0-未使用, 1-已使用, 2-已过期
  @JsonKey(defaultValue: 0)
  final int status;

  /// 有效期开始时间戳 (毫秒)
  final int validStartAt;

  /// 有效期结束时间戳 (毫秒)
  final int validEndAt;

  // --- 以下是后端扁平化吐出来的模板属性 ---

  /// 优惠券名称
  @JsonKey(defaultValue: '')
  final String couponName;

  /// 券类型: 1-满减券 2-折扣券 3-无门槛
  @JsonKey(defaultValue: 1)
  final int couponType;

  /// 抵扣数值 (String类型，防止精度丢失)
  @JsonKey(defaultValue: '0.00')
  final String discountValue;

  /// 最低消费门槛
  @JsonKey(defaultValue: '0.00')
  final String minPurchase;

  /// 使用规则描述
  final String? ruleDesc;

  UserCoupon({
    required this.userCouponId,
    required this.status,
    required this.validStartAt,
    required this.validEndAt,
    required this.couponName,
    required this.couponType,
    required this.discountValue,
    required this.minPurchase,
    this.ruleDesc,
  });

  factory UserCoupon.fromJson(Map<String, dynamic> json) =>
      _$UserCouponFromJson(json);

  Map<String, dynamic> toJson() => _$UserCouponToJson(this);
}

@JsonSerializable(checked: true)
class ClaimableCoupon {
  final String couponId;
  final String couponName;
  final int couponType;
  final String discountValue;
  final String minPurchase;
  final int totalQuantity;
  final int issuedQuantity;

  /// 进度百分比 (例如 "80" 代表 80%)
  final String progress;

  /// 是否可以领取 (综合判断了库存和个人限领)
  final bool canClaim;

  /// 是否已经达到个人领取上限
  final bool hasReachedLimit;

  ClaimableCoupon({
    required this.couponId,
    required this.couponName,
    required this.couponType,
    required this.discountValue,
    required this.minPurchase,
    required this.totalQuantity,
    required this.issuedQuantity,
    required this.progress,
    required this.canClaim,
    required this.hasReachedLimit,
  });

  factory ClaimableCoupon.fromJson(Map<String, dynamic> json) => _$ClaimableCouponFromJson(json);
  Map<String, dynamic> toJson() => _$ClaimableCouponToJson(this);
}