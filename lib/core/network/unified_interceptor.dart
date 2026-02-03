import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../utils/device_utils.dart';
import '../../utils/time/server_time_helper.dart';
import '../../app/routes/app_router.dart';
import '../../utils/events/event_bus.dart';
import '../../utils/events/global_events.dart';
import '../api/http_client.dart';
import 'error_config.dart';

class UnifiedInterceptor extends QueuedInterceptor {
  final Dio _rawDio;

  UnifiedInterceptor(this._rawDio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. 加指纹头
    final fingerprint = await DeviceUtils.getFingerprint();
    final now = DateTime.now().millisecondsSinceEpoch.toString();

    options.headers['signature_nonce'] = now;
    options.headers['currentTime'] = now;
    options.headers['lang'] = 'en';
    options.headers['x-device-id'] = fingerprint.deviceId;
    options.headers['x-device-model'] = fingerprint.deviceModel;
    options.headers['x-platform'] = fingerprint.platform;

    // 2. 加 Token (直接读 Http 的静态缓存)
    final noAuth = options.extra['noAuth'] == true;
    if (!noAuth) {
      final token = await Http.getToken(); // 调用 Http 的方法
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final data = response.data;
    if (data == null || data is! Map<String, dynamic>) {
      return handler.reject(_asDioError(response, 'Invalid response data'));
    }

    // 校准时间
    ServerTimeHelper.updateOffset(response.headers.value('x-server-time'));

    final code = data['code'] as int?;
    final message = (data['message'] as String?) ?? 'Unknown error';

    //  核心分发逻辑
    final strategy = ErrorConfig.getStrategy(code);

    switch (strategy) {
      case ErrorStrategy.success:
        response.data = data['data']; // 解包
        handler.next(response);
        break;

      case ErrorStrategy.refresh:
        await _handleTokenRefresh(response, handler);
        break;

      case ErrorStrategy.security:
        EventBus().emit(GlobalEvent(GlobalEventType.deviceBanned));
        handler.reject(_asDioError(response, 'Security Block')); // 阻断
        break;

      case ErrorStrategy.redirect:
        _handleRedirect(code!);
        handler.reject(_asDioError(response, (data['errorMsg'] as String?) ?? message));
        break;

      case ErrorStrategy.toast:
      default:
        _showToast(response, data, message);
        handler.reject(_asDioError(response, (data['errorMsg'] as String?) ?? message));
        break;
    }
  }

  // --- 辅助方法 ---

  void _showToast(Response response, Map data, String defaultMsg) {
    if (response.requestOptions.extra['noErrorToast'] != true) {
      RadixToast.error((data['errorMsg'] as String?) ?? defaultMsg);
     // Fluttertoast.showToast(msg: (data['errorMsg'] as String?) ?? defaultMsg);
    }
  }

  void _handleRedirect(int code) {
    if (code == 92001) {
      appRouter.go('/me/setting');
    } else if (code == 93001) {
      appRouter.go('/me/kyc/verify');
    }
    else if (code == 18023) {
      appRouter.go('/me/bind-phone');
    }
  }

  DioException _asDioError(Response resp, String message) {
    return DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      type: DioExceptionType.badResponse,
      message: message,
    );
  }

  // --- Token 刷新 (调用 Http 里的核心逻辑) ---
  Future<void> _handleTokenRefresh(Response response, ResponseInterceptorHandler handler) async {
    final reqExtra = response.requestOptions.extra;
    if (reqExtra['skipTokenGuard'] == true) {
      handler.reject(_asDioError(response, 'Token Error'));
      return;
    }

    final latestToken = Http.tokenCache; // 访问 Http 变量
    final requestToken = response.requestOptions.headers['Authorization'] as String?;

    // 1. 只是本地旧了？
    if (latestToken != null && requestToken != 'Bearer $latestToken') {
      if (await _retryRequest(response, latestToken, handler)) return;
    }

    // 2. 真的过期？尝试刷新
    if (reqExtra['__retryAfterRefresh__'] != true) {
      //  调用 Http 类公开出来的刷新方法 (不再是 private)
      final refreshed = await Http.tryRefreshToken(_rawDio);
      if (refreshed) {
        response.requestOptions.extra['__retryAfterRefresh__'] = true;
        if (await _retryRequest(response, Http.tokenCache!, handler)) return;
      }
    }

    // 3. 失败 -> 登出
    await Http.performLogout();
    handler.reject(_asDioError(response, 'Session expired'));
  }

  Future<bool> _retryRequest(Response originalResponse, String newToken, ResponseInterceptorHandler handler) async {
    final options = originalResponse.requestOptions;
    options.headers['Authorization'] = 'Bearer $newToken';
    try {
      final newResp = await _rawDio.fetch(options);
      final data = newResp.data;
      // 这里简易判断是否成功
      if (data != null && data['code'] == 10000) {
        newResp.data = data['data']; // Unwrap
        handler.resolve(newResp);
        return true;
      }
    } catch (_) {}
    return false;
  }
}