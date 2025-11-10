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