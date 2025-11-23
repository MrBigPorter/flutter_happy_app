// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Balance _$BalanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Balance', json, ($checkedConvert) {
      final val = Balance(
        realBalance: $checkedConvert(
          'realBalance',
          (v) => JsonNumConverter.toDouble(v),
        ),
        coinBalance: $checkedConvert(
          'coinBalance',
          (v) => JsonNumConverter.toDouble(v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BalanceToJson(Balance instance) => <String, dynamic>{
  'realBalance': JsonNumConverter.doubleToString(instance.realBalance),
  'coinBalance': JsonNumConverter.doubleToString(instance.coinBalance),
};
