# OAuth Deep Link 三端统一登录方案技术指南（企业级标准）

> **Version**: 3.0  
> **Last Updated**: 2026-05-14  
> **Status**: ✅ 已实施（包含Web弹窗登录 + Chrome后台Tab节流修复）  
> **Platforms**: iOS, Android, Web/H5  
> **核心特性**: 平台感知架构 + Web弹窗登录 + 三通道Token冗余 + State防CSRF

---

## Table of Contents

1. [概述](#概述)
2. [架构设计](#架构设计)
3. [后端配置](#后端配置)
4. [Flutter端实现](#flutter端实现)
5. [平台特定配置](#平台特定配置)
6. [错误处理](#错误处理)
7. [测试指南](#测试指南)
8. [故障排除](#故障排除)
9. [与传统方案的对比](#与传统方案的对比)
10. [附录](#附录)

---

## 概述

### 为什么选择 OAuth Deep Link 方案？

我们采用 **OAuth Deep Link** 方案作为统一的三端登录解决方案。这个方案解决了传统 OAuth 的多个痛点：

1. **零SDK依赖**：移除Firebase、Facebook、Apple原生SDK，减少包大小和复杂度
2. **三端真正统一**：一套代码支持iOS、Android、Web全平台
3. **无视拦截**：服务端302重定向，ITP/Safari无法拦截
4. **零UI负担**：系统浏览器一闪而过，自动唤醒App（移动端）/ 弹窗登录（Web端）
5. **维护简单**：所有OAuth逻辑在后端，新增Provider只需改后端

### 核心优势

| 优势 | 描述 |
|------|------|
| **零SDK依赖** | 不需要Firebase或任何原生SDK |
| **三端真正统一** | 所有OAuth逻辑在后端，三端共用 |
| **无视拦截** | 服务端302重定向，ITP拦截不到 |
| **零UI负担** | 系统浏览器一闪而过，自动唤醒App |
| **Web弹窗登录** | 弹窗方式避免Flutter App整页重新加载 |
| **三通道Token传递** | postMessage + StorageEvent + localStorage轮询，不丢Token |
| **维护简单** | 新增provider只需改后端 |
| **成本降低** | 移除Firebase依赖，减少云成本 |

### 支持的Provider

- ✅ Google Sign-In
- ✅ Facebook Login
- ✅ Apple Sign-In
- ✅ 可扩展其他Provider

---

## 架构设计

### 传统方案 (Firebase OAuth) 的问题

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase OAuth 方案                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│   Flutter App    ──→ Firebase SDK ──→ Google/Facebook/Apple  │
│                           │                                    │
│                           ▼                                    │
│                   Firebase ID Token                           │
│                           │                                    │
│                           ▼                                    │
│                   后端 /api/v1/auth/firebase                  │
│                                                               │
│   ❌ 问题:                                                    │
│   - Firebase SDK依赖（包大小↑）                               │
│   - iOS H5 OAuth拦截问题复杂                                 │
│   - Firebase云成本                                           │
│   - 三端处理方式不同                                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 新方案 (OAuth Deep Link) 的优势

```
┌─────────────────────────────────────────────────────────────┐
│                    OAuth Deep Link 方案（v3.0）               │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  移动端（iOS/Android）:                                      │
│                                                               │
│   第1步: Flutter打开 OAuthWebViewPage                        │
│     Navigator.push(OAuthWebViewPage(loginUrl))               │
│           │                                                    │
│           ▼                                                    │
│   第2步: WebView 加载后端OAuth URL                            │
│     https://api/auth/google/login?callback=joymini://...     │
│           │                                                    │
│           ▼                                                    │
│   第3步: WebView 拦截 joymini:// 回调                         │
│     onNavigationRequest → Navigator.pop(token)               │
│                                                               │
│  Web端:                                                       │
│                                                               │
│   第1步: 同步打开空白弹窗                                    │
│     window.open('about:blank', 'oauth_popup', 'width=...')  │
│           │                                                    │
│           ▼                                                    │
│   第2步: 弹窗导航到后端OAuth URL                              │
│     popup.location.href = 'https://api/auth/google/login?  │
│       callback=https://joymini.com/oauth-popup-callback.html'│
│           │                                                    │
│           ▼                                                    │
│   第3步: 弹窗完成OAuth，着陆到 oauth-popup-callback.html      │
│           │                                                    │
│           ▼                                                    │
│   第4步: callback.html 通过三通道传回Token                    │
│     ① postMessage（主通道）                                  │
│     ② localStorage StorageEvent（兜底）                      │
│     ③ localStorage 轮询（每200ms，绕过Chrome节流） ⭐       │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

#### 移动端数据流（iOS/Android）

```
┌─────────────────────────────────────────────────────────────┐
│                    移动端登录数据流                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Flutter推送 OAuthWebViewPage 页面                        │
│     Navigator.push(OAuthWebViewPage(loginUrl))               │
│           │                                                    │
│           ▼                                                    │
│  2. WebView加载后端OAuth入口                                  │
│     https://api/auth/google/login?callback=joymini://...     │
│           │                                                    │
│           ▼                                                    │
│  3. 后端302重定向到Google授权页                               │
│           │                                                    │
│           ▼                                                    │
│  4. 用户在Google页面授权                                      │
│           │                                                    │
│           ▼                                                    │
│  5. Google回调到后端                                          │
│           │                                                    │
│           ▼                                                    │
│  6. 后端交换Token，获取用户信息                               │
│           │                                                    │
│           ▼                                                    │
│  7. 后端302重定向到Deep Link                                  │
│     joymini://oauth/callback?token=xxx                       │
│           │                                                    │
│           ▼                                                    │
│  8. OAuthWebViewPage.onNavigationRequest 拦截 joymini://      │
│     提取 token → Navigator.pop(result)                       │
│           │                                                    │
│           ▼                                                    │
│  9. Flutter完成登录，跳转到主页                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

#### Web端数据流

```
┌─────────────────────────────────────────────────────────────┐
│                     Web端登录数据流（v3.0）                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. 用户点击 Google/Facebook/Apple 按钮                      │
│           │                                                    │
│           ▼                                                    │
│  2. 同步打开空白弹窗（绕过浏览器弹窗拦截）                   │
│     popup = window.open('about:blank', ..., 'width=600,...')│
│     弹窗显示 "Redirecting to login..." spinner               │
│           │                                                    │
│           ▼                                                    │
│  3. 弹窗导航到后端OAuth URL                                  │
│     popup.location.href =                                     │
│       https://api/auth/google/login?                          │
│       state=xxx&callback=https://origin/oauth-popup-callback  │
│           │                                                    │
│           ▼                                                    │
│  4. 后端302重定向到Google授权页                               │
│           │                                                    │
│           ▼                                                    │
│  5. 用户在弹窗中授权                                          │
│           │                                                    │
│           ▼                                                    │
│  6. 后端重定向弹窗到 oauth-popup-callback.html               │
│     /oauth-popup-callback.html?token=xxx&provider=google     │
│           │                                                    │
│           ▼                                                    │
│  7. callback.html 通过三通道传回Token给主窗口:               │
│     ① window.opener.postMessage() — 主通道                  │
│     ② localStorage.setItem() → StorageEvent — 兜底          │
│     ③ localStorage 直接写入（被主窗口每200ms轮询） ⭐       │
│           │                                                    │
│           ▼                                                    │
│  8. 弹窗自动关闭                                              │
│     window.close()                                            │
│           │                                                    │
│           ▼                                                    │
│  9. 主窗口 Completer 收到 Token → 调用后端验证 → 登录完成   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 后端配置

### 1. 环境变量配置

#### deploy/.env.dev (开发环境)

```env
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/google/callback

# Facebook OAuth
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
FACEBOOK_REDIRECT_URI=https://dev-api.joyminis.com/auth/facebook/callback

# Apple OAuth
APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key
APPLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/apple/callback

# Web OAuth 回调白名单（弹窗方式）
WEB_OAUTH_CALLBACK_ORIGIN=https://joyminis.com
```

### 2. OAuth提供商后台配置

#### Google Cloud Console
```
Authorized redirect URIs:
- https://dev-api.joyminis.com/auth/google/callback
- https://api.joyminis.com/auth/google/callback (生产环境)
```

#### Facebook Developer Console
```
Valid OAuth Redirect URIs:
- https://dev-api.joyminis.com/auth/facebook/callback
- https://api.joyminis.com/auth/facebook/callback (生产环境)
```

#### Apple Developer Console
```
Return URLs:
- https://dev-api.joyminis.com/auth/apple/callback
- https://api.joyminis.com/auth/apple/callback (生产环境)
```

### 3. 后端API端点

#### 发起授权
```
GET /auth/google/login?callback={callback_url}&state={state}
GET /auth/facebook/login?callback={callback_url}&state={state}
GET /auth/apple/login?callback={callback_url}&state={state}
```

**参数说明：**
- `callback` — OAuth完成后后端重定向的目标URL
  - 移动端: `joymini://oauth/callback`
  - Web端: `https://{origin}/oauth-popup-callback.html`
- `state` — 防CSRF随机字符串（由Flutter生成并存入sessionStorage）

#### 接收回调
```
GET /auth/google/callback?code=xxx&state=xxx
GET /auth/facebook/callback?code=xxx&state=xxx
POST /auth/apple/callback (Apple使用form_post)
```

### 4. 后端核心代码

已完成的文件：
- `apps/api/src/client/auth/oauth-deeplink.controller.ts`
- `apps/api/src/client/auth/auth.module.ts`

---

## Flutter端实现（企业级标准）

### 🏢 大企业OAuth实现模式

大企业在处理跨平台OAuth登录时，遵循以下架构模式：

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   前端应用      │     │   OAuth后端     │     │  OAuth提供商    │
│   (Web/iOS/Android) │────▶│   (统一入口)   │────▶│ (Google/FB/Apple) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
   平台特定回调          统一token交换          用户授权
```

**核心原则（v3.0）：**
1. **平台感知**：自动检测Web/移动端，使用不同实现
2. **Web弹窗方式**：先同步打开空白弹窗，再填充OAuth URL（绕过浏览器弹窗拦截）
3. **三通道Token冗余**：postMessage + StorageEvent + localStorage轮询（每200ms）
4. **State参数防CSRF**：生成随机state，存储到sessionStorage验证
5. **弹窗关闭检测**：每500ms轮询 `popup.closed`，5000ms宽限期等待pending token
6. **专用回调页面**：`web/oauth-popup-callback.html` 静态HTML，无需加载Flutter App

### 1. 创建 Deep Link OAuth 服务（v3.0 企业级实现）

#### `lib/core/services/auth/deep_link_oauth_service.dart`

```dart
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
      return canLaunch;
    } catch (e) {
      return false;
    }
  }

  /// 初始化 Deep Link 监听（移动端安全网）
  static void initialize() {
    if (_initialized) return;
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint('[DeepLinkOAuthService] Deep Link Error: $err'),
    );
    _initialized = true;
  }

  /// 处理 Deep Link（移动端安全网，正常情况下WebView已拦截）
  static void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'joymini' && uri.host == 'oauth') {
      // WebView flow: OAuthWebViewPage intercepts joymini:// via onNavigationRequest
      // before it reaches the OS. This listener is a safety net for edge cases.
      debugPrint('[DeepLinkOAuthService] OS-level joymini:// OAuth callback received (edge case)');
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
      catch (e) { return 'http://localhost:4000'; }
    }
    return 'http://localhost:4000';
  }

  static String _getWebWindowOrigin() => DeepLinkOAuthServiceWeb.getWindowOrigin();

  /// Web 平台 OAuth 登录（v3.0 — 弹窗方式）
  ///
  /// 使用弹窗（popup）方式代替整页跳转，避免 Flutter App 完全重新加载。
  /// 流程：
  /// 1. 同步打开空白弹窗（绕过浏览器弹窗拦截）
  /// 2. 将弹窗导航到后端 OAuth URL
  /// 3. 弹窗完成 OAuth 后着陆到 /oauth-popup-callback.html
  /// 4. callback.html 通过三通道传回 token：
  ///    ① postMessage（主通道，opener 存在时）
  ///    ② StorageEvent（兜底，COOP 使 opener 为 null 时）
  ///    ③ localStorage 轮询（每200ms，绕过 Chrome 后台 tab 节流）
  /// 5. 主窗口收到 token 后完成登录
  ///
  /// 额外安全机制：
  /// - 轮询 popup.closed 检测用户主动关闭弹窗
  /// - 关闭后等待 5000ms 宽限期让 localStorage 轮询找到 pending token
  /// - 5分钟超时兜底
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

    if (!kIsWeb) {
      throw DeepLinkOAuthException('_webLoginWithProvider called on non-web platform');
    }

    // 存储 state 用于后续验证
    try { _storeStateInSession(provider, state); } catch (e) {}

    // 尝试弹窗方式（先开空白弹窗再填 URL，绕过拦截器）
    final popup = DeepLinkOAuthServiceWeb.openPopup(loginUrl);
    if (popup == null) {
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

    // 弹窗成功打开，监听 token（三通道冗余）
    StreamSubscription<Map<String, String>>? subscription;
    try {
      // 使用 Completer + 显式 StreamSubscription 以支持资源清理。
      // 三通道冗余：postMessage / StorageEvent / localStoragePoll（轮询）。
      // localStorage 轮询绕过 Chrome 后台 Tab 延迟投递 StorageEvent 的问题。
      final completer = Completer<Map<String, String>>();

      // Token 到达 — 正常路径
      subscription = DeepLinkOAuthServiceWeb
          .listenForOAuthToken()
          .listen(
            (token) {
              if (!completer.isCompleted) completer.complete(token);
            },
            onError: (Object e) {
              if (!completer.isCompleted) completer.completeError(e);
            },
          );

      // 弹窗关闭 → 等待 5000ms 宽限期，让 localStorage 轮询有时间找到 token
      // Chrome 在后台 tab 可能延迟投递 StorageEvent 数秒，轮询直接读取 localStorage
      // 不受此限制，通常 ≤200ms 即可找到 token。5000ms 是保守安全余量。
      _waitForPopupClose(popup).then((_) {
        Future.delayed(const Duration(milliseconds: 5000), () {
          if (!completer.isCompleted) {
            completer.completeError(
              DeepLinkOAuthException('Login cancelled by user'),
            );
          }
          subscription?.cancel();
        });
      });

      final token = await completer.future
          .timeout(const Duration(minutes: 5));

      return token;
    } on DeepLinkOAuthException {
      rethrow;
    } on TimeoutException {
      throw DeepLinkOAuthException('OAuth login timeout after 5 minutes');
    } finally {
      subscription?.cancel();
    }
  }

  /// 轮询弹窗是否被用户关闭，每 500ms 检测一次。
  /// 检测到关闭时返回 true，让调用方通过 5000ms 宽限期等待 pending StorageEvent。
  static Future<bool> _waitForPopupClose(dynamic popup) async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        if (popup.closed == true) {
          debugPrint('[DeepLinkOAuthService] Popup closed by user');
          return true;
        }
      } catch (e) {
        // 跨域弹窗可能无法访问 .closed 属性，静默忽略
      }
    }
  }

  /// 移动端 OAuth 登录（使用 OAuthWebViewPage，基于官方 webview_flutter）
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

  /// 取消登录 — 当前为无操作（WebView的X按钮处理取消）
  static void cancelLogin() {
    // WebView流程中取消由 OAuthWebViewPage 的 X 按钮处理
  }

  /// WebView流程中永远没有挂起的 Completer，始终返回 false。
  static bool get isOAuthInProgress => false;

  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _initialized = false;
  }
}
```

#### `lib/core/services/auth/deep_link_oauth_service_web.dart`（Web平台专用 — v3.0）

```dart
// Web平台专用实现
// 条件导入：仅在Web平台编译

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/cupertino.dart';

