import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable(checked: true)
class Debit {
  @JsonKey(name: 'real_balance')
  final double realBalance;
  @JsonKey(name: 'transaction_no')
  final String transactionNo;

  Debit({required this.realBalance, required this.transactionNo});

  factory Debit.fromJson(Map<String, dynamic> json) => _$DebitFromJson(json);

  Map<String, dynamic> toJson() => _$DebitToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
