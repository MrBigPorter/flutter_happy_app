import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/lucky_api.dart';
import '../../models/conversation.dart'; // 确保这里包含 ChatUser 定义
import '../../services/database/local_database_service.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(LocalDatabaseService());
});

class ContactRepository {
  final LocalDatabaseService _localDb;

  ContactRepository(this._localDb);

  ///  核心同步逻辑 (Sync)
  /// 流程：API -> DB -> Sembast Index
  Future<void> syncContacts() async {
    try {
      // 1. 调用真实 API 获取好友列表
      // 注意：请确保 Api.getContacts() 返回的是 List<ChatUser>
      // 如果你的 API 方法名不同 (例如 getFriendList)，请自行修改此处
      final List<ChatUser> remoteUsers = await Api.getContactsApi();

      if (remoteUsers.isNotEmpty) {
        // 2. 存入本地数据库
        // 这一步非常关键：它会自动触发 LocalDatabaseService 里的 _updateSearchIndex
        // 从而将中文名拆解为拼音索引，供搜索使用
        await _localDb.saveContacts(remoteUsers);

        debugPrint("[ContactRepo] Synced ${remoteUsers.length} contacts & built index.");
      }
    } catch (e) {
      debugPrint(" [ContactRepo] Sync failed: $e");
      // 这里的错误可以选择抛出给 UI 处理，或者静默失败
      rethrow;
    }
  }

  /// 搜索 (Search)
  Future<List<ChatUser>> search(String query) {
    return _localDb.searchContacts(query);
  }

  /// 获取列表 (List)
  Future<List<ChatUser>> getAllContacts() {
    return _localDb.getAllContacts();
  }
}