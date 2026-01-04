import 'package:json_annotation/json_annotation.dart';

import '../json/json_num_converters.dart';

part 'balance.g.dart';

@JsonSerializable(checked: true)
class Balance {
  @JsonKey(fromJson: JsonNumConverter.toDouble,toJson: JsonNumConverter.doubleToString)
  final double realBalance;
  @JsonKey(fromJson: JsonNumConverter.toDouble,toJson: JsonNumConverter.doubleToString)
  final double coinBalance;

  Balance({
    required this.realBalance,
    required this.coinBalance,
  });

   factory Balance.fromJson(Map<String, dynamic> json) => _$BalanceFromJson(json);

  Map<String, dynamic> toJson() => _$BalanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }


}

@JsonSerializable(checked: true)
class CreateRechargeDto{
   final num amount;
   final int? channelCode;
   final int? paymentMethod;

   CreateRechargeDto({
      required this.amount,
      this.channelCode,
      this.paymentMethod,
    });

    factory CreateRechargeDto.fromJson(Map<String, dynamic> json) => _$CreateRechargeDtoFromJson(json);
    Map<String, dynamic> toJson() => _$CreateRechargeDtoToJson(this);
}

@JsonSerializable(checked: true)
class RechargeResponse{
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

    factory RechargeResponse.fromJson(Map<String, dynamic> json) => _$RechargeResponseFromJson(json);
    Map<String, dynamic> toJson() => _$RechargeResponseToJson(this);

    @override
    String toString() {
      return toJson().toString();
    }
}