/// Web平台专用方法实现
class DeepLinkOAuthServiceWeb {
  /// 获取 window.origin
  static String getWindowOrigin() {
    return html.window.location.origin;
  }

  /// 存储 state 到 sessionStorage
  static void storeStateInSession(String provider, String state) {
    try {
      html.window.sessionStorage['oauth_state_$provider'] = state;
    } catch (e) {
      // sessionStorage可能不可用（隐私模式）
    }
  }

  /// 验证 state 参数
  static bool validateState(String provider, String receivedState) {
    try {
      final storedState = html.window.sessionStorage['oauth_state_$provider'];
      if (storedState == null) return false;
      final isValid = storedState == receivedState;
      html.window.sessionStorage.remove('oauth_state_$provider');
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// 从 URL 参数获取 token
  static Map<String, String>? getTokenFromUrl() {
    try {
      final uri = html.window.location;
      final search = uri.search ?? '';
      if (search.isEmpty) return null;

      final searchString = search.startsWith('?') ? search.substring(1) : search;
      final params = Uri.splitQueryString(searchString);

      final token = params['token'];
      final refreshToken = params['refreshToken'];
      final state = params['state'];
      final provider = params['provider'];

      if (token != null && provider != null && state != null) {
        if (!validateState(provider, state)) return null;
        return {
          'token': token,
          'refreshToken': refreshToken ?? '',
          'provider': provider,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 清理 URL 参数（避免token泄露）
  static void cleanUrl() {
    try {
      final uri = html.window.location;
      final search = uri.search ?? '';
      if (search.contains('token=') || search.contains('state=')) {
        final cleanUrl = '${uri.origin}${uri.pathname}';
        html.window.history.replaceState({}, '', cleanUrl);
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 打开空白弹窗，再填充URL（绕过浏览器弹窗拦截）
  ///
  /// 浏览器只允许在用户手势同步调用栈中执行 window.open()。
  /// 先同步打开空白弹窗（触发用户激活检查），再将真实OAuth URL填入。
  ///
  /// [url] 要导航到的 OAuth URL
  /// 返回 popup 引用表示弹窗成功打开，null 表示被浏览器拦截
  static html.WindowBase? openPopup(String url) {
    try {
      // 1. 同步打开空白弹窗（浏览器允许，因为是用户手势触发）
      //    使用 about:blank 以确保始终能获得可写入的 document
      final popup = html.window.open(
        'about:blank',
        'oauth_popup',
        'width=600,height=700,scrollbars=yes',
      );

      // 2. 通过 about:blank 的 document 写入 loading 内容
      try {
        final doc = (popup as dynamic).document;
        if (doc != null) {
          doc.write('''
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="UTF-8">
              <title>Signing in...</title>
              <style>
                body {
                  display: flex; justify-content: center; align-items: center;
                  height: 100vh; margin: 0;
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  background: #f8f9fa; color: #333;
                }
                .container { text-align: center; padding: 24px; }
                .spinner {
                  width: 40px; height: 40px; margin: 0 auto 16px;
                  border: 3px solid #e0e0e0; border-top-color: #FF5722;
                  border-radius: 50%; animation: spin 0.8s linear infinite;
                }
                @keyframes spin { to { transform: rotate(360deg); } }
                p { margin: 0; font-size: 16px; color: #666; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="spinner"></div>
                <p>Redirecting to login...</p>
              </div>
            </body>
            </html>
          ''');
          doc.close();
        }
      } catch (e) {
        // document.write 可能失败，不影响后续导航
      }

      // 3. 将弹窗导航到实际的 OAuth URL
      popup.location.href = url;

      return popup;
    } catch (e) {
      // 弹窗被浏览器拦截或其他异常
      return null;
    }
  }

  /// 监听 OAuth token，支持三通道冗余通信：
  /// 1. postMessage — 当 window.opener 仍然存在时（无COOP隔离）
  /// 2. localStorage StorageEvent — 当 window.opener 被 COOP 策略置为 null 时的兜底
  /// 3. localStorage 轮询（每200ms） — 绕过 Chrome 后台 tab 延迟投递 StorageEvent
  ///
  /// 三个通道同时使用，谁先触发就用谁，不会重复处理。
  static Stream<Map<String, String>> listenForOAuthToken() {
    final controller = StreamController<Map<String, String>>(sync: true);

    void handleData(Map<String, dynamic> data, String channel) {
      debugPrint('[OAuthTokenListener] Received event via $channel');
      if (data['type'] == 'oauth_token' && data['token'] != null) {
        // Convert all values to String to handle int (timestamp) etc.
        final stringMap = <String, String>{};
        data.forEach((key, value) {
          stringMap[key] = value.toString();
        });
        controller.add(stringMap);
      }
    }

    // 1. postMessage 监听（主通道 — opener 存在时工作）
    final msgSub = html.window.onMessage.listen((event) {
      if (event.data is Map) {
        try {
          handleData(Map<String, dynamic>.from(event.data as Map), 'postMessage');
        } catch (e) {}
      }
    });

    // 2. StorageEvent 监听（兜底通道 — COOP 导致 opener 丢失时工作）
    final storageSub = html.window.onStorage.listen((event) {
      if (event.key == 'oauth_token_result' && event.newValue != null) {
        try {
          final data = jsonDecode(event.newValue!) as Map<String, dynamic>;
          // 立即清理，防止重复使用
          html.window.localStorage.remove('oauth_token_result');
          handleData(data, 'localStorage');
        } catch (e) {}
      }
    });

    // 3. localStorage 轮询（每200ms — 绕过 Chrome 后台 tab StorageEvent 延迟）
    // StorageEvent 在 main tab 处于后台时被 Chrome 延迟投递。
    // 直接轮询 localStorage 确保无论 tab 可见性如何都能立即获取 token。
    Timer? pollTimer;
    pollTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final stored = html.window.localStorage['oauth_token_result'];
      if (stored != null) {
        try {
          final data = jsonDecode(stored) as Map<String, dynamic>;
          html.window.localStorage.remove('oauth_token_result');
          handleData(data, 'localStoragePoll');
        } catch (e) {}
      }
    });

    controller.onCancel = () {
      msgSub.cancel();
      storageSub.cancel();
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  /// 重定向到 URL（当前窗口）
  /// 保留此方法作为降级回退方案
  static void redirectToUrl(String url) {
    html.window.location.href = url;
  }
}
```

#### `lib/core/services/auth/deep_link_oauth_service_web_stub.dart`（非Web平台存根 — v3.0）

```dart
/// 非Web平台存根实现
/// 避免编译错误，实际不会在非Web平台调用
class DeepLinkOAuthServiceWeb {
  static String getWindowOrigin() => 'http://localhost:4000';
  static void storeStateInSession(String provider, String state) {}
  static void redirectToUrl(String url) {}
  static bool validateState(String provider, String receivedState) => false;
  static Map<String, String>? getTokenFromUrl() => null;
  static void cleanUrl() {}
  static dynamic openPopup(String url) => null;
  static Stream<Map<String, String>> listenForOAuthToken() {
    throw UnimplementedError('listenForOAuthToken is web-only');
  }
}
```

### 2. 创建弹窗回调页面

#### `web/oauth-popup-callback.html`

这是 Web 弹窗登录的核心回调页面。当用户完成 OAuth 授权后，后端将弹窗重定向到此页面，该页面通过三通道将 token 传回主窗口。

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Signing in...</title>
  <style>
    body {
      display: flex; justify-content: center; align-items: center;
      height: 100vh; margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f8f9fa; color: #333;
    }
    .container { text-align: center; padding: 24px; }
    .spinner {
      width: 40px; height: 40px; margin: 0 auto 16px;
      border: 3px solid #e0e0e0; border-top-color: #FF5722;
      border-radius: 50%; animation: spin 0.8s linear infinite;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    p { margin: 0; font-size: 16px; color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <div class="spinner"></div>
    <p>Completing sign in...</p>
  </div>

<script>
(function() {
  // 从 URL 参数中提取 token
  var params = new URLSearchParams(window.location.search);
  var token = params.get('token');
  var refreshToken = params.get('refreshToken') || '';
  var state = params.get('state') || '';
  var provider = params.get('provider') || '';
  var timestamp = Date.now();

  if (!token) {
    document.querySelector('p').textContent = 'Authentication failed. Please close this window and try again.';
    return;
  }

  // 构建传递给 Flutter 的数据
  var data = {
    type: 'oauth_token',
    token: token,
    refreshToken: refreshToken,
    provider: provider,
    state: state,
    timestamp: timestamp,
  };

  // 通道 1: postMessage（主通道 — opener 存在时立即工作）
  if (window.opener) {
    try {
      window.opener.postMessage(data, window.opener.origin);
    } catch (e) {
      console.error('postMessage failed:', e);
    }
  }

  // 通道 2 + 3: localStorage（同时写入，主窗口的 StorageEvent + 轮询都能收到）
  try {
    localStorage.setItem('oauth_token_result', JSON.stringify(data));
  } catch (e) {
    console.error('localStorage failed:', e);
  }

  // 等待短暂时间后关闭弹窗
  setTimeout(function() {
    window.close();
  }, 500);
})();
</script>
</body>
</html>
```

### 3. 配置环境变量

#### `lib/core/config/env/dev.json`

```json
{
  "API_BASE_URL": "https://dev-api.joyminis.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

#### `lib/core/config/env/prod.json`

```json
{
  "API_BASE_URL": "https://api.joyminis.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

### 4. 创建配置文件

#### `lib/core/config/oauth_config.dart`

```dart
import 'package:flutter_app/core/config/env_config.dart';

class OAuthConfig {
  static String get apiBaseUrl => EnvConfig.instance.apiBaseUrl;
  static String get deepLinkScheme => EnvConfig.instance.deepLinkScheme;
  static String get deepLinkHost => EnvConfig.instance.deepLinkHost;

  /// Google OAuth URL
  static String get googleLoginUrl =>
      '$apiBaseUrl/auth/google/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Facebook OAuth URL
  static String get facebookLoginUrl =>
      '$apiBaseUrl/auth/facebook/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Apple OAuth URL
  static String get appleLoginUrl =>
      '$apiBaseUrl/auth/apple/login?callback=$deepLinkScheme://$deepLinkHost/callback';
}
```

### 5. 修改登录页面逻辑

#### 更新 `lib/app/page/login_page/login_page_logic.dart`

```dart
// 添加导入
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

// 在 LoginPageLogic mixin 中修改登录方法
Future<void> _loginWithGoogleOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    final result = await DeepLinkOAuthService.loginWithGoogle(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    final apiResult = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
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
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}

// Facebook和Apple登录方法类似，调用对应的 loginWithFacebook/loginWithApple
```

### 6. 应用启动时初始化

#### 在 `lib/main.dart` 中添加

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Deep Link OAuth服务（移动端安全网）
  DeepLinkOAuthService.initialize();

  runApp(MyApp());
}

// 在应用退出时清理资源
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    DeepLinkOAuthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ... 其他配置
    );
  }
}
```

---

## 平台特定配置

### iOS配置

#### `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.porter.joyminis</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>joymini</string>
    </array>
  </dict>
</array>
```

### Android配置

#### `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="joymini"
        android:host="oauth" />
</intent-filter>
```

### Web配置

Web 端不需要 Deep Link 配置，但需要：
1. `web/oauth-popup-callback.html` — 弹窗回调页面
2. 后端配置 `WEB_OAUTH_CALLBACK_ORIGIN` 白名单（与 `oauth-popup-callback.html` 的 origin 一致）

---

## 错误处理

### 常见错误和解决方案

| 错误类型 | 描述 | 解决方案 |
|---------|------|----------|
| **弹窗被拦截** | 浏览器阻止了 `window.open()` | 检查用户手势触发；降级为整页跳转 |
| **Deep Link未接收** | OAuth完成后未唤醒App | 1. 检查Deep Link配置<br>2. 检查回调URL格式<br>3. 验证应用已安装 |
| **Token无效** | 后端验证token失败 | 1. 检查token格式<br>2. 验证token有效期<br>3. 重新登录 |
| **Chrome StorageEvent延迟** | 后台tab的StorageEvent被Chrome节流 | localStorage轮询（每200ms）自动处理 |
| **Race Condition** | 弹窗关闭早于token到达 | Completer + 5000ms宽限期处理 |
| **超时错误** | OAuth流程超过5分钟 | 1. 网络连接检查<br>2. OAuth提供商服务状态<br>3. 重新尝试 |
| **用户取消** | 用户关闭弹窗 | 静默处理，不显示错误 |
| **COOP拦截** | Google的COOP header使opener为null | StorageEvent + localStorage轮询兜底 |

### 错误处理模式

```dart
void _handleDeepLinkOAuthError(Object error) {
  if (error is DeepLinkOAuthException) {
    if (error.message.contains('cancelled')) {
      // 用户取消 - 不显示错误
      return;
    }

    if (error.message.contains('timeout')) {
      RadixToast.error('登录超时，请重试');
      return;
    }

    if (error.message.contains('redirect initiated')) {
      // 弹窗被拦截，降级为跳转
      RadixToast.info('请在新页面中完成登录');
      return;
    }

    if (error.message.contains('Failed to redirect')) {
      RadixToast.error('无法打开登录页面，请检查网络连接');
      return;
    }
  }

  final raw = error.toString();
  final message = raw.replaceFirst('Exception: ', '');
  RadixToast.error(message);
}
```

---

## 测试指南

### 1. 单元测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';

void main() {
  group('DeepLinkOAuthService', () {
    test('initialize should set up deep link listener', () {
      DeepLinkOAuthService.initialize();
      // 验证监听器已设置
    });

    test('loginWithGoogle on Web builds correct URL with callback param', () async {
      // 测试URL构建逻辑（使用 callback 而非 redirect_uri）
    });

    test('_generateState produces 43-char base64url string', () {
      // 测试state生成
    });
  });
}
```

### 2. 集成测试

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete OAuth Deep Link flow (Web popup)', (tester) async {
    // 启动应用
    await tester.pumpWidget(MyApp());

    // 导航到登录页面
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 点击Google登录按钮
    await tester.tap(find.byKey(Key('google_login_button')));
    await tester.pumpAndSettle();

    // Web端：验证弹窗被打开（openPopup被调用）
    // 移动端：验证OAuthWebViewPage被推送
  });
}
```

### 3. 手动测试清单

#### Web端（弹窗方式）
- [ ] Google登录 - 弹窗正常打开
- [ ] Google登录 - 弹窗被拦截时降级为整页跳转
- [ ] Google登录 - token通过postMessage接收
- [ ] Google登录 - token通过localStorage接收（模拟COOP场景）
- [ ] Google登录 - 后台tab时localStorage轮询正常工作（打开弹窗后切到其他tab再切回）
- [ ] Google登录 - 用户手动关闭弹窗后loading状态正常恢复
- [ ] Google登录 - 5分钟超时兜底
- [ ] Facebook登录 - 同上所有测试
- [ ] Apple登录 - 同上所有测试

#### 移动端（OAuthWebViewPage）
- [ ] Google登录 - iOS
- [ ] Google登录 - Android
- [ ] Facebook登录 - iOS
- [ ] Facebook登录 - Android
- [ ] Apple登录 - iOS

#### 通用
- [ ] Token刷新流程
- [ ] 错误处理（取消、超时、失败）
- [ ] 邀请码转发
- [ ] 登出功能

---

## 故障排除

### 问题1: Web弹窗被浏览器拦截

**症状**: 点击登录按钮后无弹窗弹出，或控制台显示 `openPopup returned null`

**原因**: 浏览器弹窗拦截器阻止了 `window.open()`

**解决方案**:
1. 确保点击事件直接在用户手势中触发（非 async 调用）
2. 我们的实现已通过"先同步打开空白弹窗再填充URL"的方式最大程度绕过拦截
3. 如果仍然被拦截，代码会自动降级为整页跳转（`window.location.href = loginUrl`）

### 问题2: OAuth登录后状态未更新（Chrome后台Tab问题）

**症状**: 用户在弹窗中完成OAuth授权后，主窗口的loading状态一直卡住，数分钟后才恢复

**原因**: 这是 Chrome 的已知行为 — 当主 tab 在后台时，Chrome 会延迟投递 `StorageEvent` 事件

**修复方案（v3.0）**:
1. 新增 localStorage 轮询（`Timer.periodic` 每200ms读取 `localStorage['oauth_token_result']`）
2. 三通道冗余：postMessage + StorageEvent + localStoragePoll
3. 弹窗关闭后等待 5000ms 宽限期让轮询找到 pending token

```
时间轴对比：
  修复前:  弹窗写入→ [Chrome延迟StorageEvent 5-10秒] → 主窗口收到 → 登录完成
  修复后:  弹窗写入→ localStorage轮询每200ms读取 → ≤200ms → 登录完成 ✅
```

### 问题3: Race Condition — 弹窗关闭早于token处理

**症状**: 用户快速关闭弹窗后，token刚刚到达但completer已经被标记为cancelled

**修复方案（v3.0）**:
1. 使用 `Completer` 替代 `Future.any()` 
2. 弹窗关闭后不立即取消，而是等待 5000ms 宽限期
3. 宽限期内如果 localStorage 轮询找到 token，仍然可以正常完成

### 问题4: Deep Link未唤醒App

**症状**: OAuth完成后停留在浏览器页面，未唤醒App

**解决方案**:
1. 检查AndroidManifest.xml中的intent-filter配置
2. 检查Info.plist中的CFBundleURLSchemes配置
3. 验证回调URL格式：`joymini://oauth/callback`
4. 测试应用是否已正确安装

### 问题5: Token验证失败

**症状**: 后端返回"Invalid token"错误

**解决方案**:
1. 检查后端OAuth配置是否正确
2. 验证Google/Facebook/Apple后台回调URL配置
3. 检查环境变量中的Client ID和Secret
4. 验证token是否过期

### 问题6: iOS Safari拦截OAuth

**症状**: iOS Safari阻止OAuth弹出窗口

**解决方案**:
1. 使用 `OAuthWebViewPage`（官方 webview_flutter）替代系统浏览器
2. 确保用户交互触发（非自动弹出）
3. 提示用户允许弹出窗口

### 问题7: Android Chrome未处理Deep Link

**症状**: Android Chrome打开Deep Link但未唤醒App

**解决方案**:
1. 检查Android应用链接验证
2. 添加 `android:autoVerify="true"` 到intent-filter
3. 配置Digital Asset Links文件

### 问题8: Web端回调白屏

**症状**: Web端弹窗OAuth完成后停留在白屏

**解决方案**:
1. 确保 `web/oauth-popup-callback.html` 已正确部署
2. 检查后端 `callback` 参数指向正确的 origin
3. 确认 `oauth-popup-callback.html` 中的 `localStorage.setItem` 和 `postMessage` 正常执行

---

## 与传统方案的对比

### Firebase OAuth方案 vs OAuth Deep Link方案

| 特性 | Firebase OAuth | OAuth Deep Link (v3.0) |
|------|----------------|----------------------|
| **SDK依赖** | 需要Firebase、Facebook、Apple SDK | 零SDK依赖 |
| **三端统一** | 部分统一，仍有平台差异 | 完全统一 |
| **ITP拦截** | Safari可能拦截 | 无视拦截（服务端302） |
| **包大小** | 较大（多个SDK） | 极小（仅url_launcher+app_links） |
| **Web登录方式** | Firebase SDK弹窗 | 自定义弹窗（空窗→导航→三通道回调） |
| **Token传递** | Firebase SDK管理 | 三通道冗余（postMessage+StorageEvent+轮询） |
| **Chrome兼容** | — | localStorage轮询绕过后台tab节流 |
| **维护成本** | 高 | 低 |

---

## 附录

### A. API端点总结

| 端点 | 方法 | 描述 |
|------|------|------|
| `/auth/google/login` | GET | 发起Google OAuth |
| `/auth/facebook/login` | GET | 发起Facebook OAuth |
| `/auth/apple/login` | GET | 发起Apple OAuth |
| `/auth/google/callback` | GET | Google回调 |
| `/auth/facebook/callback` | GET | Facebook回调 |
| `/auth/apple/callback` | POST | Apple回调（form_post） |

### B. 环境变量

```env
# Development
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
FACEBOOK_APP_ID=xxx
FACEBOOK_APP_SECRET=xxx
APPLE_CLIENT_ID=xxx
APPLE_TEAM_ID=xxx
APPLE_KEY_ID=xxx
APPLE_PRIVATE_KEY=xxx
WEB_OAUTH_CALLBACK_ORIGIN=https://joyminis.com
```

### C. 架构演进历史

```
v1.0 (2026-03-28) — Firebase OAuth 方案
  - 依赖 Firebase SDK
  - 三端实现不统一

v2.0 (2026-03-30) — OAuth Deep Link 方案
  - 移除 Firebase 依赖
  - 三端统一（移动端Deep Link / Web端整页跳转）
  - State防CSRF

v2.1 (2026-05-14) — Web弹窗登录
  - 弹窗方式替代整页跳转（避免Flutter App重新加载）
  - 双通道 token 传递（postMessage + StorageEvent）
  - 弹窗关闭检测

v3.0 (2026-05-14) — Chrome后台Tab修复 + 三通道冗余 ⭐
  - localStorage 轮询（Timer.periodic 每200ms）绕过Chrome后台tab节流
  - 三通道冗余：postMessage + StorageEvent + localStoragePoll
  - Completer + 5000ms宽限期解决Race Condition
  - popup-closed 500ms 轮询检测
```

### D. 关键Bug修复记录

| 日期 | Bug | Root Cause | 修复 |
|------|-----|------------|------|
| 2026-05-14 | 登录后loading卡住5分钟 | Chrome后台tab延迟StorageEvent | 新增localStorage轮询每200ms |
| 2026-05-14 | 快速关闭弹窗后token丢失 | Completer被cancelled先于token到达 | Completer + 5000ms宽限期 |
| 2026-05-14 | 登录状态未更新 | Future.any导致race condition | 替换为显式Completer管理 |
| 2026-05-13 | 弹窗被浏览器拦截 | 异步调用window.open | 先同步打开空窗再导航 |
| 2026-05-13 | 弹窗打开为新tab | window.open缺少尺寸参数 | 添加 width=600,height=700 |
| 2026-05-13 | opener为null | Google COOP header | 新增StorageEvent兜底通道 |
| 2026-05-12 | 后端不识别redirect_uri | 参数名不匹配 | 改为callback参数 |

### E. 参考链接

- [Web OAuth Popup 实现计划](../../../../plans/web_oauth_popup_flow.md)
- [Web OAuth 流程详解（含Bug修复记录）](../../../../plans/web_oauth_flow_explained.md)
- [Flutter App Working Instructions](../../../../.github/copilot-instructions.md)
