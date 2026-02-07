import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';

// Provider 定义
final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository();
});

class MessageRepository {
  final LocalDatabaseService _db = LocalDatabaseService();

  Future<ChatUiModel?> get(String id) async {
    return await _db.getMessageById(id);
  }

  /// 🟢 [场景 1：初始发送]
  /// 仅用于消息刚创建时 (Sending 状态)，或者你确实想要全量覆盖时。
  Future<void> saveOrUpdate(ChatUiModel msg) async {
    // 简单粗暴，新消息直接存。
    // 如果你要保留之前的双轨合并逻辑作为兜底也可以，
    // 但有了 patchFields 后，这个方法主要只服务于 "第一步入库"。
    final old = await _db.getMessageById(msg.id);
    if (old == null) {
      await _db.saveMessage(msg);
    } else {
      // 兼容老逻辑：为了防止意外覆盖，这里依然用 saveMessage，
      // 但后续 Pipeline 步骤必须改用 patchFields！
      await _db.saveMessage(msg);
    }
  }

  /// 🔴 [场景 2：状态更新 / 上传完成 / 压缩完成]
  /// 🔥🔥🔥 核心：增量更新 (Patch) 🔥🔥🔥
  /// 只更新 map 里存在的字段，绝对不动其他字段 (如 previewBytes)
  Future<void> patchFields(String msgId, Map<String, dynamic> updates) async {
    if (updates.isEmpty) return;

    // 🛡️ 1. 铁壁防御：绝对禁止把 previewBytes 设为 null
    // 只要我不传 previewBytes，数据库里原来的封面图就永远在！
    if (updates.containsKey('previewBytes') && updates['previewBytes'] == null) {
      updates.remove('previewBytes');
    }

    // 🛡️ 2. 铁壁防御：绝对禁止把 localPath 设为 null
    // 防止网络层传回来的空路径覆盖掉本地路径
    if (updates.containsKey('localPath') && updates['localPath'] == null) {
      updates.remove('localPath');
    }

    // 🛡️ 3. 深度合并 Meta
    // 防止 {meta: {url: ...}} 覆盖掉了 {meta: {w: 100, h: 200}}
    if (updates.containsKey('meta')) {
      final oldMsg = await _db.getMessageById(msgId);
      if (oldMsg != null) {
        final oldMeta = oldMsg.meta ?? {};
        final newMeta = updates['meta'] as Map<String, dynamic>;

        // 合并策略：旧数据打底，新数据覆盖
        updates['meta'] = {...oldMeta, ...newMeta};
      }
    }

    // 调用数据库底层的 update (Merge 模式)
    await _db.updateMessage(msgId, updates);

    if (kDebugMode) {
      // print("🛡️ [Repo] Patched $msgId: keys=${updates.keys}");
    }
  }
}