// SSE 共享类型 — 同时被 SseClient（Dio 版）和 NativeSseClient（dart:io 版）使用
// ViewModel 只需导入此文件获取 SseEvent / SseEventType

/// SSE 事件类型
enum SseEventType { token, step, done, error, transfer }

/// 解析后的 SSE 事件
class SseEvent {
  final SseEventType type;
  final Map<String, dynamic> data;

  const SseEvent({required this.type, required this.data});

  @override
  String toString() => 'SseEvent($type, $data)';
}
