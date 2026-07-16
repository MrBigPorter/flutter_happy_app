import 'dart:async';
import 'dart:convert';
import 'dart:io'
    show
        HttpClient,
        HttpClientRequest,
        HttpStatus,
        SocketException,
        HttpException;
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'sse_types.dart';

/// SSE 流式客户端（原生版）
///
/// 使用 dart:io 的 HttpClient 直接发起流式 HTTP 请求，
/// 绕过 Dio 及其 adapter 层，避免第三方库在流式场景下的缓冲问题。
///
/// 仅 iOS / Android / macOS 可用；
/// Web 通过 sse_client.dart 的条件导出自动使用 sse_client_dio.dart。
class SseClient {
  HttpClient? _httpClient;
  HttpClientRequest? _pendingRequest;

  late final StreamController<SseEvent> _controller;
  bool _isActive = false;

  SseClient() {
    _controller = StreamController<SseEvent>.broadcast(
      onCancel: () => cancel(),
    );
  }

  /// 事件流 — 外部通过 .listen 消费
  Stream<SseEvent> get events => _controller.stream;

  /// 是否正在接收
  bool get isActive => _isActive;

  /// 发送消息并开始接收 SSE 流
  Future<void> sendMessage({
    required String message,
    required String sessionId,
    required String token,
    void Function(SseEvent event)? onEvent,
    VoidCallback? onDone,
    void Function(String error)? onError,
    Duration firstTokenTimeout = const Duration(seconds: 30),
  }) async {
    // 如果已有活跃连接，先取消
    cancel();

    _isActive = true;

    // 如果提供了快捷回调，订阅事件流
    StreamSubscription<SseEvent>? subscription;
    if (onEvent != null || onDone != null || onError != null) {
      subscription = _controller.stream.listen(
        onEvent,
        onDone: () {
          onDone?.call();
          _isActive = false;
        },
        onError: (e) {
          onError?.call(e.toString());
          _isActive = false;
        },
        cancelOnError: false,
      );
    }

    try {
      // ── 1. 创建 HttpClient 连接 ──
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 10);

      final uri =
          Uri.parse('${AppConfig.apiBaseUrl}/api/v1/ai/customer/chat-stream');
      _pendingRequest = await _httpClient!.postUrl(uri);

      // 设置请求头
      _pendingRequest!
        ..headers.set('Content-Type', 'application/json')
        ..headers.set('Authorization', 'Bearer $token')
        ..headers.set('Accept', 'text/event-stream')
        ..headers.set('Cache-Control', 'no-cache');

      // 写入请求体
      final bodyBytes = utf8.encode(jsonEncode({
        'message': message,
        'sessionId': sessionId,
      }));
      _pendingRequest!.add(bodyBytes);

      // ── 2. 获取响应 ──
      final response = await _pendingRequest!.close();
      _pendingRequest = null;

      final statusCode = response.statusCode;

      if (statusCode == HttpStatus.tooManyRequests) {
        try {
          final body = await response.transform(utf8.decoder).join();
          final decoded = jsonDecode(body);
          final reason =
              decoded['error'] ?? '操作太频繁，请稍后再试';
          _controller.addError(reason.toString());
        } catch (_) {
          _controller.addError('操作太频繁，请稍后再试');
        }
        return;
      }

      if (statusCode != HttpStatus.ok) {
        _controller.addError('服务器错误 ($statusCode)');
        return;
      }

      // ── 3. 逐行解析 SSE 流 ──
      bool hasReceivedFirstToken = false;
      Timer? timeoutTimer;

      // 首 token 超时定时器
      timeoutTimer = Timer(firstTokenTimeout, () {
        if (!hasReceivedFirstToken) {
          _controller.addError('AI 无响应，请重试');
          _isActive = false;
        }
      });

      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        final jsonStr = line.substring(6);

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final typeStr = json['type'] as String?;
          if (typeStr == null) continue;

          SseEvent event;
          switch (typeStr) {
            case 'token':
              hasReceivedFirstToken = true;
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.token, data: json);
              break;
            case 'step':
              event = SseEvent(type: SseEventType.step, data: json);
              break;
            case 'transfer':
              event = SseEvent(type: SseEventType.transfer, data: json);
              break;
            case 'done':
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.done, data: json);
              break;
            case 'error':
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.error, data: json);
              break;
            default:
              continue;
          }

          _controller.add(event);

          // token 事件后等待一帧，给 Flutter 足够时间渲染中间帧
          if (typeStr == 'token') {
            await Future.delayed(const Duration(milliseconds: 30));
          }

          // done/error 后不再处理后续行
          if (typeStr == 'done' || typeStr == 'error') {
            timeoutTimer.cancel();
            _isActive = false;
            return;
          }
        } catch (_) {
          continue;
        }
      }

      // 流自然结束 → 合成 done 事件
      timeoutTimer.cancel();
      if (_isActive) {
        _controller.add(const SseEvent(
            type: SseEventType.done, data: {'type': 'done'}));
        _isActive = false;
      }
    } on SocketException catch (e) {
      final msg = e.port == 0 ? '连接失败' : '连接中断: ${e.message}';
      _controller.addError(msg);
      _isActive = false;
    } on HttpException catch (e) {
      _controller.addError('HTTP 错误: ${e.message}');
      _isActive = false;
    } on TimeoutException {
      _controller.addError('连接超时');
      _isActive = false;
    } catch (e) {
      if (e is Exception && e.toString().contains('Connection closed')) {
        // 主动取消（cancel 关闭连接导致），不报错
        return;
      }
      _controller.addError('未知错误: $e');
      _isActive = false;
    } finally {
      subscription?.cancel();
      // 确保 HttpClient 被释放
      _httpClient?.close(force: true);
      _httpClient = null;
      _isActive = false;
    }
  }

  /// 取消当前请求
  void cancel() {
    // 强制关闭 HttpClient 会立即中断正在进行的请求
    _httpClient?.close(force: true);
    _httpClient = null;
    _pendingRequest = null;
    _isActive = false;
  }

  /// 释放资源
  void dispose() {
    cancel();
    _controller.close();
  }
}

