import '../constants/app_errors.dart';

/// 策略枚举：决定怎么处理错误
enum ErrorStrategy {
  success,      //  成功
  refresh,      //  Token过期
  redirect,     //  跳转
  security,     //  风控 (设备锁/黑名单)
  toast,        //  弹窗
  silent,       //  静默
}

class ErrorConfig {

  // =================  配置区域 =================

  static const _successCodes = <int>[10000];
  static const _tokenErrorCodes = <int>[40100];

  // 核心配置表
  static const Map<int, ErrorStrategy> _strategyMap = {
    // --- 业务跳转 ---
    92001: ErrorStrategy.redirect, // 去设置
    93001: ErrorStrategy.redirect, // 去KYC
    18023: ErrorStrategy.redirect, // 去绑手机

    // --- 风控安全 ---
    AppErrors.deviceBlacklisted: ErrorStrategy.security,
    AppErrors.deviceNotTrusted: ErrorStrategy.security,
  };

  // =================  决策方法 =================

  static ErrorStrategy getStrategy(int? code) {
    if (code == null) return ErrorStrategy.toast;

    if (_successCodes.contains(code)) return ErrorStrategy.success;
    if (_tokenErrorCodes.contains(code)) return ErrorStrategy.refresh;

    return _strategyMap[code] ?? ErrorStrategy.toast;
  }
}