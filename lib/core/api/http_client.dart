
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/app/routes/app_router.dart';

/// A singleton HTTP client using Dio with interceptors for request and response handling.
/// Includes methods for GET, POST, PUT, DELETE requests.
/// Handles token management and error responses globally.
/// Usage:
///   Api.dio.get('/path');
///   Api.get('/path');
///   Api.post('/path', data: {...});
///   Api.put('/path', data: {...});
///   Api.delete('/path', data: {...});
class HttpClient {
  // Base URL for the API
  // static const String baseUrl = 'https://api.example.com';
  static const String baseUrl = 'http://127.0.0.1:5173';
  // Success and token error codes
  static const List<int> successCodes = [10000];
  // Codes indicating token issues
  static const List<int> tokenErrorCodes = [20062, 92000, 14004];

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "Cache-Control": "no-cache",
    },
  ))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add common headers
        options.headers["signature_nonce"] = DateTime.now().millisecondsSinceEpoch.toString();
        options.headers["currentTime"] = DateTime.now().millisecondsSinceEpoch.toString();
        options.headers["device"] = "web";
        options.headers["lang"] = "en";

        final prefs = await SharedPreferences.getInstance();
        options.headers["authorization"] = prefs.getString('__t__') ?? '';
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final data = response.data;
        final code = data['code'] as int;
        final message = data['message'] as String? ?? 'Unknown error';
        final resData = data['data'];

        if(!successCodes.contains(code)){
          final errorMsg = data['errorMsg'] as String?;

          // token is invalid
          if(tokenErrorCodes.contains(code)){
            response.requestOptions.extra = {'noErrorToast': true};
            // clear token and redirect to login
            _clearToken();
            AppRouter.router.replace("/login");
          }

          // no address found, redirect to settings
          if(code == 92001){
            response.requestOptions.extra = {'noErrorToast': true};
            AppRouter.router.push("/me/setting");
          }

          // no kyc found, redirect to kyc
          if(code == 93001){
            response.requestOptions.extra = {'noErrorToast': true};
            AppRouter.router.push("/me/kyc/verify");
          }

          // phone not bound, redirect to bind phone
          if(code == 18023){
            response.requestOptions.extra = {'noErrorToast': true};
             AppRouter.router.push("/me/bind-phone");
          }

          // show error toast
          if(!(response.requestOptions.extra['noErrorToast'] == true)){
            Fluttertoast.showToast(msg: errorMsg ?? message);
          }

          return handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: "code $code, msg: $message",
          ));
        }

        response.data = resData;
        return handler.next(response);

      },
      onError: (DioException e, handler) {
        // Handle errors globally
        Fluttertoast.showToast(msg: e.message ?? "Network error");
        return handler.next(e);
      },
    ));

  static Dio get dio => _dio;

  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('__t__',"");
  }

  static Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onReceiveProgress}) async {
    final response = await _dio.get<T>(path, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onReceiveProgress: onReceiveProgress);
    return response.data as T;
  }

  static Future<T> post<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    final response = await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
    return response.data as T;
  }

  static Future<T> put<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress}) async {
    final response = await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken, onSendProgress: onSendProgress, onReceiveProgress: onReceiveProgress);
    return response.data as T;
  }

  static Future<T> delete<T>(String path, {data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    final response = await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options, cancelToken: cancelToken);
    return response.data as T;
  }
}