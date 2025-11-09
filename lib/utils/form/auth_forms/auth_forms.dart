import 'package:flutter_app/utils/form/validators.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

part 'auth_forms.gform.dart';

@Rf()
class LoginOtpModel {
  const LoginOtpModel({
    @RfControl(validators: [NonEmpty(), Phone10()]) this.phone = '',
    @RfControl(validators: [OtpLen(4)]) this.otp = '',
    @RfControl(validators: [InviteCode()]) this.inviteCode = '',
  });

  final String phone;
  final String otp;
  final String? inviteCode;
}

@Rf()
class LoginPasswordModel {
  const LoginPasswordModel({
    @RfControl(validators: [NonEmpty(), Phone10()]) this.phone = '',
    @RfControl(validators: [StrongPassword()]) this.password = '',
    @RfControl(validators: [InviteCode()]) this.inviteCode = '',
  });

  final String phone;
  final String password;
  final String? inviteCode;
}
