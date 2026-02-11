import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/store/hydrated_state_notifier.dart';
import 'package:flutter_app/core/models/index.dart'; // 确保引入 UserInfo
import '../../ui/chat/services/database/local_database_service.dart';
import '../api/lucky_api.dart';

class UserNotifier extends HydratedStateNotifier<UserInfo?> {
  UserNotifier() : super(null);

  @override
  String get storageKey => 'user_info_storage';

  @override
  UserInfo? fromJson(Map<String, dynamic> json) {
    //  修复点 1: 如果本地存的是空 Map，说明是登出状态，返回 null
    if (json.isEmpty) {
      return null;
    }
    return UserInfo.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(UserInfo? state) {
    //  修复点 2: 必须返回非空 Map。如果 state 是 null，就存一个空 Map
    if (state == null) {
      return {};
    }
    return state.toJson();
  }

  /// 获取最新用户信息并初始化 DB
  Future<void> fetchProfile() async {
    try {
      final user = await Api.getUserInfo();
      // 核心业务：拿到用户ID后必须初始化本地数据库
      await LocalDatabaseService.init(user.id);
      state = user;
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    //  修复点 3: 只要置为 null，toJson 就会存入 {}，达到清空效果
    state = null;
    // clear(); //  删掉这行，因为基类里没这个方法，也不需要它
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserInfo?>((ref) {
  return UserNotifier();
});