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

CreateRechargeDto _$CreateRechargeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CreateRechargeDto', json, ($checkedConvert) {
      final val = CreateRechargeDto(
        amount: $checkedConvert('amount', (v) => v as num),
        channelCode: $checkedConvert(
          'channelCode',
          (v) => (v as num?)?.toInt(),
        ),
        paymentMethod: $checkedConvert(
          'paymentMethod',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CreateRechargeDtoToJson(CreateRechargeDto instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'channelCode': instance.channelCode,
      'paymentMethod': instance.paymentMethod,
    };

RechargeResponse _$RechargeResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RechargeResponse', json, ($checkedConvert) {
      final val = RechargeResponse(
        rechargeNo: $checkedConvert('rechargeNo', (v) => v as String),
        rechargeAmount: $checkedConvert('rechargeAmount', (v) => v as String),
        payUrl: $checkedConvert('payUrl', (v) => v as String),
        rechargeStatus: $checkedConvert(
          'rechargeStatus',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$RechargeResponseToJson(RechargeResponse instance) =>
    <String, dynamic>{
      'rechargeNo': instance.rechargeNo,
      'rechargeAmount': instance.rechargeAmount,
      'payUrl': instance.payUrl,
      'rechargeStatus': instance.rechargeStatus,
    };
