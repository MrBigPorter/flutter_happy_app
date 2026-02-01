import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb, kDebugMode, kReleaseMode
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // 手机端
import 'package:sembast_web/sembast_web.dart';

import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';
import '../../../../utils/asset/asset_manager.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  Database? _db;
  final _messageStore = stringMapStoreFactory.store('messages');
  final _detailStore = stringMapStoreFactory.store('conversation_details');

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;
    if (kIsWeb) {
      _db = await databaseFactoryWeb.openDatabase('chat_app_v1.db');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      await appDir.create(recursive: true);
      final dbPath = join(appDir.path, 'chat_app_v1.db');
      _db = await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  // ================= 业务方法 (CRUD) =================

  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    final record = _messageStore.record(msg.id);
    Map<String, dynamic> dataToSave = msg.toJson();

    // 防御性合并：防止覆盖关键字段 (如本地预览图、时长)
    final oldSnapshot = await record.getSnapshot(db);
    if (oldSnapshot != null) {
      final oldData = oldSnapshot.value;
      if (dataToSave['previewBytes'] == null &&
          oldData['previewBytes'] != null) {
        dataToSave['previewBytes'] = oldData['previewBytes'];
      }
      if (dataToSave['localPath'] == null && oldData['localPath'] != null) {
        dataToSave['localPath'] = oldData['localPath'];
      }
      if (dataToSave['duration'] == null && oldData['duration'] != null) {
        dataToSave['duration'] = oldData['duration'];
      }
    }
    await record.put(db, dataToSave);
  }

  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final msg in msgs) {
        try {
          if (msg.id.trim().isEmpty) continue;
          await _messageStore.record(msg.id).put(txn, msg.toJson());
        } catch (e) {
          debugPrint("❌ [存库炸了] id=${msg.id} err=$e");
        }
      }
    });
  }

  Future<void> replaceMessage(String oldId, ChatUiModel newMsg) async {
    final db = await database;
    await db.transaction((txn) async {
      await _messageStore.record(oldId).delete(txn);
      await _messageStore.record(newMsg.id).put(txn, newMsg.toJson());
    });
  }

  Future<void> updateMessageStatus(
    String msgId,
    MessageStatus newStatus,
  ) async {
    final db = await database;
    await _messageStore.record(msgId).update(db, {'status': newStatus.name});
  }

  Future<void> updateMessage(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await _messageStore.record(id).update(db, updates);
  }

  Future<void> markMessagesAsRead(String conversationId, int maxSeqId) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.equals('isMe', true),
        Filter.lessThanOrEquals('seqId', maxSeqId),
        Filter.notEquals('status', 'read'),
      ]),
    );
    final records = await _messageStore.find(db, finder: finder);
    for (var record in records) {
      var map = Map<String, dynamic>.from(record.value);
      map['status'] = 'read';
      await _messageStore.record(record.key).put(db, map);
    }
  }

  Future<void> doLocalRecall(String messageId, String tip) async {
    final existingMsg = await getMessageById(messageId);
    if (existingMsg == null) return;
    final recalledMsg = existingMsg.copyWith(
      content: tip,
      type: MessageType.system,
      isRecalled: true,
      status: MessageStatus.success,
    );
    await saveMessage(recalledMsg);
  }

  Future<ChatUiModel?> getMessageById(String msgId) async {
    final db = await database;
    final recordSnapshot = await _messageStore.record(msgId).getSnapshot(db);
    if (recordSnapshot != null) {
      // 单条查询也要过一遍预热，保证数据结构一致
      final raw = ChatUiModel.fromJson(recordSnapshot.value);
      final list = await _prewarmMessages([raw]);
      return list.first;
    }
    return null;
  }

  // ========================================================================
  //  核心重构 A：监听消息流 (带 Limit 分页 + 自动预热)
  // ========================================================================
  Stream<List<ChatUiModel>> watchMessages(
    String conversationId, {
    int limit = 50,
  }) async* {
    final db = await database;

    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)], // 倒序：最新的在前面
      limit: limit, //  关键：限制数量，防止大群卡死
    );

    yield* _messageStore.query(finder: finder).onSnapshots(db).asyncMap((
      snapshots,
    ) async {
      final rawModels = snapshots
          .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
          .toList();

      return await _prewarmMessages(rawModels);
    });
  }

  // ========================================================================
  //  核心重构 B：分页拉取旧消息 (供上拉加载使用)
  // ========================================================================
  Future<List<ChatUiModel>> getHistoryMessages({
    required String conversationId,
    int offset = 0,
    int limit = 50,
  }) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)],
      limit: limit,
      offset: offset,
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    final rawList = snapshots
        .map((e) => ChatUiModel.fromJson(e.value))
        .toList();

    return await _prewarmMessages(rawList);
  }

  // ========================================================================
  // 内部引擎：批量数据预热 (Pre-warming Service)
  //  修复点：删除了手动 gw 拼接，全部委托给 UrlResolver
  // ========================================================================
  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // --- A. 预处理主文件路径 ---
      if (msg.localPath != null && msg.localPath!.isNotEmpty) {
        // ️ Blob 保护策略：
        // 如果是 Web 端，且消息已发送成功，则认为本地存的 blob 链接已过期（刷新会导致失效）
        // 此时强制 absPath = null，迫使下方逻辑使用 msg.content (远程链接)
        bool isDeadBlob = kIsWeb &&
            msg.localPath!.startsWith('blob:') &&
            msg.status == MessageStatus.success;

        if (!isDeadBlob) {
          if (msg.localPath!.startsWith('http') || msg.localPath!.startsWith('blob:')) {
            // 网络路径 -> UrlResolver
            absPath = _resolveByMsgType(msg.type, msg.localPath);
          } else {
            // 本地路径 -> AssetManager
            absPath = await AssetManager.getFullPath(msg.localPath!, msg.type);
          }
        }
      }

      // 3. 如果本地解析失败，兜底使用 content (远程路径)
      //    UrlResolver 会自动识别 content 是绝对路径还是相对 uploads 路径，并补全正确域名
      if (absPath == null) {
        absPath = _resolveByMsgType(msg.type, msg.content);
      }

      if (absPath != null && absPath != msg.resolvedPath) {
        needsUpdate = true;
      }

      // --- B. 预处理封面路径 ---
      if (msg.meta != null) {
        String? t = msg.meta!['thumb'] ?? msg.meta!['remote_thumb'];
        if (t != null && t.isNotEmpty) {
          // 封面全部按图片处理
          // 如果 t 是相对路径 (uploads/xxx) 或网络路径，走 UrlResolver
          // 如果 t 是本地资源 ID (没有斜杠)，走 AssetManager
          if (t.startsWith('http') ||
              t.startsWith('blob:') ||
              t.contains('/')) {
            //  修复：第一个参数传 null (因为 Service 层没有 context)
            thumbPath = UrlResolver.resolveImage(null, t);
          } else {
            thumbPath = await AssetManager.getFullPath(t, MessageType.image);
          }
        }
        if (thumbPath != null && thumbPath != msg.resolvedThumbPath) {
          needsUpdate = true;
        }
      }

      // --- C. 返回新模型 ---
      if (needsUpdate) {
        return msg.copyWith(
          resolvedPath: absPath,
          resolvedThumbPath: thumbPath,
        );
      }
      return msg;
    });

    return await Future.wait(futures);
  }

  //  辅助分发器：根据消息类型选择正确的解析策略
  // 取代了旧的 _ensureHttps
  String? _resolveByMsgType(MessageType type, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (type) {
      case MessageType.video:
        return UrlResolver.resolveVideo(raw); // 走视频专用通道 (Web/Native 分流)
      case MessageType.image:
        return UrlResolver.resolveImage(null, raw); // 走图片专用通道 (CDN)
      default:
        return UrlResolver.resolveFile(raw); // 走文件专用通道 (纯 API 域名)
    }
  }

  // ========================================================================
  // 其他基础方法
  // ========================================================================

  Future<List<ChatUiModel>> getPendingMessages() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('status', MessageStatus.pending.name),
      sortOrders: [SortOrder('createdAt', true)],
    );
    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots.map((s) => ChatUiModel.fromJson(s.value)).toList();
  }

  Future<void> markMessageAsPending(String msgId) async {
    await updateMessageStatus(msgId, MessageStatus.pending);
  }

  Future<void> deleteMessage(String msgId) async {
    final db = await database;
    await _messageStore.record(msgId).delete(db);
  }

  Future<void> clearConversation(String conversationId) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
    );
    await _messageStore.delete(db, finder: finder);
  }

  Future<void> saveConversationDetail(ConversationDetail detail) async {
    final db = await database;
    await _detailStore.record(detail.id).put(db, detail.toJson());
  }

  Future<ConversationDetail?> getConversationDetail(String id) async {
    final db = await database;
    final json = await _detailStore.record(id).get(db);
    if (json == null) return null;
    return ConversationDetail.fromJson(json);
  }

  Future<void> clearAll() async {
    final db = await database;
    await _messageStore.delete(db);
  }
}
