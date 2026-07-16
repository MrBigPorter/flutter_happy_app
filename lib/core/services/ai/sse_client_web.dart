// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' show EventSource;
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/config/app_config.dart';
import 'sse_types.dart';

/// 两阶段 SSE 客户端（Web 版）
///
/// 使用浏览器原生 EventSource API 连接 SSE 流。
/// dart:html EventSource 只能 GET，不能设自定义 header，
/// 因此 JWT 通过 `?token=` 查询参数传递。
///
/// 只能用两阶段协议（先 POST /chat 拿 streamId，再 GET /chat/stream/:id）。
/// 单次 POST + SSE 的老协议走 sse_client_dio.dart。
///
/// 生活类比：收音机
///   调好频率（连 GET URL）→ 自动收听（onMessage）
///   信号断了自动重连（EventSource 内置）→ 但收到 done 后主动关机
class SseClientV2 {
  EventSource? _eventSource;
  late final StreamController<SseEvent> _controller;
  bool _isActive = false;

  /// 事件流 — 外部通过 .listen 消费
  Stream<SseEvent> get events => _controller.stream;

  /// 是否正在接收
  bool get isActive => _isActive;

  SseClientV2() {
    _controller = StreamController<SseEvent>.broadcast();
  }

  /// 连接 SSE 流（阶段 2）
  ///
  /// 先调 POST /chat 拿到 streamId，再调此方法。
  ///
  /// 参数：
  ///   [streamId] — POST /chat 返回的 streamId
  ///   [token] — JWT，会拼进 `?token=` 查询参数
  ///   [firstTokenTimeout] — 首 token 超时，默认 30 秒
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
      // ── 1. 用 EventSource 连 GET 流 ──
      final uri =
          '${AppConfig.apiBaseUrl}/api/v1/ai/customer/chat/stream/$streamId?token=$token';
      _eventSource = EventSource(uri);

      // ── 2. 首 token 超时定时器 ──
      bool hasReceivedFirstToken = false;
      Timer? timeoutTimer;
      timeoutTimer = Timer(firstTokenTimeout, () {
        if (!hasReceivedFirstToken) {
          _controller.addError('AI 无响应，请重试');
          _isActive = false;
          _eventSource?.close();
        }
      });

      // ── 3. 监听消息事件 ──
      _eventSource!.onMessage.listen((event) {
        final raw = event.data as String;
        if (raw.isEmpty) return;

        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          final typeStr = json['type'] as String?;
          if (typeStr == null) return;

          SseEvent sseEvent;
          switch (typeStr) {
            case 'token':
              hasReceivedFirstToken = true;
              timeoutTimer?.cancel();
              sseEvent = SseEvent(type: SseEventType.token, data: json);
              break;
            case 'step':
              sseEvent = SseEvent(type: SseEventType.step, data: json);
              break;
            case 'transfer':
              sseEvent = SseEvent(type: SseEventType.transfer, data: json);
              break;
            case 'done':
              timeoutTimer?.cancel();
              sseEvent = SseEvent(type: SseEventType.done, data: json);
              break;
            case 'error':
              timeoutTimer?.cancel();
              sseEvent = SseEvent(type: SseEventType.error, data: json);
              break;
            default:
              return;
          }

          _controller.add(sseEvent);

          // done/error → 关闭 EventSource 防止浏览器自动重连
          if (typeStr == 'done' || typeStr == 'error') {
            timeoutTimer?.cancel();
            _isActive = false;
            _eventSource?.close();
            return;
          }
        } catch (_) {
          // JSON 解析失败就跳过
        }
      });

      // ── 4. 监听错误事件 ──
      _eventSource!.onError.listen((_) {
        if (!_isActive) return; // 已经 done/error 关闭了
        timeoutTimer?.cancel();
        _controller.addError('SSE 连接失败');
        _isActive = false;
        _eventSource?.close();
      });
    } catch (e) {
      _controller.addError('未知错误: $e');
      _isActive = false;
    } finally {
      subscription?.cancel();
    }
  }

  /// 取消当前连接
  void cancel() {
    _eventSource?.close();
    _eventSource = null;
    _isActive = false;
  }

  /// 释放资源
  void dispose() {
    cancel();
    _controller.close();
  }
}
