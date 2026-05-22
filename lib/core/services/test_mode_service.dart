import 'test_mode_service_web.dart'
    if (dart.library.io) 'test_mode_service_stub.dart';

/// Test Mode 服务 - 用于 Web 端演示/面试场景
///
/// 当用户访问 `/?type=test` 时，检测 URL 参数并持久化到 SharedPreferences。
/// 在 LoginPage 上自动填入测试账号凭据并显示引导提示。
///
/// 设计原则：
/// - `999999` 仅为 UI 占位符，不是真正验证码，用户仍需点击获取验证码
/// - 非 Web 平台强制关闭 test mode，防止误用
class TestModeService {
  /// SharedPreferences 中存储 test mode 标志的 key
  static const String testModeKey = 'is_test_mode';

  /// 测试账号邮箱
  static const String testEmail = 'mrsuperportertest@gmail.com';

  /// 测试账号验证码占位符（仅 UI 展示用，非真实验证码）
  static const String testCode = '999999';

  /// 检查当前 URL 是否包含 `?type=test` 参数
  static bool isTestParamPresent() {
    return TestModeServiceWeb.getTypeParam() == 'test';
  }
}
