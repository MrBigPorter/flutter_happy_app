import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

typedef PagePaymentParams = ({
  String? entries,
  String? treasureId,
  String? paymentMethod,
  String? groupId,
});

@JsonSerializable(checked: true)
class OrdersCheckoutParams {
  @JsonKey(name: 'treasure_id')
  final String treasureId;
  @JsonKey(name: 'entries')
  final int entries;
  @JsonKey(name: 'group_id')
  final String? groupId;
  @JsonKey(name: 'coupon_id')
  final String? couponId;
  @JsonKey(name: 'payment_method')
  final int paymentMethod;
  @JsonKey(name: 'address_id')
  final String? addressId;

  OrdersCheckoutParams({
    required this.treasureId,
    required this.entries,
    this.groupId,
    this.couponId,
    required this.paymentMethod,
    this.addressId,
  });

  factory OrdersCheckoutParams.fromJson(Map<String, dynamic> json) =>
      _$OrdersCheckoutParamsFromJson(json);

  Map<String, dynamic> toJson() => _$OrdersCheckoutParamsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class OrderCheckoutResponse {
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'order_no')
  final String orderNo;
  @JsonKey(name: 'group_id')
  final String? groupId;
  @JsonKey(name: 'lottery_tickets')
  final List<String> lotteryTickets;
  @JsonKey(name: 'activity_coin')
  final int activityCoin;
  @JsonKey(name: 'treasure_id')
  final String? treasureId;

  OrderCheckoutResponse({
    required this.orderId,
    required this.orderNo,
    required this.groupId,
    required this.lotteryTickets,
    required this.activityCoin,
    required this.treasureId,
  });


  factory OrderCheckoutResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderCheckoutResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCheckoutResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}




