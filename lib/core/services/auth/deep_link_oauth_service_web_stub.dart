// Web平台存根实现
// 用于非Web平台编译

/// Web平台存根实现
class DeepLinkOAuthServiceWeb {
  /// 获取 window.origin
  static String getWindowOrigin() {
    return 'http://localhost:4000';
  }

  /// 存储 state 到 sessionStorage
  static void storeStateInSession(String provider, String state) {
    // 非Web平台无操作
  }

  /// 验证 state 参数
  static bool validateState(String provider, String receivedState) {
    return false;
  }

  /// 从 URL 参数获取 token
  static Map<String, String>? getTokenFromUrl() {
    return null;
  }

  /// 清理 URL 参数（避免token泄露）
  static void cleanUrl() {
    // 非Web平台无操作
  }

  /// 打开空白弹窗（非Web平台不支持）
  static bool openPopup(String url) {
    return false;
  }

  /// 监听 OAuth token（非Web平台不支持）
  /// 返回一个永不发射事件的空 Stream
  static Stream<Map<String, String>> listenForOAuthToken() {
    return const Stream<Map<String, String>>.empty();
  }

  /// 重定向到 URL（当前窗口）
  static void redirectToUrl(String url) {
    // 非Web平台无操作
  }
}
