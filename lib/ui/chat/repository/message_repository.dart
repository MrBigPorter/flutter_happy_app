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
  //  基础查询
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

  // ==========================================
  //  核心写入逻辑 (带防守)
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
    // 这里循环调用 saveOrUpdate 虽然慢一点点，但是为了安全（Merge逻辑），值得！
    // 如果性能有瓶颈，可以在 _db 里实现批量 merge，但目前几十条消息没问题。
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

  // ==========================================
  //  P0 核心业务：已读状态管理
  // ==========================================

  /// 静默标记已读 (只改本地库，不调 API)
  /// 用于：冷启动自愈、进入房间时消除红点
  Future<void> markAsReadLocally(String conversationId, int targetSeqId) async {
    await _db.markMessagesAsRead(conversationId, targetSeqId);
  }

  Future<void> forceClearUnread(String conversationId) async {
    await _db.clearUnreadCount(conversationId);
  }
}