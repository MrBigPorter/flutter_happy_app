import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'deep_link_oauth_service_web_stub.dart'
    if (dart.library.html) 'deep_link_oauth_service_web.dart';
import 'oauth_web_view_page.dart';

/// OAuth Deep Link 异常
class DeepLinkOAuthException implements Exception {
  final String message;
  DeepLinkOAuthException(this.message);
  @override
  String toString() => message;
}

/// 后端统一 Deep Link OAuth 登录服务
/// 支持 Google、Facebook、Apple 三种 Provider
/// 移动端统一使用 OAuthWebViewPage（官方 webview_flutter，兼容 iOS 26+）
class DeepLinkOAuthService {
  DeepLinkOAuthService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _deepLinkSubscription;
  static bool _initialized = false;

  static bool get canShowGoogleButton => true;
  static bool get canShowFacebookButton => true;

  /// Apple Sign-In は Apple プラットフォームと Web のみで表示
  static bool get canShowAppleButton {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  /// 检查后端 OAuth 配置是否正常
  static Future<bool> checkOAuthConfiguration(String apiBaseUrl) async {
    try {
      final testUrl = '$apiBaseUrl/auth/google/login?callback=joymini://oauth/callback';
      final uri = Uri.parse(testUrl);
      final canLaunch = await canLaunchUrl(uri);
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OAuth configuration check: $canLaunch');
        debugPrint('[DeepLinkOAuthService] Test URL: $testUrl');
      }
      return canLaunch;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OAuth configuration check failed: $e');
      }
      return false;
    }
  }

  /// 初始化 Deep Link 监听
  static void initialize() {
    if (_initialized) return;
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint('[DeepLinkOAuthService] Deep Link Error: $err'),
    );
    _initialized = true;
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Deep Link listener initialized');
  }

  /// 处理 Deep Link
  static void _handleDeepLink(Uri uri) {
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Received URI: $uri');

    if (uri.scheme == 'joymini' && uri.host == 'oauth') {
      // WebView flow: OAuthWebViewPage intercepts joymini:// via onNavigationRequest
      // before it reaches the OS. This listener is a safety net for edge cases
      // (e.g., external browser fallback) but normally the token is returned
      // directly via Navigator.pop() in OAuthWebViewPage.
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OS-level joymini:// OAuth callback received (edge case): $uri');
      }
    } else if (uri.scheme != 'https' && uri.scheme != 'http') {
      if (kDebugMode) debugPrint('[DeepLinkOAuthService] Ignoring non-OAuth Deep Link: $uri');
    }
  }

  /// 使用 Google 登录
  static Future<Map<String, String>> loginWithGoogle({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('google', apiBaseUrl, inviteCode: inviteCode, context: context);

  /// 使用 Facebook 登录
  static Future<Map<String, String>> loginWithFacebook({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('facebook', apiBaseUrl, inviteCode: inviteCode, context: context);

  /// 使用 Apple 登录
  static Future<Map<String, String>> loginWithApple({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('apple', apiBaseUrl, inviteCode: inviteCode, context: context);

  static String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _getWebOrigin() {
    if (!kIsWeb) return 'http://localhost:4000';
    try { return _getWindowOrigin(); } catch (_) { return 'http://localhost:4000'; }
  }

  static String _getWindowOrigin() {
    if (kIsWeb) {
      try { return _getWebWindowOrigin(); }
      catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to get window origin: $e');
        return 'http://localhost:4000';
      }
    }
    return 'http://localhost:4000';
  }

  static String _getWebWindowOrigin() => DeepLinkOAuthServiceWeb.getWindowOrigin();

  /// Web 平台 OAuth 登录
  ///
  /// 使用弹窗（popup）方式代替整页跳转，避免 Flutter App 完全重新加载。
  /// 流程：
  /// 1. 同步打开空白弹窗（绕过浏览器弹窗拦截）
  /// 2. 将弹窗导航到后端 OAuth URL
  /// 3. 弹窗完成 OAuth 后着陆到 /oauth-popup-callback.html
  /// 4. callback.html 通过 postMessage 或 localStorage 传回 token
  /// 5. 主窗口收到 token 后完成登录
  static Future<Map<String, String>> _webLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    final state = _generateState();
    final origin = _getWebOrigin();
    // 弹窗回调页改为静态 HTML，无需加载 Flutter App
    final redirectUri = '$origin/oauth-popup-callback.html';
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    var loginPath =
        '/auth/$provider/login'
        '?state=${Uri.encodeComponent(state)}'
        '&callback=${Uri.encodeComponent(redirectUri)}';
    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }
    final loginUrl = cleanBaseUrl + loginPath;
    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Web OAuth URL: $loginUrl');
      debugPrint('[DeepLinkOAuthService] callback param: ${Uri.encodeComponent(redirectUri)}');
    }

    if (!kIsWeb) {
      throw DeepLinkOAuthException('_webLoginWithProvider called on non-web platform');
    }

    // 存储 state 用于后续验证
    try { _storeStateInSession(provider, state); } catch (e) {
      debugPrint('[DeepLinkOAuthService] Failed to store state: $e');
    }

    // 尝试弹窗方式（先开空白弹窗再填 URL，绕过拦截器）
    final popupOpened = DeepLinkOAuthServiceWeb.openPopup(loginUrl);
    if (!popupOpened) {
      // 弹窗被拦截，降级为整页跳转
      debugPrint('[DeepLinkOAuthService] Popup blocked, falling back to full-page redirect');
      try {
        _redirectToUrl(loginUrl);
      } catch (e) {
        throw DeepLinkOAuthException('Failed to redirect: $e');
      }
      throw DeepLinkOAuthException(
        'Web OAuth cancelled: redirect initiated, awaiting browser completion.',
      );
    }

    // 弹窗成功打开，监听 token（postMessage + localStorage 双通道）
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Popup opened, waiting for OAuth token...');

    try {
      if (kDebugMode) debugPrint('[DeepLinkOAuthService] Listening for token via postMessage + StorageEvent...');
      final token = await DeepLinkOAuthServiceWeb
          .listenForOAuthToken()
          .timeout(const Duration(minutes: 5))
          .first;
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OAuth token received');
        debugPrint('[DeepLinkOAuthService] Token keys: ${token.keys}');
      }
      return token;
    } on TimeoutException {
      throw DeepLinkOAuthException('OAuth login timeout after 5 minutes');
    }
  }

  /// 移动端 OAuth 登录（使用 OAuthWebViewPage，基于官方 webview_flutter，兼容 iOS 26+）
  static Future<Map<String, String>> _mobileLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
    BuildContext? context,
  }) async {
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    var loginPath =
        '/auth/$provider/login?callback=${Uri.encodeComponent('joymini://oauth/callback')}';
    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }
    final loginUrl = cleanBaseUrl + loginPath;

    if (kDebugMode) {
      debugPrint('\n====================================');
      debugPrint(' [DeepLinkOAuth] OAuth URL: $loginUrl');
      debugPrint('====================================\n');
    }

    if (context == null || !context.mounted) {
      throw DeepLinkOAuthException(
          'OAuth requires a valid BuildContext (context is null or unmounted)');
    }

    final result = await Navigator.of(context).push<Map<String, String>?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OAuthWebViewPage(loginUrl: loginUrl, provider: provider),
      ),
    );

    if (result != null) return result;
    throw DeepLinkOAuthException('Login cancelled by user');
  }

  static Future<Map<String, String>> _loginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      return _webLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode);
    } else {
      return _mobileLoginWithProvider(provider, apiBaseUrl,
          inviteCode: inviteCode, context: context);
    }
  }

  static void _storeStateInSession(String provider, String state) =>
      DeepLinkOAuthServiceWeb.storeStateInSession(provider, state);

  static void _redirectToUrl(String url) =>
      DeepLinkOAuthServiceWeb.redirectToUrl(url);

  /// 取消登录 — WebView 流程中取消由 OAuthWebViewPage 的 X 按钮处理，
  /// 此方法保留供将来扩展，当前为空操作。
  static void cancelLogin() {
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] cancelLogin() called (no-op in WebView mode)');
  }

  /// WebView 流程中永远没有挂起的 Completer，始终返回 false。
  static bool get isOAuthInProgress => false;

  /// 已废弃：InAppBrowser 已移除，始终返回 false
  static bool get isInAppBrowserMode => false;

  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _initialized = false;
  }
}
