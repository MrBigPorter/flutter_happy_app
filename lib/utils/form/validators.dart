import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

// v17 时代：一切皆 dynamic，简单粗暴
class NonEmpty extends Validator<dynamic> {
  const NonEmpty();
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    // 不需要 <String, Object> 了，普通的 Map 就行
    return v.isNotEmpty ? null : {'required': true};
  }
}

class Phone10 extends Validator<dynamic> {
  const Phone10();
  static final _re = RegExp(r'^[1-9]\d{9}$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : {'phone': true};
  }
}

class CountryCode extends Validator<dynamic> {
  const CountryCode();
  static final _re = RegExp(r'^\+[1-9]\d{0,3}$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : {'countryCode': true};
  }
}

class OtpLen extends Validator<dynamic> {
  final int length;
  const OtpLen([this.length = 6]);
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return {'required': true};
    return v.length == length ? null : {'otp': {'len': length}};
  }
}

class StrongPassword extends Validator<dynamic> {
  const StrongPassword();
  static final _re = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,20}$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if (v.isEmpty) return {'required': true};
    return _re.hasMatch(v) ? null : {'password': true};
  }
}

class InviteCode extends Validator<dynamic> {
  const InviteCode();
  static final _re = RegExp(r'^(?:[a-zA-Z0-9]{5,20})?$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    return _re.hasMatch(v) ? null : {'inviteCode': true};
  }
}

class RealName extends Validator<dynamic> {
  const RealName();
  static final _re = RegExp(r'^[^\d0-9`~!@#$%^&*()_+={}\[\]|\\:;\"<>,?/]+$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value?.toString() ?? '';
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : {'realName': true};
  }
}

class IdNumberValidator extends Validator<dynamic> {
  const IdNumberValidator();
  static final _re = RegExp(r'^[A-Z0-9-]{5,30}$');
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value?.toString() ?? '';
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : {'idNumber': true};
  }
}

class IsAdult extends Validator<dynamic> {
  const IsAdult();
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (control.value == null) return null;
    try {
      final birthDate = DateTime.parse(control.value.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age >= 18 ? null : {'underage': true};
    } catch (_) {
      return {'invalidDate': true};
    }
  }
}

class Required extends Validator<dynamic> {
  const Required();
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = control.value;
    if (v == null) return {'required': true};
    if (v is String && v.trim().isEmpty) return {'required': true};
    if (v is Iterable || v is Map) {
      if ((v as dynamic).isEmpty) return {'required': true};
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
    if (v.isEmpty) return null;
    return _re.hasMatch(v) ? null : {'postalCode': true};
  }
}

class DepositAmount extends Validator<dynamic> {
  final double minAmount;
  final double? maxAmount;
  const DepositAmount({this.minAmount = 100.0, this.maxAmount});
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final raw = control.value;
    if (raw == null || raw.toString().trim().isEmpty) return null;
    final amount = double.tryParse(raw.toString().trim());
    if (amount == null) return {'amount': {'reason': 'invalid'}};
    if (amount < minAmount) {
      return {'amount': {'reason': 'min', 'min': minAmount, if (maxAmount != null) 'max': maxAmount}};
    }
    if (maxAmount != null && amount > maxAmount!) {
      return {'amount': {'reason': 'max', 'max': maxAmount, 'min': minAmount}};
    }
    return null;
  }
}

class WithdrawAmount extends Validator<dynamic> {
  final double minAmount;
  final double? maxAmount;
  final double? withdrawableBalance;
  final double feeRate;
  final double fixedFee;
  final double? dailyLimit;
  final bool isAccountVerified;
  final double minBalanceToKeep;

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
    if (amount < minAmount) return {'amount': {'reason': 'min', 'min': minAmount}};
    if (maxAmount != null && amount > maxAmount!) return {'amount': {'reason': 'max', 'max': maxAmount}};
    if (!isAccountVerified) return {'amount': {'reason': 'not_verified'}};
    final actualAvailable = (withdrawableBalance ?? 0) - minBalanceToKeep;
    if (amount > actualAvailable) return {'amount': {'reason': 'insufficient', 'balance': actualAvailable}};
    if (dailyLimit != null && amount > dailyLimit!) return {'amount': {'reason': 'daily_limit', 'limit': dailyLimit}};
    final totalFee = (amount * feeRate) + fixedFee;
    if (amount <= totalFee) return {'amount': {'reason': 'too_low_for_fee', 'fee': totalFee}};
    return null;
  }
}