import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/api/http_client.dart';
import 'sse_types.dart';

/// Debug flag — set to true to trace SSE chunk arrival timing.
/// When enabled, logs each line's delta from stream start so you can
/// distinguish network-layer buffering from rendering-layer batching.
const _kTraceSse = true;

/// SSE 流式客户端（Dio 版）
///
/// 通过 Dio 的 ResponseType.stream 接收 SSE 流。
/// 适用于所有平台（包括 Web）。
///
/// 原生平台会通过 sse_client.dart 的条件导出自动切换到
/// sse_client_io.dart（dart:io HttpClient 版）。
class SseClient {
  CancelToken? _cancelToken;

  /// Controller 在构造时就创建，确保订阅总能拿到有效的 stream
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
    cancel();

    _isActive = true;
    _cancelToken = CancelToken();

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
      final response = await Http.rawDio.post<ResponseBody>(
        '/api/v1/ai/customer/chat-stream',
        data: {
          'message': message,
          'sessionId': sessionId,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 180),
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          },
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 429) {
        final body = response.data;
        String reason = '操作太频繁，请稍后再试';
        if (body != null) {
          try {
            final decoded = jsonDecode(
                await body.stream.cast<List<int>>().transform(utf8.decoder).join());
            reason = decoded['error'] ?? reason;
          } catch (_) {}
        }
        _controller.addError(reason);
        return;
      }

      if (response.statusCode != 200) {
        _controller.addError('服务器错误 (${response.statusCode})');
        return;
      }

      final responseBody = response.data;
      if (responseBody == null) {
        _controller.addError('服务器无响应');
        return;
      }

      // ── 逐行解析 SSE 流 ──
      bool hasReceivedFirstToken = false;
      Timer? timeoutTimer;

      timeoutTimer = Timer(firstTokenTimeout, () {
        if (!hasReceivedFirstToken) {
          _controller.addError('AI 无响应，请重试');
          _isActive = false;
        }
      });

      // ── 诊断追踪 ──
      final traceId = DateTime.now().microsecondsSinceEpoch.toString();
      final streamStart = DateTime.now();
      int lineCount = 0;
      if (_kTraceSse) {
        debugPrint('[SSE:$traceId] Stream started at ${streamStart.toIso8601String()}');
      }

      final lines = responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final rawLine in lines) {
        lineCount++;
        final line = rawLine.trim();
        if (line.isEmpty || !line.startsWith('data: ')) continue;

        if (_kTraceSse) {
          final now = DateTime.now();
          final delta = now.difference(streamStart).inMilliseconds;
          debugPrint('[SSE:$traceId] Line $lineCount delta=${delta}ms raw="${rawLine.substring(0, rawLine.length.clamp(0, 80))}"');
        }

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

          if (_kTraceSse) debugPrint('[SSE:$traceId]  >> add($typeStr)');
          _controller.add(event);

          if (typeStr == 'token') {
            if (_kTraceSse) debugPrint('[SSE:$traceId]  >> delay 30ms');
            await Future.delayed(const Duration(milliseconds: 30));
          }

          if (typeStr == 'done' || typeStr == 'error') {
            timeoutTimer.cancel();
            _isActive = false;
            return;
          }
        } catch (_) {
          continue;
        }
      }

      timeoutTimer.cancel();
      if (_isActive) {
        _controller.add(const SseEvent(type: SseEventType.done, data: {'type': 'done'}));
        _isActive = false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return;
      }
      final msg = e.type == DioExceptionType.connectionTimeout
          ? '连接超时'
          : e.type == DioExceptionType.receiveTimeout
              ? '接收超时'
              : '连接中断: ${e.message}';
      _controller.addError(msg);
      _isActive = false;
    } catch (e) {
      _controller.addError('未知错误: $e');
      _isActive = false;
    } finally {
      subscription?.cancel();
      _isActive = false;
    }
  }

  /// 取消当前请求
  void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _isActive = false;
  }

  /// 释放资源
  void dispose() {
    cancel();
    _controller.close();
  }
}
