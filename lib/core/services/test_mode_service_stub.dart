// 非 Web 平台桩实现
// 条件导入：仅在非 Web 平台（iOS/Android/MacOS/Linux/Windows）编译

class TestModeServiceWeb {
  /// 非 Web 平台始终返回 null，因为无法访问浏览器 URL。
  static String? getTypeParam() => null;
}
