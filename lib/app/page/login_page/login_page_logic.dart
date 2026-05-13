part of 'login_page.dart';

mixin LoginPageLogic on ConsumerState<LoginPage> {
  late final Countdown cd = Countdown();

  late final LoginEmailModelForm emailForm = LoginEmailModelForm(
    LoginEmailModelForm.formElements(const LoginEmailModel()),
    null,
  );

  bool _submitted = false;
  bool _emailLoginInFlight = false;
  bool _socialOauthInFlight = false;
  bool _isSuccessRedirecting = false;
  bool _oauthCancelled = false;
  /// 当前正在加载的第三方登录 provider，用于精确控制各按钮的 loading 状态
  String? _socialLoadingProvider; // 'google' | 'facebook' | 'apple'

  @override
  void initState() {
    super.initState();
    if (isAppRouterReady) {
      appRouter.routeInformationProvider.addListener(_onRouteChanged);
    }
  }

  /// 路由监听：如果用户在 OAuth 进行中被 deep link 带离登录页，重置 loading 状态
  void _onRouteChanged() {
    if (!mounted) return;
    final currentPath = appRouter.routeInformationProvider.value.uri.path;
    if (currentPath != '/login' && _socialOauthInFlight) {
      debugPrint('[LoginPage] Route changed away from login, resetting OAuth state');
      if (mounted) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }

  void submit() {
    setState(() {
      _submitted = true;
      emailForm.form.markAllAsTouched();
    });

    if (!emailForm.form.valid) return;
    loginWithEmailCode();
  }

  Future<void> loginWithEmailCode() async {
    if (ref.watch(authLoginEmailCtrlProvider).isLoading ||
        _emailLoginInFlight ||
        _isSuccessRedirecting) {
      return;
    }

    final model = emailForm.model;
    setState(() => _emailLoginInFlight = true);

    try {
      final result = await ref.read(authLoginEmailCtrlProvider.notifier).run((
      email: model.email,
      code: model.code,
      ));

      if (!mounted) return;

      // 检查 token.accessToken 是否非空，确保后端真正返回了有效令牌
      if (result.tokens.accessToken.isNotEmpty) {
        _isSuccessRedirecting = true;
        await _syncLoginTokens(result.tokens.accessToken, result.tokens.refreshToken);
      }
    } catch (e) {
      // 显示后端错误信息（如 Invalid code）
      final message = e.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        RadixToast.error(message);
      }
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _emailLoginInFlight = false);
      }
    }
  }

  String? _currentInviteCode() {
    final AbstractControl<dynamic>? control;
    try {
      control = emailForm.form.control('inviteCode');
    } catch (_) {
      return null;
    }
    final value = control.value?.toString();
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  Future<void> _syncLoginTokens(String accessToken, String refreshToken) async {
    if (!mounted) return;
    final auth = ref.read(authProvider.notifier);
    await auth.login(accessToken, refreshToken);
  }

  Future<void> _loginWithGoogleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() {
      _socialOauthInFlight = true;
      _socialLoadingProvider = 'google';
    });
    try {
      final result = await DeepLinkOAuthService.loginWithGoogle(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
        context: context,
      );

      if (!mounted) return;

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
        }
      }
    }
  }

  Future<void> _loginWithFacebookOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() {
      _socialOauthInFlight = true;
      _socialLoadingProvider = 'facebook';
    });
    try {
      final result = await DeepLinkOAuthService.loginWithFacebook(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
        context: context,
      );

      if (!mounted) return;

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
        }
      }
    }
  }

  Future<void> _loginWithAppleOauth() async {
    if (_socialOauthInFlight || _isSuccessRedirecting) return;
    _oauthCancelled = false;
    setState(() {
      _socialOauthInFlight = true;
      _socialLoadingProvider = 'apple';
    });
    try {
      final result = await DeepLinkOAuthService.loginWithApple(
        apiBaseUrl: OAuthConfig.apiBaseUrl,
        inviteCode: _currentInviteCode(),
        context: context,
      );

      if (!mounted) return;

      _isSuccessRedirecting = true;
      await _syncLoginTokens(result['token']!, result['refreshToken'] ?? '');

      if (mounted) setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
    } on DeepLinkOAuthException catch (e) {
      if (e.message.contains('cancelled') || e.message.contains('timeout')) {
        _oauthCancelled = true;
        return;
      }
      _handleOauthError(e);
    } catch (e) {
      _handleOauthError(e);
    } finally {
      if (mounted && !_isSuccessRedirecting) {
        if (!_oauthCancelled && mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        if (mounted && !_isSuccessRedirecting) {
          setState(() { _socialOauthInFlight = false; _socialLoadingProvider = null; });
        }
      }
    }
  }

  void _handleOauthError(Object error) {
    if (error is OauthCancelledException) {
      _oauthCancelled = true;
      return;
    }
    final raw = error.toString();
    if (raw.contains('origin_mismatch')) {
      RadixToast.error('Google login blocked: origin_mismatch.');
      return;
    }
    final message = raw.replaceFirst('Exception: ', '');
    RadixToast.error(message);
  }

  Future<void> sendCode() async {
    if (cd.running || _emailLoginInFlight || _socialOauthInFlight || _isSuccessRedirecting) return;

    final email = emailForm.form.control('email');
    email.markAsTouched();
    if (email.invalid) return;

    final emailValue = email.value.toString();
    try {
      await ref.read(sendEmailCodeCtrlProvider.notifier).run(emailValue);
      if (!mounted) return;
      RadixToast.success('login.email_code_sent'.tr(namedArgs: {'email': emailValue}));
      cd.start(60);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      RadixToast.error(message);
    }
  }

  @override
  void dispose() {
    if (isAppRouterReady) {
      appRouter.routeInformationProvider.removeListener(_onRouteChanged);
    }
    cd.dispose();
    super.dispose();
  }
}