// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debit _$DebitFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Debit',
  json,
  ($checkedConvert) {
    final val = Debit(
      realBalance: $checkedConvert(
        'real_balance',
        (v) => (v as num).toDouble(),
      ),
      transactionNo: $checkedConvert('transaction_no', (v) => v as String),
    );
    return val;
  },
  fieldKeyMap: const {
    'realBalance': 'real_balance',
    'transactionNo': 'transaction_no',
  },
);

Map<String, dynamic> _$DebitToJson(Debit instance) => <String, dynamic>{
  'real_balance': instance.realBalance,
  'transaction_no': instance.transactionNo,
};
