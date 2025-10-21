
import 'package:json_annotation/json_annotation.dart';
part 'coupon_threshold_data.g.dart';

enum CouponStatus {
  uncollected(0),
  collected(1),
  used(2),
  runout(3),
  closed(4);

  final int value;
  const CouponStatus(this.value);


  static CouponStatus fromJson(dynamic value){
    if(value is int){
      return CouponStatus.values.firstWhere((e)=> e.value == value,orElse: ()=> CouponStatus.uncollected);
    }
    return CouponStatus.uncollected;
  }

  static int toJson(CouponStatus? status) => status?.value ?? 0;
}

@JsonSerializable(checked: true)
class CouponThresholdData {
  @JsonKey(name: 'buy_threshold_start')
  final double? buyThresholdStart;
  @JsonKey(name: 'coupon_id')
  final int couponId;
  @JsonKey(name: 'currency')
  final String? currency;
  @JsonKey(name: 'get_coupons')
  final int getCoupons; //1 | 2 | 3; // 1:不可领取 2:可领取 3:已领取
  @JsonKey(name: 'reward_amount')
  final double rewardAmount;
  @JsonKey(name: 'id')
  final String id;
  @JsonKey(name: 'coupon_name')
  final String couponName;
  @JsonKey(
      name: 'coupon_status',
      fromJson:  CouponStatus.fromJson,
      toJson: CouponStatus.toJson,
  )
  final CouponStatus? couponStatus;
  @JsonKey(name: 'treasure_id')
  final int? treasureId;
  @JsonKey(name: 'use_at_end')
  final int? useAtEnd;
  @JsonKey(name: 'use_at_start')
  final int? useAtStart;
  @JsonKey(name: 'threshold_start')
  final double? thresholdStart;

  const CouponThresholdData({
    required this.couponId,
    required this.getCoupons,
    required this.rewardAmount,
    required this.id,
    required this.couponName,
    required this.couponStatus,
    required this.treasureId,
    required this.useAtEnd,
    required this.useAtStart,
     this.thresholdStart,
    this.buyThresholdStart,
    this.currency,

  });

  factory CouponThresholdData.fromJson(Map<String, dynamic> json) => _$CouponThresholdDataFromJson(json);

  Map<String, dynamic> toJson() => _$CouponThresholdDataToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class CouponThresholdResponse {
  @JsonKey(name: 'coupon_threshold')
  final List<CouponThresholdData> couponThreshold;
  @JsonKey(name: 'desc')
  final String desc;
  const CouponThresholdResponse({
    required this.couponThreshold,
    required this.desc,
  });

  factory CouponThresholdResponse.fromJson(Map<String, dynamic> json) => _$CouponThresholdResponseFromJson(json);
}