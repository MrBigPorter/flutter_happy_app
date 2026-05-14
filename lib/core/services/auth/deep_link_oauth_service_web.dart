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
      // 静默失败，不影响主要功能
    }
  }

  /// 验证 state 参数
  static bool validateState(String provider, String receivedState) {
    try {
      final storedState = html.window.sessionStorage['oauth_state_$provider'];
      if (storedState == null) {
        return false;
      }

      final isValid = storedState == receivedState;

      // 验证后清理
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

      // 手动解析URL参数
      final searchString = search.startsWith('?') ? search.substring(1) : search;
      final params = Uri.splitQueryString(searchString);

      final token = params['token'];
      final refreshToken = params['refreshToken'];
      final state = params['state'];
      final provider = params['provider'];

      if (token != null && provider != null && state != null) {
        // 验证 state
        if (!validateState(provider, state)) {
          return null;
        }

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
      // 移除URL中的token参数
      final uri = html.window.location;
      final search = uri.search ?? '';

      if (search.contains('token=') || search.contains('state=')) {
        // 创建不带参数的URL
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
      //    第三参数指定弹窗尺寸，让浏览器以 popup 窗口（非新 tab）打开
      final popup = html.window.open(
        'about:blank',
        'oauth_popup',
        'width=600,height=700,scrollbars=yes',
      );

      // 2. 通过 about:blank 的 document 写入 loading 内容
      //    （popup 的实际类型是 WindowBase，document 需要 dynamic 访问）
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

  /// 监听 OAuth token，支持双通道通信：
  /// 1. postMessage — 当 window.opener 仍然存在时（无COOP隔离）
  /// 2. localStorage StorageEvent — 当 window.opener 被 COOP 策略置为 null 时的兜底
  ///
  /// 两个通道同时使用，谁先触发就用谁，不会重复处理。
  static Stream<Map<String, String>> listenForOAuthToken() {
    final controller = StreamController<Map<String, String>>(sync: true);

    void handleData(Map<String, dynamic> data, String channel) {
      debugPrint('[OAuthTokenListener] Received event via $channel');
      if (data['type'] == 'oauth_token' && data['token'] != null) {
        debugPrint('[OAuthTokenListener] Valid token found, adding to stream');
        // Convert all values to String to handle int (timestamp) etc.
        final stringMap = <String, String>{};
        data.forEach((key, value) {
          stringMap[key] = value.toString();
        });
        controller.add(stringMap);
      } else {
        debugPrint('[OAuthTokenListener] Invalid data: type=${data['type']}, hasToken=${data['token'] != null}');
      }
    }

    // 1. postMessage 监听（主通道 - opener 存在时工作）
    final msgSub = html.window.onMessage.listen((event) {
      debugPrint('[OAuthTokenListener] postMessage event received');
      if (event.data is Map) {
        try {
          handleData(Map<String, dynamic>.from(event.data as Map), 'postMessage');
        } catch (e) {
          debugPrint('[OAuthTokenListener] postMessage parse error: $e');
        }
      } else {
        debugPrint('[OAuthTokenListener] postMessage data is not Map: ${event.data.runtimeType}');
      }
    });

    // 2. StorageEvent 监听（兜底通道 - COOP 导致 opener 丢失时工作）
    final storageSub = html.window.onStorage.listen((event) {
      debugPrint('[OAuthTokenListener] StorageEvent: key=${event.key}, newValue=${event.newValue?.substring(0, 30)}...');
      if (event.key == 'oauth_token_result' && event.newValue != null) {
        try {
          final data = jsonDecode(event.newValue!) as Map<String, dynamic>;
          debugPrint('[OAuthTokenListener] StorageEvent parsed: type=${data['type']}, hasToken=${data['token'] != null}');
          // 立即清理，防止重复使用
          html.window.localStorage.remove('oauth_token_result');
          handleData(data, 'localStorage');
        } catch (e) {
          debugPrint('[OAuthTokenListener] StorageEvent parse error: $e');
        }
      }
    });

    // 3. localStorage 轮询（新增 — 绕过 Chrome 后台 tab StorageEvent 延迟）
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
        } catch (e) {
          debugPrint('[OAuthTokenListener] Poll parse error: $e');
        }
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
  /// 保留此方法作为回退方案
  static void redirectToUrl(String url) {
    html.window.location.href = url;
  }
}
