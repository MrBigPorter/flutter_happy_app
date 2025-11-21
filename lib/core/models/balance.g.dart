// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Balance _$BalanceFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Balance',
  json,
  ($checkedConvert) {
    final val = Balance(
      realBalance: $checkedConvert(
        'real_balance',
        (v) => JsonNumConverter.toDouble(v),
      ),
      coinBalance: $checkedConvert(
        'coin_balance',
        (v) => JsonNumConverter.toDouble(v),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'realBalance': 'real_balance',
    'coinBalance': 'coin_balance',
  },
);

Map<String, dynamic> _$BalanceToJson(Balance instance) => <String, dynamic>{
  'real_balance': JsonNumConverter.doubleToString(instance.realBalance),
  'coin_balance': JsonNumConverter.doubleToString(instance.coinBalance),
};