/// 两阶段 SSE 客户端（原生版）
///
/// 使用 dart:io HttpClient 发起 GET 请求连接 SSE 流。
/// JWT 通过 `?token=` 查询参数传递（因为 GET 请求没有 body）。
///
/// 使用方式：
///   1. POST /api/v1/ai/customer/chat → 拿 streamId
///   2. SseClientV2().connect(streamId, token) → 收 SSE 事件
///
/// 与 SseClient（V1）的区别：
///   V1 = POST + body → 流式响应（单次连接，老协议）
///   V2 = GET + streamId → 流式响应（两阶段，新协议）
class SseClientV2 {
  HttpClient? _httpClient;

  late final StreamController<SseEvent> _controller;
  bool _isActive = false;

  SseClientV2() {
    _controller = StreamController<SseEvent>.broadcast(
      onCancel: () => cancel(),
    );
  }

  /// 事件流 — 外部通过 .listen 消费
  Stream<SseEvent> get events => _controller.stream;

  /// 是否正在接收
  bool get isActive => _isActive;

  /// 连接 SSE 流（阶段 2）
  ///
  /// 先调 POST /chat 拿到 streamId，再调此方法。
  /// 用 GET 请求 + `?token=` 传 JWT，不走 header。
  Future<void> connect({
    required String streamId,
    required String token,
    void Function(SseEvent event)? onEvent,
    VoidCallback? onDone,
    void Function(String error)? onError,
    Duration firstTokenTimeout = const Duration(seconds: 30),
  }) async {
    cancel();

    _isActive = true;

    // ── 快捷回调订阅 ──
    StreamSubscription<SseEvent>? subscription;
    if (onEvent != null || onDone != null || onError != null) {
      subscription = _controller.stream.listen(
        onEvent,
        onDone: () {
          onDone?.call();
          _isActive = false;
        },
        onError: (e) {
          onError?.call(e.toString());
          _isActive = false;
        },
        cancelOnError: false,
      );
    }

    try {
      // ── 1. 创建 HttpClient，发 GET 请求 ──
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 10);

      final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/v1/ai/customer/chat/stream/$streamId?token=$token',
      );
      final request = await _httpClient!.getUrl(uri);

