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