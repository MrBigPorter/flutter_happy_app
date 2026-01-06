import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

class NonEmpty extends Validator<dynamic> {
  const NonEmpty();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    return v.isNotEmpty ? null : const {'required': true};
  }
}

class Phone10 extends Validator<dynamic> {
  const Phone10();

  static final _re = RegExp(r'^[1-9]\d{9}$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return null; // 允许空值 let required handle it
    return _re.hasMatch(v) ? null : const {'phone': true}; // 非法
  }
}

class CountryCode extends Validator<dynamic> {
  const CountryCode();

  static final _re = RegExp(r'^\+[1-9]\d{0,3}$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return null; // 允许空值 let required handle it
    return _re.hasMatch(v) ? null : const {'countryCode': true}; // 非法
  }
}

class OtpLen extends Validator<dynamic> {
  final int length;

  const OtpLen([this.length = 6]);

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return const {'required': true}; // 必填 must not be empty
    return v.length == length
        ? null
        : {
            'otp': {'len': length},
          }; // 非法
  }
}

class StrongPassword extends Validator<dynamic> {
  const StrongPassword();

  static final _re = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,20}$',
  );

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return const {'required': true}; // 必填 must not be empty
    return _re.hasMatch(v) ? null : const {'password': true}; // 非法
  }
}

class InviteCode extends Validator<dynamic> {
  const InviteCode();

  static final _re = RegExp(r'^(?:[a-zA-Z0-9]{5,20})?$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    return _re.hasMatch(v) ? null : const {'inviteCode': true}; // 非法
  }
}

// 1. 实名验证：支持中文、英文及菲律宾常见名字字符
class RealName extends Validator<dynamic> {
  const RealName();

  // 这种写法更宽松：只要不是数字和大部分奇怪的标点符号就行
  static final _re = RegExp(r'^[^\d0-9`~!@#$%^&*()_+={}\[\]|\\:;\"<>,?/]+$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value?.toString() ?? '';
    if (v.isEmpty) return null; // 让 NonEmpty 处理必填
    return _re.hasMatch(v) ? null : const {'realName': true};
  }
}

// 2. 证件号验证：兼容性更强
class IdNumberValidator extends Validator<dynamic> {
  const IdNumberValidator();

  static final _re = RegExp(r'^[A-Z0-9-]{5,30}$'); // 增加对连字符的支持

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value?.toString() ?? '';
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : const {'idNumber': true};
  }
}

// 3. 生日验证：确保用户已成年
class IsAdult extends Validator<dynamic> {
  const IsAdult();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (control.value == null) return null;
    try {
      final birthDate = DateTime.parse(control.value.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age >= 18 ? null : const {'underage': true};
    } catch (_) {
      return const {'invalidDate': true};
    }
  }
}

class Required extends Validator<dynamic> {
  const Required();

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value;
    if (v == null) return const {'required': true};
    if (v is String && v.trim().isEmpty) return const {'required': true};
    if (v is Iterable || v is Map) {
      if ((v as dynamic).isEmpty) return const {'required': true};
    }
    return null;
  }
}

class PostalCode extends Validator<dynamic> {
  const PostalCode();

  static final _re = RegExp(r'^\d{4}$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();

    // 修改点：如果为空，直接返回 null (代表通过)，不再返回 required 错误
    if (v.isEmpty) {
      return null;
    }

    // 只有当有值的时候，才校验格式
    return _re.hasMatch(v) ? null : const {'postalCode': true};
  }
}

class DepositAmount extends Validator<dynamic> {
  final double minAmount;
  final double? maxAmount;

  const DepositAmount({this.minAmount = 100.0, this.maxAmount});

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final raw = control.value;
    //空值交给 Validators.required 处理
    if (raw == null || raw.toString().trim().isEmpty) return null;

    final amount = double.tryParse(raw.toString().trim());

    if (amount == null) {
      return const {
        'amount': {'reason': 'invalid'},
      };
    }

    if (amount < minAmount) {
      return {
        'amount': {
          'reason': 'min',
          'min': minAmount,
          if (maxAmount != null) 'max': maxAmount,
        },
      };
    }

    if (maxAmount != null && amount > maxAmount!) {
      return {
        'amount': {'reason': 'max', 'max': maxAmount, 'min': minAmount},
      };
    }

    return null;
  }
}

class WithdrawAmount extends Validator<dynamic> {
  final double minAmount; // 最小提现金额
  final double? maxAmount; // 平台单笔最大上限
  final double? withdrawableBalance; // 当前实际可提现余额
  final double feeRate; // 百分比费率 (如 0.02)
  final double fixedFee; // 固定手续费 (如 5.0)
  final double? dailyLimit; // 每日剩余提现额度
  final bool isAccountVerified; // 用户是否完成KYC实名
  final double minBalanceToKeep; // 账户需保留的最低余额 (有些钱包要求不能取空)

  const WithdrawAmount({
    this.minAmount = 100.0,
    this.maxAmount,
    this.withdrawableBalance,
    this.feeRate = 0.0,
    this.fixedFee = 0.0,
    this.dailyLimit,
    this.isAccountVerified = true,
    this.minBalanceToKeep = 0.0,
  });

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final raw = control.value;
    

    if (raw == null || raw.toString().trim().isEmpty) return null;
    final amount = double.tryParse(raw.toString().trim()) ?? 0;
    // 1. 基础金额校验
    if (amount < minAmount) {
      return {
        'amount': {'reason': 'min', 'min': minAmount},
      };
    }
    if (maxAmount != null && amount > maxAmount!) {
      return {
        'amount': {'reason': 'max', 'max': maxAmount},
      };
    }

    // 2. 身份/合规校验
    if (!isAccountVerified) {
      return {
        'amount': {'reason': 'not_verified'},
      };
    }

    // 3. 余额校验 (扣除需保留的金额)
    final actualAvailable = (withdrawableBalance ?? 0) - minBalanceToKeep;
    if (amount > actualAvailable) {
      return {
        'amount': {
          'reason': 'insufficient',
          'balance': actualAvailable,
        },
      };
    }

    // 4. 每日额度校验
    if (dailyLimit != null && amount > dailyLimit!) {
      return {
        'amount': {'reason': 'daily_limit', 'limit': dailyLimit},
      };
    }

    // 5. 手续费逻辑校验
    final totalFee = (amount * feeRate) + fixedFee;
    if (amount <= totalFee) {
      return {
        'amount': {'reason': 'too_low_for_fee', 'fee': totalFee},
      };
    }

    return null;
  }
}
