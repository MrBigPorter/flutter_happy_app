// 按平台自动选择 SSE 客户端实现
//
// 原生平台（iOS / Android / macOS）使用 dart:io HttpClient，
// Web 平台使用 Dio（浏览器不支持 dart:io）。
export 'sse_client_dio.dart'
    if (dart.library.io) 'sse_client_io.dart';
