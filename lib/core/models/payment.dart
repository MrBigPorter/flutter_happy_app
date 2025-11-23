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
  final String treasureId;
  final int entries;
  final String? groupId;
  final String? couponId;
  final int paymentMethod;
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
  final String orderId;
  final String orderNo;
  final String? groupId;
  final List<String> lotteryTickets;
  final int activityCoin;
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




