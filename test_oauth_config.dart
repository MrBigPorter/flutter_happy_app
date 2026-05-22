import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';

void main() async {
  // 测试开发环境配置
  const devApiBaseUrl = 'https://dev-api.joyminis.com';

  final devConfigOk = await DeepLinkOAuthService.checkOAuthConfiguration(devApiBaseUrl);

  if (!devConfigOk) {
    // OAuth 配置可能的排查项：
    // 1. 检查后端是否运行在 devApiBaseUrl
    // 2. 检查后端 /auth/google/login 端点是否可用
    // 3. 检查 Google Cloud Console 中的 Authorized redirect URIs 配置
    // 4. 检查后端环境变量 GOOGLE_REDIRECT_URI 是否正确
  }

  // 测试 URL 构建
  final testUrl = '$devApiBaseUrl/auth/google/login?callback=joymini%3A%2F%2Foauth%2Fcallback';

  // 测试 Deep Link 监听
  DeepLinkOAuthService.initialize();

  // 建议：
  // 1. 手动访问以下 URL 测试 OAuth 流程：$testUrl
  // 2. 授权后应该重定向到 joymini://oauth/callback?token=xxx
  // 3. 如果返回 404，检查后端 /auth/google/callback 端点

  // 清理
  DeepLinkOAuthService.dispose();
}
