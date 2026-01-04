import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';

import '../network/unified_interceptor.dart';
import 'env.dart';

typedef FromJson<T> = T Function(dynamic json);

class Http {
  Http._();

  // =========================================================
  // 1. 基础配置 (保持不变)
  // =========================================================

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseEffective,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
      validateStatus: (_) => true,
      receiveDataWhenStatusError: true,
    ),
  );

  /// 干净 Dio (给拦截器刷新 Token 用)
  static final Dio _rawDio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseEffective,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
      validateStatus: (_) => true,
      receiveDataWhenStatusError: true,
    ),
  );

  // =========================================================
  // 2. 共享变量 (去掉下划线，让拦截器能访问)
  // =========================================================

  //  改动：变成 public，拦截器要读它
  static String? tokenCache;

  // 改动：变成 public，拦截器要读锁
  static Future<bool>? refreshingFuture;

  // ️ 改动：变成 public
  static bool navigatingToLogin = false;

  static Future<void> Function()? onTokenInvalid;
  static Future<void> Function(String access, String? refresh)? onTokenRefresh;

  // =========================================================
  // 3. 初始化 (核心改动)
  // =========================================================

  static Future<void> init() async {
    //  以前这里有几百行代码，现在全部委托给 UnifiedInterceptor
    // 我们把 _rawDio 传给它，让它去处理刷新逻辑
    _dio.interceptors.add(UnifiedInterceptor(_rawDio));
  }

  // =========================================================
  // 4. 对外 API (完全保持不变，这就是你想要的)
  // =========================================================

  static Dio get dio => _dio;

  static Future<T> get<T>(
      String path, {
        Map<String, dynamic>? query,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        FromJson<T>? fromJson,
      }) async {
    final resp = await _dio.get(
      path,
      queryParameters: query ?? queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return _decode<T>(resp.data, fromJson);
  }

  static Future<T> post<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        FromJson<T>? fromJson,
      }) async {
    final resp = await _dio.post(
      path,
      data: data,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _decode<T>(resp.data, fromJson);
  }

  static Future<T> put<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        FromJson<T>? fromJson,
      }) async {
    final resp = await _dio.put(
      path,
      data: data,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _decode<T>(resp.data, fromJson);
  }

  static Future<T> delete<T>(
      String path, {
        dynamic data,
        Map<String, dynamic>? query,
        Options? options,
        CancelToken? cancelToken,
        FromJson<T>? fromJson,
      }) async {
    final resp = await _dio.delete(
      path,
      data: data,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    );
    return _decode<T>(resp.data, fromJson);
  }

  // =========================================================
  // 5. 辅助方法 (去掉下划线，让拦截器调用)
  // =========================================================

  //  改动：去掉了前面的 _
  static void setToken(String token) {
    tokenCache = token;
  }

  // ️ 改动：去掉了前面的 _
  static Future<void> clearToken() async {
    tokenCache = null;
    final storage = authInitialTokenStorage();
    await storage.clear();
  }

  //  改动：去掉了前面的 _
  static Future<String?> getToken() async {
    if (tokenCache != null) return tokenCache;
    final auth = authInitialTokenStorage();
    final tokens = await auth.read();
    tokenCache = tokens.$1;
    return tokens.$1;
  }

  //  改动：去掉了前面的 _，拦截器发现 Token 失效时调用
  static Future<void> performLogout() async {
    await clearToken();
    if (onTokenInvalid != null) await onTokenInvalid!();

    if (!navigatingToLogin) {
      navigatingToLogin = true;
      appRouter.go('/login');
      Future.delayed(const Duration(seconds: 1), () {
        navigatingToLogin = false;
      });
    }
  }

  //  改动：去掉了前面的 _，拦截器需要刷新 Token 时调用
  static Future<bool> tryRefreshToken(Dio rawDio) async {
    if (refreshingFuture != null) return refreshingFuture!;
    final completer = Completer<bool>();
    refreshingFuture = completer.future;

    try {
      final storage = authInitialTokenStorage();
      final tokens = await storage.read();
      final refreshToken = tokens.$2;

      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }

      // 使用传入的 rawDio (或者是 _rawDio 也可以，既然在类内部)
      final resp = await rawDio.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {
          'noAuth': true,
          'noErrorToast': true,
          'skipTokenGuard': true,
        }),
      );

      final map = resp.data;
      if (map == null || map is! Map<String, dynamic>) {
        completer.complete(false);
        return false;
      }

      // 注意：这里检查的是 API 的业务码
      final code = map['code'] as int?;
      if (code != 10000) {
        completer.complete(false);
        return false;
      }

      final data = map['data'];
      final tokensMap = data['tokens'];
      final newAccessToken = tokensMap['accessToken'] as String?;
      final newRefreshToken = tokensMap['refreshToken'] as String?;

      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        tokenCache = newAccessToken; // 更新内存
        await storage.save(newAccessToken, newRefreshToken); // 更新硬盘

        if (onTokenRefresh != null) {
          await onTokenRefresh!(newAccessToken, newRefreshToken!);
        }
        completer.complete(true);
        return true;
      }

      completer.complete(false);
      return false;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      refreshingFuture = null;
    }
  }

  // 内部解码辅助
  static T _decode<T>(dynamic raw, FromJson<T>? parse) {
    if (parse != null) return parse(raw);
    return raw as T;
  }
}