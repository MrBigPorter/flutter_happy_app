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
    if(v.isEmpty) return null; // 允许空值 let required handle it
    return _re.hasMatch(v) ? null : const {'phone': true}; // 非法
  }
}

class CountryCode extends Validator<dynamic> {
  const CountryCode();
  static final _re = RegExp(r'^\+[1-9]\d{0,3}$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if(v.isEmpty) return null; // 允许空值 let required handle it
    return _re.hasMatch(v) ? null : const {'countryCode': true}; // 非法
  }
}

class OtpLen extends Validator<dynamic> {
  final int length;
  const OtpLen([this.length = 6]);
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if(v.isEmpty) return const {'required': true}; // 必填 must not be empty
    return v.length == length ? null : {'otp': {'len':length}}; // 非法
  }
}

class StrongPassword extends Validator<dynamic> {
  const StrongPassword();
  static final _re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,20}$');

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final v = (control.value ?? '').toString();
    if(v.isEmpty) return const {'required': true}; // 必填 must not be empty
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
  static final _re = RegExp(r'^[\u4e00-\u9fa5a-zA-Z·\s]{2,50}$');

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
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
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