import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';

// Provider 定义
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

class MessageRepository {
  final LocalDatabaseService _db = LocalDatabaseService();

  // ==========================================
  //  基础查询 (Existing + Enhanced)
  // ==========================================

  Future<ChatUiModel?> get(String id) async {
    return await _db.getMessageById(id);
  }

  /// 获取会话的最大 seqId (用于增量同步断点)
  Future<int> getMaxSeqId(String conversationId) async {
    return (await _db.getMaxSeqId(conversationId)) ?? 0;
  }

  /// 获取会话详情 (用于 P0 自愈判断 unreadCount)
  Future<Conversation?> getConversation(String id) async {
    return await _db.getConversation(id);
  }

  // [新增] 获取群详情缓存
  Future<ConversationDetail?> getGroupDetail(String id) async {
    return await _db.getConversationDetail(id);
  }

  // [新增] 保存群详情缓存
  Future<void> saveGroupDetail(ConversationDetail detail) async {
    await _db.saveConversationDetail(detail);
  }

  /// [删除会话] 用于解散群、被踢、退群
  Future<void> deleteConversation(String conversationId) async {
    await _db.deleteConversation(conversationId);
  }

  /// [更新会话信息] 用于 Socket 推送群名/头像变更
  Future<void> updateConversationInfo(
      String conversationId, {
        String? name,
        String? avatar,
        String? announcement, // 新增公告参数
      }) async {
    // 1. 更新会话列表 (Conversation Table)
    // 列表通常只展示名字和头像，不展示公告
    final Map<String, dynamic> listUpdates = {};
    if (name != null) listUpdates['name'] = name;
    if (avatar != null) listUpdates['avatar'] = avatar;

    if (listUpdates.isNotEmpty) {
      await _db.updateConversation(conversationId, listUpdates);
    }

    // 2. 更新详情缓存 (ConversationDetail Table)
    // 如果本地有缓存详情，也要同步更新，否则点进群设置会看到旧数据
    final detail = await _db.getConversationDetail(conversationId);
    if (detail != null) {
      final newDetail = detail.copyWith(
        name: name,
        avatar: avatar,
        announcement: announcement, // 同步更新公告
      );
      await _db.saveConversationDetail(newDetail);
    }
  }

  /// [新增] 从群组移除成员 (踢人/退群)
  Future<void> removeMemberFromGroup(String groupId, String targetUserId) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    // 过滤掉目标用户
    final updatedMembers = detail.members.where((m) => m.userId != targetUserId).toList();

    // 如果人数变了，保存回去
    if (updatedMembers.length != detail.members.length) {
      final newDetail = detail.copyWith(members: updatedMembers);
      await _db.saveConversationDetail(newDetail);
    }
  }

  /// [新增] 向群组添加成员 (进群)
  Future<void> addMemberToGroup(String groupId, ChatMember member) async {
    final detail = await _db.getConversationDetail(groupId);
    if (detail == null) return;

    // 防止重复添加
    final exists = detail.members.any((m) => m.userId == member.userId);
    if (exists) return;

    // 添加新成员
    final updatedMembers = [...detail.members, member];

    // 保存
    final newDetail = detail.copyWith(members: updatedMembers);
    await _db.saveConversationDetail(newDetail);
  }

  //  [新增] 分页拉取历史消息 (UI下拉刷新专用)
  Future<List<ChatUiModel>> getHistory({
    required String conversationId,
    int offset = 0,
    int limit = 50,
  }) async {
    return await _db.getHistoryMessages(
      conversationId: conversationId,
      offset: offset,
      limit: limit,
    );
  }

  //  [新增] 实时监听消息列表 (UI 聊天气泡自动上屏专用)
  Stream<List<ChatUiModel>> watchMessages(String conversationId) {
    return _db.watchMessages(conversationId);
  }

  //  [新增] 获取发送失败/发送中的消息 (App启动重发专用)
  Future<List<ChatUiModel>> getPendingMessages() async {
    return await _db.getPendingMessages();
  }

  // ==========================================
  //  核心写入逻辑 (Existing - 保持原样)
  // ==========================================

  /// [场景 1：初始发送 / 同步入库]
  Future<void> saveOrUpdate(ChatUiModel msg) async {
    final old = await _db.getMessageById(msg.id);

    if (old == null) {
      // 1. 如果是全新的消息，直接存
      await _db.saveMessage(msg);
    } else {
      // 2. 核心防御：合并旧数据
      // 保留旧数据里的 localPath 和 previewBytes
      final merged = old.merge(msg);
      await _db.saveMessage(merged);
    }
  }

  /// [批量入库] (用于同步下来的列表)
  Future<void> saveBatch(List<ChatUiModel> msgs) async {
    // 保持你原有的安全循环逻辑
    for (var msg in msgs) {
      await saveOrUpdate(msg);
    }
  }

  /// [场景 2：状态更新 / 上传完成 / 压缩完成]
  /// 核心：增量更新 (Patch)
  Future<void> patchFields(String msgId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;

    //  1. 铁壁防御：绝对禁止把 previewBytes 设为 null
    if (updates.containsKey('previewBytes') && updates['previewBytes'] == null) {
      updates.remove('previewBytes');
    }

    //  2. 铁壁防御：绝对禁止把 localPath 设为 null
    if (updates.containsKey('localPath') && updates['localPath'] == null) {
      updates.remove('localPath');
    }

    //  3. 深度合并 Meta
    if (updates.containsKey('meta')) {
      final oldMsg = await _db.getMessageById(msgId);
      if (oldMsg != null) {
        final oldMeta = oldMsg.meta ?? {};
        final newMeta = updates['meta'] as Map<String, dynamic>;
        updates['meta'] = {...oldMeta, ...newMeta};
      }
    }

    // 调用数据库底层的 update
    await _db.updateMessage(msgId, updates);
  }

  //  [新增] 快捷更新状态 (发送中 -> 成功/失败)
  Future<void> updateStatus(String msgId, MessageStatus status) async {
    await _db.updateMessageStatus(msgId, status);
  }

  // ==========================================
  //  P0 核心业务：已读状态管理 (Existing)
  // ==========================================

  /// 静默标记已读 (只改本地库，不调 API)
  /// 用于：冷启动自愈、进入房间时消除红点
  Future<void> markAsReadLocally(String conversationId, int targetSeqId) async {
    await _db.markMessagesAsRead(conversationId, targetSeqId);
  }

  Future<void> forceClearUnread(String conversationId) async {
    await _db.clearUnreadCount(conversationId);
  }

  // ==========================================
  //  用户操作 (新增 - New Features)
  // ==========================================

  //  [新增] 删除消息
  Future<void> delete(String msgId) async {
    await _db.deleteMessage(msgId);
  }

  //  [新增] 撤回消息
  Future<void> recallMessage(String msgId, String tipText) async {
    await _db.doLocalRecall(msgId, tipText);
  }
}