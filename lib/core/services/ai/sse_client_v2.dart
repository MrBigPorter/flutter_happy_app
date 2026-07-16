// 两阶段 SSE 协议客户端 — 按平台自动选择实现
//
// 默认（dart.library.io 不可用 = Web）→ sse_client_web.dart（EventSource）
// 原生（dart.library.io 可用 = iOS/Android/macOS）→ sse_client_io.dart（dart:io GET）
export 'sse_client_web.dart'
    if (dart.library.io) 'sse_client_io.dart';
