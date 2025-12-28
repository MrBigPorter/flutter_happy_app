import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../utils/device_utils.dart';
import 'env.dart';

typedef FromJson<T> = T Function(dynamic json);

class Http {
  Http._();

  /// 业务 Dio：带拦截器（Queued）
  static final Dio _dio = Dio(
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

  /// 干净 Dio：专门用于 refresh / retry（无拦截器，避免死锁）
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

  static const _successCodes = <int>[10000];
  static const _tokenErrorCodes = <int>[40100];

  static bool _navigatingToLogin = false;

  static String? _tokenCache;

  /// 刷新锁：并发只刷新一次，其他请求等同一个 Future
  static Future<bool>? _refreshingFuture;

  static Future<void> init() async {
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // 通用头
          final fingerprint = await DeviceUtils.getFingerprint();
          final now = DateTime.now().millisecondsSinceEpoch.toString();

          options.headers['signature_nonce'] = now;
          options.headers['currentTime'] = now;
          options.headers['lang'] = 'en';
          options.headers['x-device-id'] = fingerprint.deviceId;
          options.headers['x-device-model'] = fingerprint.deviceModel;
          options.headers['x-platform'] = fingerprint.platform;

          // 注入 token（除非显式标记 noAuth）
          final noAuth = options.extra['noAuth'] == true;
          if (!noAuth) {
            final token = await _getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },

        onResponse: (response, handler) async {
          final data = response.data;

          if (data == null || data is! Map<String, dynamic>) {
            return handler.reject(_asDioError(response, 'Invalid response data'));
          }

          final code = data['code'] as int?;
          final message = (data['message'] as String?) ?? 'Unknown error';
          final resData = data['data'];

          if (code == null) {
            return handler.reject(_asDioError(response, 'Missing code'));
          }

          // 成功：把 data 透给调用方
          if (_successCodes.contains(code)) {
            response.data = resData;
            return handler.next(response);
          }

          final reqExtra = response.requestOptions.extra;
          final noToast = reqExtra['noErrorToast'] == true;
          final skipTokenGuard = reqExtra['skipTokenGuard'] == true;

          // token 失效处理
          if (_tokenErrorCodes.contains(code) && !skipTokenGuard) {
            final requestToken = response.requestOptions.headers['Authorization'] as String?;
            final latestToken = _tokenCache;

            final isTokenOutdated = latestToken != null &&
                requestToken != null &&
                requestToken != 'Bearer $latestToken';

            // 1) 如果只是“旧 token”导致失败：直接用新 token retry（走 rawDio）
            if (isTokenOutdated) {
              final options = response.requestOptions;
              options.headers['Authorization'] = 'Bearer $latestToken';
              try {
                final newResp = await _rawDio.fetch(options);
                final unwrapped = _unwrapApiResponse(newResp);
                if (unwrapped != null) return handler.resolve(unwrapped);
              } catch (_) {}
            }

            // 定义一个变量标记是否“抢救成功”
            bool rescueSuccess = false;
            // 2) 真过期：刷新一次，再 retry（避免无限循环）
            final alreadyRetried = reqExtra['__retryAfterRefresh__'] == true;
            if (!alreadyRetried) {
              final refreshed = await _tryRefreshToken();
              if (refreshed) {
                final options = response.requestOptions;
                options.extra['__retryAfterRefresh__'] = true;

                final newToken = _tokenCache;
                if (newToken != null && newToken.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $newToken';
                }

                try {
                  // 尝试重试
                  final newResp = await _rawDio.fetch(options);
                  // 只要重试的网络请求通了（哪怕业务 Code 不是 10000），就算抢救成功
                  // 我们不能因为业务报错（比如图片模糊）就让用户退登
                  rescueSuccess = true;

                  // 尝试解包，如果解包成功直接返回
                  final unwrapped = _unwrapApiResponse(newResp);
                  if (unwrapped != null) {
                    return handler.resolve(unwrapped);
                  }

                } catch (e) {
                  // 如果重试过程报错（比如 FormData 无法复用），
                  // 我们认定这次请求失败，但不代表 Token 无效（因为刷新已经成功了）
                  // 所以我们要 Reject 这次请求，但阻止代码向下执行去 ClearToken
                  return handler.reject(_asDioError(response, 'Retry failed: ${e.toString()}'));
                }
              }
            }

            // 3) 刷新失败：清 token + 去登录
            await _clearToken();

            if (onTokenInvalid != null) {
              await onTokenInvalid!();
            }

            if (!_navigatingToLogin) {
              _navigatingToLogin = true;
              appRouter.go('/login');
              Future.delayed(const Duration(seconds: 1), () {
                _navigatingToLogin = false;
              });
            }
          } else if (code == 92001) {
            appRouter.go('/me/setting');
          } else if (code == 93001) {
            appRouter.go('/me/kyc/verify');
          } else if (code == 18023) {
            appRouter.go('/me/bind-phone');
          }

          if (!noToast) {
            final errorMsg = (data['errorMsg'] as String?) ?? message;
            Fluttertoast.showToast(
              msg: errorMsg,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }

          return handler.reject(_asDioError(response, (data['errorMsg'] as String?) ?? message));
        },

        onError: (e, handler) {
          final noToast = e.requestOptions.extra['noErrorToast'] == true;
          print('HTTP Error: ${e.message}');
          print('Request Options: ${e.requestOptions}');
          if (!noToast) {
            Fluttertoast.showToast(
              msg: e.message ?? 'Network error',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }
          handler.next(e);
        },
      ),
    );
  }

  /// 对外暴露
  static Dio get dio => _dio;

  /// 便捷请求
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

  /// refresh：只允许一个在跑，其他请求等它
  static Future<bool> _tryRefreshToken() async {
    if (_refreshingFuture != null) return _refreshingFuture!;
    final completer = Completer<bool>();
    _refreshingFuture = completer.future;

    try {
      final storage = authInitialTokenStorage();
      final tokens = await storage.read();
      final refreshToken = tokens.$2;

      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }

      // 用 rawDio 直接打 refresh（不要进队列拦截器）
      final resp = await _rawDio.post(
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

      final code = map['code'] as int?;
      if (code != 10000) {
        completer.complete(false);
        return false;
      }

      final data = map['data'];
      if (data is! Map<String, dynamic>) {
        completer.complete(false);
        return false;
      }

      final tokensMap = data['tokens'];
      if (tokensMap is! Map<String, dynamic>) {
        completer.complete(false);
        return false;
      }

      final newAccessToken = tokensMap['accessToken'] as String?;
      final newRefreshToken = tokensMap['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        completer.complete(false);
        return false;
      }

      _tokenCache = newAccessToken;
      await storage.save(newAccessToken, newRefreshToken);

      if (onTokenRefresh != null) {
        await onTokenRefresh!(newAccessToken, newRefreshToken);
      }

      completer.complete(true);
      return true;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshingFuture = null;
    }
  }

  /// Token 管理
  static void setToken(String token) {
    _tokenCache = token;
  }

  static Future<void> clearToken() => _clearToken();

  static Future<String?> _getToken() async {
    if (_tokenCache != null) return _tokenCache;
    final auth = authInitialTokenStorage();
    final tokens = await auth.read();
    _tokenCache = tokens.$1;
    return tokens.$1;
  }

  static Future<void> Function()? onTokenInvalid;
  static Future<void> Function(String access, String? refresh)? onTokenRefresh;

  static Future<void> _clearToken() async {
    _tokenCache = null;
    final storage = authInitialTokenStorage();
    await storage.clear();
  }

  /// 工具：把 rawDio 的标准响应也“剥壳”为 data，保持你上层 API 的一致性
  static Response? _unwrapApiResponse(Response resp) {
    final raw = resp.data;
    if (raw == null || raw is! Map<String, dynamic>) return null;

    final code = raw['code'] as int?;
    if (code == null) return null;

    if (_successCodes.contains(code)) {
      resp.data = raw['data'];
      return resp;
    }

    return null;
  }

  static DioException _asDioError(Response resp, String message) {
    return DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
      message: message,
    );
  }

  static T _decode<T>(dynamic raw, FromJson<T>? parse) {
    if (parse != null) return parse(raw);
    return raw as T;
  }
}