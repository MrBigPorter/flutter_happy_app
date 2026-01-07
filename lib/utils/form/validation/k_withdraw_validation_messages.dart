import 'package:reactive_forms/reactive_forms.dart';

final Map<String, ValidationMessageFunction> kWithdrawValidationMessages = {
  // === 1. 基础验证 (General) ===
  ValidationMessage.required: (_) => 'This field is required.',
  ValidationMessage.number: (_) => 'Please enter a valid amount.',

  // === 2. 金额校验 (Amount - 对应 WithdrawAmountValidator) ===
  'amount': (error) {
    final err = error as Map<String, dynamic>;
    final reason = err['reason'];
    final min = err['min'];
    final max = err['max'];
    final balance = err['balance'];
    final fee = err['fee'];
    final limit = err['limit'];

    switch (reason) {
      case 'invalid':
        return 'Please enter a valid amount.';
      case 'min':
        return 'Minimum withdrawal is ₱$min.';
      case 'max':
        return 'Maximum withdrawal is ₱$max per transaction.';
      case 'insufficient':
        return 'Insufficient balance. Available: ₱$balance';
      case 'too_low_for_fee':
        return 'Amount must be greater than the service fee (₱$fee).';
      case 'daily_limit':
        return 'Daily withdrawal limit reached. Remaining: ₱$limit';
      case 'min_keep':
        return 'Minimum account balance of ₱${err['min_keep']} must be maintained.';
      default:
        return 'Invalid withdrawal amount.';
    }
  },


  // 银行卡/电子钱包格式校验
  'accountNumber': (error) {
    final err = error as Map<String, dynamic>;
    if (err['reason'] == 'format') return 'Invalid account number format.';
    return 'Please enter a valid account number.';
  },

  // 姓名格式校验
  'accountName': (error) {
    final err = error as Map<String, dynamic>;
    if (err['reason'] == 'format') return 'Invalid name format.';
    return 'Please enter a valid name.';
  },


};