      request.headers.set('Accept', 'text/event-stream');

      // ── 2. 发送并获取响应 ──
      final response = await request.close();

      final statusCode = response.statusCode;

      if (statusCode == HttpStatus.tooManyRequests) {
        try {
          final body = await response.transform(utf8.decoder).join();
          final decoded = jsonDecode(body);
          final reason = decoded['error'] ?? '操作太频繁，请稍后再试';
          _controller.addError(reason.toString());
        } catch (_) {
          _controller.addError('操作太频繁，请稍后再试');
        }
        return;
      }

      if (statusCode == HttpStatus.notFound) {
        _controller.addError('会话已过期或不存在，请重新发送');
        return;
      }

      if (statusCode != HttpStatus.ok) {
        _controller.addError('服务器错误 ($statusCode)');
        return;
      }

      // ── 3. 逐行解析 SSE 流 ──
      bool hasReceivedFirstToken = false;
      Timer? timeoutTimer;

      timeoutTimer = Timer(firstTokenTimeout, () {
        if (!hasReceivedFirstToken) {
          _controller.addError('AI 无响应，请重试');
          _isActive = false;
        }
      });

      final lines = response
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines) {
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        final jsonStr = line.substring(6);

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final typeStr = json['type'] as String?;
          if (typeStr == null) continue;

          SseEvent event;
          switch (typeStr) {
            case 'token':
              hasReceivedFirstToken = true;
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.token, data: json);
              break;
            case 'step':
              event = SseEvent(type: SseEventType.step, data: json);
              break;
            case 'transfer':
              event = SseEvent(type: SseEventType.transfer, data: json);
              break;
            case 'done':
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.done, data: json);
              break;
            case 'error':
              timeoutTimer.cancel();
              event = SseEvent(type: SseEventType.error, data: json);
              break;
            default:
              continue;
          }

          _controller.add(event);

          // token 事件后等待一帧
          if (typeStr == 'token') {
            await Future.delayed(const Duration(milliseconds: 30));
          }

          // done/error 后不再处理后续行
          if (typeStr == 'done' || typeStr == 'error') {
            timeoutTimer.cancel();
            _isActive = false;
            return;
          }
        } catch (_) {
          continue;
        }
      }

      // 流自然结束 → 合成 done 事件
      timeoutTimer.cancel();
      if (_isActive) {
        _controller.add(const SseEvent(
            type: SseEventType.done, data: {'type': 'done'}));
        _isActive = false;
      }
    } on SocketException catch (e) {
      final msg = e.port == 0 ? '连接失败' : '连接中断: ${e.message}';
      _controller.addError(msg);
      _isActive = false;
    } on HttpException catch (e) {
      _controller.addError('HTTP 错误: ${e.message}');
      _isActive = false;
    } on TimeoutException {
      _controller.addError('连接超时');
      _isActive = false;
    } catch (e) {
      if (e is Exception && e.toString().contains('Connection closed')) {
        return;
      }
      _controller.addError('未知错误: $e');
      _isActive = false;
    } finally {
      subscription?.cancel();
      _httpClient?.close(force: true);
      _httpClient = null;
      _isActive = false;
    }
  }

  /// 取消当前连接
  void cancel() {
    _httpClient?.close(force: true);
    _httpClient = null;
    _isActive = false;
  }

  /// 释放资源
  void dispose() {
    cancel();
    _controller.close();
  }
}
