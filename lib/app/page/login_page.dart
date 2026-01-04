import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/core/providers/auth_provider.dart';
import 'package:flutter_app/core/store/auth/auth_provider.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/form/index.dart';
import 'package:flutter_app/utils/form/auth_forms/auth_forms.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_app/utils/time/countdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'package:flutter_app/ui/button/variant.dart';
import 'package:flutter_app/utils/form/validation_messages.dart';



class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {

  late final Countdown cd = Countdown();



  // OTP 登录表单 OTP Login Form
  late final LoginOtpModelForm otpForm = LoginOtpModelForm(
    LoginOtpModelForm.formElements(const LoginOtpModel()),
    null,
  );

  // 密码登录表单 Password Login Form
  late final LoginPasswordModelForm passwordForm = LoginPasswordModelForm(
    LoginPasswordModelForm.formElements(const LoginPasswordModel()),
    null,
  );

  // 当前使用的登录方式 Current Login Method
  bool _usePasswordLogin = false;
  // 是否已提交表单 Whether the form has been submitted
  bool _submitted = false;

 // 切换登录方式 Switch Login Method
  void changeLoginMethod() {
    if (_usePasswordLogin) {
      passwordForm.form
          .reset();
    } else {
      otpForm.form
          .reset();
    }
    cd.stop();
    setState(() {
      _usePasswordLogin = !_usePasswordLogin;
      _submitted = false;
    });

  }

  // 提交表单 Submit Form
  void submit () {
    final form = _usePasswordLogin ? passwordForm.form : otpForm.form;
    setState(() {
      _submitted = true;
      form.markAllAsTouched();
    });

    if (!form.valid) return;

    if (_usePasswordLogin) {
      final m = passwordForm.model;
      // TODO: 密码登录 m.phone, m.password, m.countryCode, m.inviteCode
    } else {
      loginWithOtp();
    }
  }

  Future<void> loginWithOtp() async {
    final model = otpForm.model;

    if(ref.watch(verifyOtpCtrlProvider).isLoading) return;

    // verify otp
    final verify = await ref.read(verifyOtpCtrlProvider.notifier).run(model.phone, model.otp);

   if(!verify) return;

    //  Call login logic
    final result = await ref.read(authLoginOtpCtrlProvider.notifier).run((
      phone: model.phone,
    ));

    if(result.isNotNullOrEmpty && result.tokens.isNotNullOrEmpty) {
      //  Token Save Token
      final auth = ref.read(authProvider.notifier);
      //  Login success,save tokens
      await auth.login(
        result.tokens.accessToken,
        result.tokens.refreshToken,
      );

      //  Navigate to Main Page
      appRouter.go('/home');
    }
  }

  Future<void> sendCode() async {
    final form = _usePasswordLogin ? passwordForm.form : otpForm.form;
    final phone = form.control('phone');
    phone.markAsTouched();


    if(phone.invalid) return;


    if(cd.running) return;

    final sendCtrl = ref.read(sendOtpCtrlProvider.notifier);
    await sendCtrl.run(phone.value);
    cd.start(60);
  }

  @override
  void dispose() {
    cd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final send = ref.watch(sendOtpCtrlProvider);
    final verify = ref.watch(verifyOtpCtrlProvider);
    final login = ref.watch(authLoginOtpCtrlProvider);

    return BaseScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 32.w, 16.w, 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      'sign-in'.tr(),
                      style: TextStyle(
                        fontSize: context.displayXs,
                        height: context.leadingXs,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900,
                      ),
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      'start-your-fortunate-journey'.tr(),
                      style: TextStyle(
                        fontSize: context.textMd,
                        height: context.leadingMd,
                        fontWeight: FontWeight.w400,
                        color: context.textTertiary600,
                      ),
                    ),
                    SizedBox(height: 20.w),

                    ReactiveFormConfig(
                      validationMessages: kGlobalValidationMessages,
                      child: ReactiveForm(
                        key: ValueKey(_usePasswordLogin),
                        formGroup: _usePasswordLogin ? passwordForm.form : otpForm.form,
                        child: Stack(
                          children: [
                            // 右上角切换按钮
                            Positioned(
                              right: 0,
                              top: -18.w,
                              child: Button(
                                variant: ButtonVariant.text,
                                textStyle: TextStyle(
                                  fontSize: context.textSm,
                                  height: context.leadingSm,
                                  fontWeight: FontWeight.w600,
                                  color: context.buttonTertiaryColorFg,
                                ),
                                onPressed: changeLoginMethod,
                                child: Text(
                                  _usePasswordLogin
                                      ? 'Log in with Code'
                                      : 'Log in with Password',
                                ),
                              ),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 公共：手机号
                                LfInput(
                                  name: 'phone',
                                  label: 'Phone Number',
                                  hint: 'Enter your phone number',
                                  required: true,
                                  keyboardType: TextInputType.phone,
                                  showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                  prefixIcon: _buildPhPrefix(context),
                                ),
                                SizedBox(height: 16.w),

                                if (_usePasswordLogin) ...[
                                  LfInput(
                                    name: 'password',
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    required: true,
                                    obscureText: true,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                  ),
                                  Button(
                                    variant: ButtonVariant.text,
                                    paddingX: 0,
                                    onPressed: () =>
                                        appRouter.push('/reset-password'),
                                    child: Text(
                                      'common.forgot.password'.tr(),
                                      style: TextStyle(
                                        fontSize: context.textSm,
                                        height: context.leadingSm,
                                        fontWeight: FontWeight.w800,
                                        color: context.buttonTertiaryColorFg,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  LfInput(
                                    name: 'otp',
                                    label: 'Code',
                                    hint: 'Enter your Code',
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                    suffixIcon: ValueListenableBuilder(
                                        valueListenable: cd.seconds,
                                        builder: (context, int seconds, _) {
                                          final running = cd.running;
                                          return Button(
                                              variant: ButtonVariant.text,
                                              loading: send.isLoading,
                                              onPressed: running || send.isLoading ? null:sendCode,
                                              child: Text(
                                                  running?'Resend in ${seconds}s':'send code',
                                                  style: TextStyle(
                                                    fontSize: context.textSm,
                                                    height: context.leadingSm,
                                                    fontWeight: FontWeight.w600,
                                                    color: running
                                                        ? context.textDisabled
                                                        : context.buttonTertiaryColorFg,
                                                  )
                                              )
                                          );
                                        }
                                    ),
                                  ),
                                ],

                                SizedBox(height: 24.w),

                                // 提交
                                Button(
                                  loading: verify.isLoading || login.isLoading,
                                  width: double.infinity,
                                  onPressed: submit,
                                  child: Text('common.login'.tr()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhPrefix(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/ph.png',
            width: 24.w,
            height: 24.w,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 4.w),
          Text(
            '+63',
            style: TextStyle(
              fontSize: context.textMd,
              height: context.leadingMd,
              fontWeight: FontWeight.w400,
              color: context.textPrimary900,
            ),
          ),
        ],
      ),
    );
  }
}
