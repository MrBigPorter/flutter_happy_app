import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/store/hydrated_state_notifier.dart';
import 'package:flutter_app/core/models/index.dart'; // 确保引入 SysConfig
import '../api/lucky_api.dart';

class SysConfigNotifier extends HydratedStateNotifier<SysConfig> {
  // 设置默认值
  SysConfigNotifier() : super(SysConfig(
    kycAndPhoneVerification: '1',
    webBaseUrl: '',
    exChangeRate: 1.0,
  ));

  @override
  String get storageKey => 'sys_config_storage';

  @override
  SysConfig fromJson(Map<String, dynamic> json) => SysConfig.fromJson(json);

  @override
  Map<String, dynamic> toJson(SysConfig state) => state.toJson();

  /// 获取最新配置
  Future<void> fetchLatest() async {
    final config = await Api.getSysConfig();
    state = config;
  }
}

final configProvider = StateNotifierProvider<SysConfigNotifier, SysConfig>((ref) {
  return SysConfigNotifier();
});