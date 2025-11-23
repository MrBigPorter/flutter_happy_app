
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
  final double? buyThresholdStart;
  final int couponId;
  final String? currency;
  final int getCoupons; //1 | 2 | 3; // 1:不可领取 2:可领取 3:已领取
  final double rewardAmount;
  final String id;
  final String couponName;
  @JsonKey(
      fromJson:  CouponStatus.fromJson,
      toJson: CouponStatus.toJson,
  )
  final CouponStatus? couponStatus;
  final int? treasureId;
  final int? useAtEnd;
  final int? useAtStart;
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
  final List<CouponThresholdData> couponThreshold;
  final String desc;
  const CouponThresholdResponse({
    required this.couponThreshold,
    required this.desc,
  });

  factory CouponThresholdResponse.fromJson(Map<String, dynamic> json) => _$CouponThresholdResponseFromJson(json);
}