// lib/app/network/http_client.dart
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'env.dart';

typedef FromJson<T> = T Function(dynamic json);

class Http {
  Http._();
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseEffective,               // <- 用 final 值，不要 const
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
      // 我们自己根据 code 判断成败
      validateStatus: (_) => true,
      receiveDataWhenStatusError: true,
    ),
  );

  static const _kTokenKey = '__t__';
  static const _successCodes = <int>[10000];
  static const _tokenErrorCodes = <int>[20062, 92000, 14004]; // 按你后端定义
  static bool _navigatingToLogin = false;

  static String? _tokenCache;

  static Future<void> init() async {
    // 日志（仅在 dev / 需要时打开）
   /* if (Env.logHttp) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }*/

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 通用头
          final now = DateTime.now().millisecondsSinceEpoch.toString();
          options.headers['signature_nonce'] = now;
          options.headers['currentTime'] = now;
          options.headers['device'] = 'flutter';
          options.headers['lang'] = 'en';

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
          // HTTP 非 2xx 也允许走到这里，由我们按后端 code 统一处理
          final data = response.data;
          if (data is! Map) {
            // 非标准信封，直接当错误抛
            return handler.reject(_asDioError(
              response,
              'Invalid response shape',
            ));
          }

          final code = data['code'] as int?;
          final message = (data['message'] as String?) ?? 'Unknown error';
          final resData = data['data'];

          if (code == null) {
            return handler.reject(_asDioError(response, 'Missing code'));
          }

          if (_successCodes.contains(code)) {
            response.data = resData; // 成功：把 data 透给调用方
            return handler.next(response);
          }

          // 处理需要跳转的业务码
          final noToast = response.requestOptions.extra['noErrorToast'] == true;

          if (_tokenErrorCodes.contains(code)) {
            // token 失效：清除并跳登录（防抖）
            await _clearToken();
            if (!_navigatingToLogin) {
              _navigatingToLogin = true;
              AppRouter.router.replace('/login');
              Future.delayed(const Duration(seconds: 1), () {
                _navigatingToLogin = false;
              });
            }
          } else if (code == 92001) {
            // 无地址
            AppRouter.router.push('/me/setting');
          } else if (code == 93001) {
            // 未完成 KYC
            AppRouter.router.push('/me/kyc/verify');
          } else if (code == 18023) {
            // 未绑定手机
            AppRouter.router.push('/me/bind-phone');
          }

          if (!noToast) {
            final errorMsg = (data['errorMsg'] as String?) ?? message;
            Fluttertoast.showToast(msg: errorMsg);
          }

          return handler.reject(_asDioError(
            response,
            'code $code, msg: $message',
          ));
        },
        onError: (e, handler) {
          // 统一网络错误提示（可由 noErrorToast 关闭）
          final noToast = e.requestOptions.extra['noErrorToast'] == true;
          if (!noToast) {
            Fluttertoast.showToast(msg: e.message ?? 'Network error');
          }
          handler.next(e);
        },
      ),
    );
  }

  /// ---- 对外暴露的 Dio（必要时可直接用） ----
  static Dio get dio => _dio;

  /// ---- 便捷请求：支持 fromJson 类型安全解析 ----
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

  /// ---- Token 管理 ----
  static Future<void> setToken(String token) async {
    _tokenCache = token;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTokenKey, token);
  }

  static Future<void> clearToken() => _clearToken();

  static Future<String?> _getToken() async {
    if (_tokenCache != null) return _tokenCache;
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString(_kTokenKey);
    _tokenCache = t;
    return t;
  }

  static Future<void> _clearToken() async {
    _tokenCache = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
  }

  /// ---- 工具 ----
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