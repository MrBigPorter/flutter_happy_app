import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

// 1. 路由参数定义 (接收 URL Query 参数)
typedef PagePaymentParams = ({
String? entries,
String? treasureId,
String? paymentMethod,
String? groupId,
//  新增：用于区分 "单独购买" 还是 "拼团购买"
// 因为 "发起拼团" 时 groupId 为空，必须靠这个字段区分
String? isGroupBuy,
});

// 2. 提交订单参数 (发给后端)
@JsonSerializable(checked: true)
class OrdersCheckoutParams {
  final String treasureId;
  final int entries;
  final String? groupId;
  final String? couponId;
  final int paymentMethod;
  final String? addressId;

  //  新增：告诉后端是否为拼团订单 (影响价格计算)
  // true = 拼团 (开团或参团)
  // false/null = 单独购买
  final bool? isGroup;

  OrdersCheckoutParams({
    required this.treasureId,
    required this.entries,
    this.groupId,
    this.couponId,
    required this.paymentMethod,
    this.addressId,
    this.isGroup, //  构造函数加入
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