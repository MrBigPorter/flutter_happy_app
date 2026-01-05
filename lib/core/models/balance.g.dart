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

WalletTransactionsDto _$WalletTransactionsDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletTransactionsDto', json, ($checkedConvert) {
  final val = WalletTransactionsDto(
    page: $checkedConvert('page', (v) => (v as num).toInt()),
    pageSize: $checkedConvert('pageSize', (v) => (v as num).toInt()),
    balanceType: $checkedConvert('balanceType', (v) => (v as num?)?.toInt()),
    transactionType: $checkedConvert(
      'transactionType',
      (v) => (v as num?)?.toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$WalletTransactionsDtoToJson(
  WalletTransactionsDto instance,
) => <String, dynamic>{
  'page': instance.page,
  'pageSize': instance.pageSize,
  'balanceType': instance.balanceType,
  'transactionType': instance.transactionType,
};

WalletTransactionItem _$WalletTransactionItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletTransactionItem', json, ($checkedConvert) {
  final val = WalletTransactionItem(
    transactionNo: $checkedConvert('transactionNo', (v) => v as String),
    transactionType: $checkedConvert(
      'transactionType',
      (v) => (v as num).toInt(),
    ),
    amount: $checkedConvert('amount', (v) => v as String),
    balanceType: $checkedConvert('balanceType', (v) => (v as num).toInt()),
    createdAt: $checkedConvert('createdAt', (v) => v as num),
    relatedId: $checkedConvert('relatedId', (v) => v as String?),
    description: $checkedConvert('description', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$WalletTransactionItemToJson(
  WalletTransactionItem instance,
) => <String, dynamic>{
  'transactionNo': instance.transactionNo,
  'transactionType': instance.transactionType,
  'amount': instance.amount,
  'balanceType': instance.balanceType,
  'createdAt': instance.createdAt,
  'relatedId': instance.relatedId,
  'description': instance.description,
};

WalletWithdrawApplyDto _$WalletWithdrawApplyDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletWithdrawApplyDto', json, ($checkedConvert) {
  final val = WalletWithdrawApplyDto(
    amount: $checkedConvert('amount', (v) => v as num),
    withdrawMethod: $checkedConvert('withdrawMethod', (v) => v as num),
    account: $checkedConvert('account', (v) => v as String),
    accountName: $checkedConvert('accountName', (v) => v as String),
    bankName: $checkedConvert('bankName', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$WalletWithdrawApplyDtoToJson(
  WalletWithdrawApplyDto instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'withdrawMethod': instance.withdrawMethod,
  'account': instance.account,
  'accountName': instance.accountName,
  'bankName': instance.bankName,
};

WalletWithdrawResponse _$WalletWithdrawResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletWithdrawResponse', json, ($checkedConvert) {
  final val = WalletWithdrawResponse(
    withdrawId: $checkedConvert('withdrawId', (v) => v as String),
    withdrawNo: $checkedConvert('withdrawNo', (v) => v as String),
    withdrawAmount: $checkedConvert('withdrawAmount', (v) => v as String),
    withdrawStatus: $checkedConvert(
      'withdrawStatus',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
});

Map<String, dynamic> _$WalletWithdrawResponseToJson(
  WalletWithdrawResponse instance,
) => <String, dynamic>{
  'withdrawId': instance.withdrawId,
  'withdrawNo': instance.withdrawNo,
  'withdrawAmount': instance.withdrawAmount,
  'withdrawStatus': instance.withdrawStatus,
};

WalletWithdrawHistoryDto _$WalletWithdrawHistoryDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletWithdrawHistoryDto', json, ($checkedConvert) {
  final val = WalletWithdrawHistoryDto(
    page: $checkedConvert('page', (v) => (v as num).toInt()),
    pageSize: $checkedConvert('pageSize', (v) => (v as num).toInt()),
    status: $checkedConvert('status', (v) => (v as num?)?.toInt()),
  );
  return val;
});

Map<String, dynamic> _$WalletWithdrawHistoryDtoToJson(
  WalletWithdrawHistoryDto instance,
) => <String, dynamic>{
  'page': instance.page,
  'pageSize': instance.pageSize,
  'status': instance.status,
};

WalletWithdrawHistoryItem _$WalletWithdrawHistoryItemFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WalletWithdrawHistoryItem', json, ($checkedConvert) {
  final val = WalletWithdrawHistoryItem(
    withdrawNo: $checkedConvert('withdrawNo', (v) => v as String),
    amount: $checkedConvert('amount', (v) => v as String),
    feeAmount: $checkedConvert('feeAmount', (v) => v as String),
    withdrawStatus: $checkedConvert(
      'withdrawStatus',
      (v) => (v as num).toInt(),
    ),
    createdAt: $checkedConvert('createdAt', (v) => v as num),
    auditedAt: $checkedConvert('auditedAt', (v) => v as num?),
    completedAt: $checkedConvert('completedAt', (v) => v as num?),
    rejectReason: $checkedConvert('rejectReason', (v) => v as String?),
    accountName: $checkedConvert('accountName', (v) => v as String),
    withdrawAccount: $checkedConvert('withdrawAccount', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$WalletWithdrawHistoryItemToJson(
  WalletWithdrawHistoryItem instance,
) => <String, dynamic>{
  'withdrawNo': instance.withdrawNo,
  'amount': instance.amount,
  'feeAmount': instance.feeAmount,
  'withdrawStatus': instance.withdrawStatus,
  'createdAt': instance.createdAt,
  'auditedAt': instance.auditedAt,
  'completedAt': instance.completedAt,
  'rejectReason': instance.rejectReason,
  'accountName': instance.accountName,
  'withdrawAccount': instance.withdrawAccount,
};
