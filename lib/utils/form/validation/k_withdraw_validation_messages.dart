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

 /* // === 3. 账户与渠道 (Account & Channel) ===
  'withdrawMethod': (_) => 'Please select a withdrawal method.',

  // 银行卡/电子钱包格式校验
  'accountNo': (error) {
    final err = error as Map<String, dynamic>;
    if (err['reason'] == 'format') return 'Invalid account number format.';
    return 'Please enter a valid account number.';
  },

  // 姓名匹配校验 (防洗钱核心)
  'accountNameMatch': (_) => 'Account name must match your verified identity name.',

  // 银行/分行信息
  'bankName': (_) => 'Please select your bank.',
  'branchName': (_) => 'Please enter the branch information.',

  // === 4. 安全验证 (Security) ===
  // 交易密码
  'transactionPassword': (error) {
    final err = error as Map<String, dynamic>;
    if (err['reason'] == 'wrong') return 'Incorrect transaction password.';
    if (err['reason'] == 'length') return 'Password must be 6 digits.';
    return 'Security verification failed.';
  },

  // 提现频率限制
  'frequencyLimit': (_) => 'Please wait a few minutes before the next withdrawal.',

  // === 5. 合规状态 (Compliance) ===
  'kycRequired': (_) => 'Identity verification (KYC) is required for withdrawal.',
  'turnoverNotMet': (error) {
    final remaining = (error as Map)['remaining'];
    return 'Remaining betting turnover required: ₱$remaining';
  },*/
};