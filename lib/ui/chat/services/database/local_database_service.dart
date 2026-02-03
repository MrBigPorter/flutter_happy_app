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
  /// 构造函数保持为空，允许 `LocalDatabaseService().method()` 的调用方式
  /// 但内部共享同一个 static _db 连接
  LocalDatabaseService();

  // ---------------------------------------------------------------------------
  // 核心：静态连接管理 (User Isolation)
  // ---------------------------------------------------------------------------

  static Database? _db;
  static String? _currentUserId;

  // 定义存储仓库 (改为 static final)
  static final _messageStore = stringMapStoreFactory.store('messages');
  static final _detailStore = stringMapStoreFactory.store('conversation_details');
  static final _conversationStore = stringMapStoreFactory.store('conversations');

  /// 获取当前活跃的数据库实例
  Future<Database> get database async {
    if (_db == null) {
      throw Exception(" [LocalDB] Database not initialized! You MUST call LocalDatabaseService.init(userId) after login.");
    }
    return _db!;
  }

  ///  初始化：传入 userId，打开专属数据库
  static Future<void> init(String userId) async {
    // 1. 如果已经是这个用户的库，直接复用
    if (_db != null && _currentUserId == userId) {
      debugPrint(" [LocalDB] Already initialized for user: $userId");
      return;
    }

    // 2. 如果之前有别的用户登录，先关掉旧的，防止串号
    if (_db != null) {
      debugPrint(" [LocalDB] Closing DB for previous user: $_currentUserId");
      await _db!.close();
      _db = null;
    }

    _currentUserId = userId;

    // 3. 关键点：文件名带上 userId，实现物理隔离
    final dbName = 'chat_app_v1_$userId.db';

    try {
      if (kIsWeb) {
        _db = await databaseFactoryWeb.openDatabase(dbName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        await appDir.create(recursive: true);
        final dbPath = join(appDir.path, dbName);
        _db = await databaseFactoryIo.openDatabase(dbPath);
      }
      debugPrint(" [LocalDB] Initialized successfully: $dbName");
    } catch (e) {
      debugPrint(" [LocalDB] Init failed: $e");
      rethrow;
    }
  }

  /// 关闭数据库 (用于退出登录)
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _currentUserId = null;
      debugPrint("🔒 [LocalDB] Database closed.");
    }
  }

  // ========================================================================
  //  Conversation List 缓存
  // ========================================================================

  /// 批量保存会话列表 (Sync: API -> Local DB)
  Future<void> saveConversations(List<Conversation> list) async {
    if (list.isEmpty) return;

    final db = await database; // 这里的 database 已经是隔离后的实例

    // 1. 提取所有 ID (Keys)
    final keys = list.map((c) => c.id).toList();

    // 2. 提取所有数据 (Values)
    final values = list.map((c) => c.toJson()).toList();

    // 3. 批量写入
    await db.transaction((txn) async {
      await _conversationStore.records(keys).put(txn, values);
    });
  }

  /// 获取本地会话列表 (Load: Local DB -> UI)
  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final finder = Finder(
      sortOrders: [SortOrder('lastMsgTime', false)], // 倒序
    );

    final snapshots = await _conversationStore.find(db, finder: finder);

    return snapshots.map((s) {
      try {
        return Conversation.fromJson(s.value);
      } catch (e) {
        debugPrint(" [DB] 会话解析失败 id=${s.key}: $e");
        return null;
      }
    }).whereType<Conversation>().toList();
  }

  /// 更新单个会话
  Future<void> updateConversation(Conversation item) async {
    final db = await database;
    await _conversationStore.record(item.id).put(db, item.toJson());
  }

  // ================= 业务方法 (CRUD - Message) =================

  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    final record = _messageStore.record(msg.id);
    Map<String, dynamic> dataToSave = msg.toJson();

    final oldSnapshot = await record.getSnapshot(db);
    if (oldSnapshot != null) {
      final oldData = oldSnapshot.value;
      // 防御性保留本地字段
      if (dataToSave['previewBytes'] == null && oldData['previewBytes'] != null) {
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
          debugPrint(" [存库炸了] id=${msg.id} err=$e");
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

  Future<void> updateMessageStatus(String msgId, MessageStatus newStatus) async {
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
      final raw = ChatUiModel.fromJson(recordSnapshot.value);
      final list = await _prewarmMessages([raw]);
      return list.first;
    }
    return null;
  }

  // ========================================================================
  //  监听消息流
  // ========================================================================
  Stream<List<ChatUiModel>> watchMessages(String conversationId, {int limit = 50}) async* {
    final db = await database;

    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)],
      limit: limit,
    );

    yield* _messageStore.query(finder: finder).onSnapshots(db).asyncMap((snapshots) async {
      final rawModels = snapshots
          .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
          .toList();

      return await _prewarmMessages(rawModels);
    });
  }

  // ========================================================================
  //  分页历史
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
  // 内部引擎：数据预热
  // ========================================================================
  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // A. 主文件路径
      if (msg.localPath != null && msg.localPath!.isNotEmpty) {
        bool isDeadBlob = kIsWeb &&
            msg.localPath!.startsWith('blob:') &&
            msg.status == MessageStatus.success;

        if (!isDeadBlob) {
          if (msg.localPath!.startsWith('http') || msg.localPath!.startsWith('blob:')) {
            absPath = _resolveByMsgType(msg.type, msg.localPath);
          } else {
            absPath = await AssetManager.getFullPath(msg.localPath!, msg.type);
          }
        }
      }

      if (absPath == null) {
        absPath = _resolveByMsgType(msg.type, msg.content);
      }

      if (absPath != null && absPath != msg.resolvedPath) {
        needsUpdate = true;
      }

      // B. 封面路径
      if (msg.meta != null) {
        String? t = msg.meta!['thumb'] ?? msg.meta!['remote_thumb'];
        if (t != null && t.isNotEmpty) {
          if (t.startsWith('http') || t.startsWith('blob:') || t.contains('/')) {
            thumbPath = UrlResolver.resolveImage(null, t);
          } else {
            thumbPath = await AssetManager.getFullPath(t, MessageType.image);
          }
        }
        if (thumbPath != null && thumbPath != msg.resolvedThumbPath) {
          needsUpdate = true;
        }
      }

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

  String? _resolveByMsgType(MessageType type, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (type) {
      case MessageType.video:
        return UrlResolver.resolveVideo(raw);
      case MessageType.image:
        return UrlResolver.resolveImage(null, raw);
      default:
        return UrlResolver.resolveFile(raw);
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