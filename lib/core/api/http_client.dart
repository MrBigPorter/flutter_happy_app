// lib/app/network/http_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_app/core/store/auth/auth_initial.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'env.dart';

typedef FromJson<T> = T Function(dynamic json);

class Http {
  Http._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseEffective,
      // <- 用 final 值，不要 const
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
  static const _tokenErrorCodes = <int>[40100];
  static bool _navigatingToLogin = false;

  static String? _tokenCache;
  static bool _isRefreshingToken = false;

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
            print("Injecting token: $token");
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) async {
          // HTTP 非 2xx 也允许走到这里，由我们按后端 code 统一处理
          final data = response.data;

          if (data == null || data is! Map<String, dynamic>) {
            return handler.reject(
              _asDioError(response, 'Invalid response data'),
            );
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
          final reqExtra = response.requestOptions.extra;
          final noToast = reqExtra['noErrorToast'] == true;

          // Whether to skip token guard
          final skipTokenGuard = reqExtra['skipTokenGuard'] == true;

          if (_tokenErrorCodes.contains(code) && !skipTokenGuard) {

           final alreadyRetries = reqExtra['__retryAfterRefresh__'] == true;

           if(!alreadyRetries){
             final refreshed = await _tryRefreshToken();
             if(refreshed){
               // successfully refreshed token, retry original request
               final options = response.requestOptions;
               // mark as retried, avoid infinite loop
                options.extra['__retryAfterRefresh__'] = true;

                // update Authorization header
               final newToken = _tokenCache;

               if(newToken != null && newToken.isNotEmpty) {
                 options.headers['Authorization'] = 'Bearer $newToken';
               }

               try{
                 // retry to appy the last request
                 final newResponse = await _dio.fetch(options);
                 return handler.resolve(newResponse);
               }catch(_){
                 // failed to retry, will continue to logout
               }

             }
           }

            // remove token from cache
            await _clearToken();

            if(onTokenInvalid != null){
              // notify authProvider to logout
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
            // 无地址
            appRouter.go('/me/setting');
          } else if (code == 93001) {
            // 未完成 KYC
            appRouter.go('/me/kyc/verify');
          } else if (code == 18023) {
            // 未绑定手机
            appRouter.go('/me/bind-phone');
          }

          if (!noToast) {
            final errorMsg = (data['errorMsg'] as String?) ?? message;
            print("Showing error toast: $errorMsg");
            Fluttertoast.showToast(
              msg: errorMsg,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.TOP,
            );
          }

          return handler.reject(
            _asDioError(response, (data['errorMsg'] as String?) ?? message),
          );
        },
        onError: (e, handler) {
          // 统一网络错误提示（可由 noErrorToast 关闭）
          final noToast = e.requestOptions.extra['noErrorToast'] == true;
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

  static Future<bool> _tryRefreshToken() async {
    if(_isRefreshingToken){
      return false;
    }
    _isRefreshingToken = true;

    try{
      // get refresh token from storage
      final storage = authInitialTokenStorage();
      final tokens = await storage.read();
      final refreshToken = tokens.$2;

      if(refreshToken == null || refreshToken.isEmpty){
        return false;
      }

      // apply refresh token API
      final resp = await _dio.post(
          '/api/v1/auth/refresh',
          data: {
            'refresh_token': refreshToken,
          },
          options: Options(
            extra: {
              'noAuth': true, // avoid injecting token
              'noErrorToast': true, // avoid error toast
              'skipTokenGuard' : true, // avoid token invalid handling, avoid loop
            },
          )
      );

      // parse response
      final data = resp.data;
      if(data == null || data is! Map<String, dynamic>){
        return false;
      }

      final tokensMap = data['tokens'] as Map<String, dynamic>?;
      if(tokensMap == null){
        return false;
      }

      final newAccessToken = tokensMap['access_token'] as String?;
      final newRefreshToken = tokensMap['refresh_token'] as String?;

      if(newAccessToken == null || newAccessToken.isEmpty){
        return false;
      }

      // update token cache and storage
      _tokenCache = newAccessToken;
      await storage.save(newAccessToken, newRefreshToken);

      // notify auth provider
      if(onTokenRefresh != null){
        await onTokenRefresh!(newAccessToken, newRefreshToken);
      }

     return true;

    }catch(e){
      return false;
    }finally {
      _isRefreshingToken = false;
    }

  }

  /// ---- Token 管理 ---- set to memory cache
  static void setToken(String token)  {
    _tokenCache = token;
  }

  static Future<void> clearToken() => _clearToken();

  static Future<String?> _getToken() async {
    if (_tokenCache != null) return _tokenCache;
    final auth = authInitialTokenStorage();
    final tokens = await auth.read();
    return tokens.$1;
  }

  static Future<void> Function()? onTokenInvalid;

  static Future<void> Function(String access, String? refresh)? onTokenRefresh;

  static Future<void> _clearToken() async {
    _tokenCache = null;
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
