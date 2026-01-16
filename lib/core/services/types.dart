// 定义 Token 刷新函数的签名
typedef TokenRefreshCallback = Future<String?> Function();

// 定义 ACK 响应结构
typedef AckResponse = ({bool success, String? message, Map<String, dynamic>? data});

// 统一异常类
class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}