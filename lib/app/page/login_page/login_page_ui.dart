part of 'login_page.dart';

extension LoginPageUI on _LoginPageState {
  Widget buildUI(BuildContext context) {
    final sendEmail = ref.watch(sendEmailCodeCtrlProvider);
    final emailLogin = ref.watch(authLoginEmailCtrlProvider);

    final isPageBusy = _emailLoginInFlight ||
        _socialOauthInFlight ||
        _isSuccessRedirecting;

    final isEmailBtnLoading = emailLogin.isLoading || _emailLoginInFlight;
    // 各按钮只在自己的 provider 被点击时转圈
    final isGoogleLoading = _socialOauthInFlight && _socialLoadingProvider == 'google';
    final isFacebookLoading = _socialOauthInFlight && _socialLoadingProvider == 'facebook';
    final isAppleLoading = _socialOauthInFlight && _socialLoadingProvider == 'apple';

    final showGoogleButton = DeepLinkOAuthService.canShowGoogleButton;
    final showFacebookButton = DeepLinkOAuthService.canShowFacebookButton;
    final showAppleButton = DeepLinkOAuthService.canShowAppleButton;

    return BaseScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 48.h),
                    // 核心防御墙：整个表单和按钮区域在 Busy 状态下完全忽略触摸事件
                    child: AbsorbPointer(
                      absorbing: isPageBusy,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ─── 头部视觉组 ───
                          Image.asset(
                            'assets/images/logo.png',
                            width: 72.w,
                            height: 72.w,
                          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),


                          Text(
                            'sign-in'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30.sp,
                              height: 1.2,
                              letterSpacing: -0.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary900,
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

                          SizedBox(height: 8.h),

                          Text(
                            'login.welcome_subtitle'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: context.textMd,
                              height: context.leadingMd,
                              fontWeight: FontWeight.w400,
                              color: context.textTertiary600,
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                          // ─── 测试模式引导横幅（仅 test mode 可见） ───
                          if (_isTestMode) ...[
                            SizedBox(height: 16.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: context.bgWarningPrimary,
                                border: Border.all(color: context.bgWarningSecondary),
                                borderRadius: BorderRadius.circular(12.h),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline, color: context.textWhite, size: 20.sp),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'login.test_mode_banner'.tr(),
                                      style: TextStyle(
                                        fontSize: context.textSm,
                                        color: context.textWhite,
                                        height: context.leadingMd,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                          ] else ...[
                            SizedBox(height: 48.h),
                          ],

                          // ─── 表单区域 ───
                          ReactiveFormConfig(
                            validationMessages: kGlobalValidationMessages,
                            child: ReactiveForm(
                              formGroup: emailForm.form,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LfInput(
                                    name: 'email',
                                    label: 'login.email.label'.tr(),
                                    hint: 'login.email.hint'.tr(),
                                    required: true,
                                    keyboardType: TextInputType.emailAddress,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                  ),
                                  SizedBox(height: 20.h),
                                  LfInput(
                                    name: 'code',
                                    label: 'login.email_code.label'.tr(),
                                    hint: 'login.email_code.hint'.tr(),
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    showErrors: (c) => c.invalid && (c.dirty || _submitted),
                                    suffixIcon: ValueListenableBuilder(
                                      valueListenable: cd.seconds,
                                      builder: (context, int seconds, _) {
                                        final running = cd.running;
                                        return Button(
                                          variant: ButtonVariant.text,
                                          loading: sendEmail.isLoading,
                                          onPressed: running || sendEmail.isLoading ? null : sendCode,
                                          child: Text(
                                            running
                                                ? 'login.resend_in'.tr(namedArgs: {'seconds': '$seconds'})
                                                : 'login.send_code'.tr(),
                                            style: TextStyle(
                                              fontSize: context.textSm,
                                              fontWeight: FontWeight.w600,
                                              color: running ? context.textDisabled : context.buttonTertiaryColorFg,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: 36.h),

                                  // 登录按钮 (使用专属的 Loading 状态)
                                  Button(
                                    loading: isEmailBtnLoading,
                                    width: double.infinity,
                                    height: 52.h,
                                    onPressed: submit,
                                    child: Text(
                                      'common.login'.tr(),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 32.h),

                                  Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: Text(
                                          'login.or_continue_with'.tr(),
                                          style: TextStyle(
                                            fontSize: context.textSm,
                                            color: context.textTertiary600,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider()),
                                    ],
                                  ),

                                  SizedBox(height: 24.h),

                                  // ─── 社交登录按钮区域 ───
                                  if (showGoogleButton) ...[
                                    Button(
                                      width: double.infinity,
                                      height: 48.h,
                                      variant: ButtonVariant.secondary,
                                      loading: isGoogleLoading,
                                      onPressed: isPageBusy ? null : _loginWithGoogleOauth,
                                      leading: Icon(Icons.g_mobiledata_rounded, size: 35.sp),
                                      child: Text('login.oauth.google'.tr()),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],

                                  if (showFacebookButton) ...[
                                    Button(
                                      width: double.infinity,
                                      height: 48.h,
                                      variant: ButtonVariant.secondary,
                                      loading: isFacebookLoading,
                                      onPressed: isPageBusy ? null : _loginWithFacebookOauth,
                                      leading: const Icon(Icons.facebook_rounded),
                                      child: Text('login.oauth.facebook'.tr()),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],

                                  /*if (showAppleButton) ...[
                                    Button(
                                      width: double.infinity,
                                      height: 48.h,
                                      variant: ButtonVariant.secondary,
                                      loading: isAppleLoading,
                                      onPressed: isPageBusy ? null : _loginWithAppleOauth,
                                      leading: const Icon(Icons.apple_rounded),
                                      child: Text('login.oauth.apple'.tr()),
                                    ),
                                    SizedBox(height: 16.h),
                                  ],*/


                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.05, end: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}