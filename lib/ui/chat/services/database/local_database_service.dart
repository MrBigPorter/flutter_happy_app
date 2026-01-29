import 'dart:async';
import 'package:flutter/foundation.dart'; // 用于 kIsWeb
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // 手机端
import 'package:sembast_web/sembast_web.dart';

import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';
import '../../../../utils/asset/asset_manager.dart'; // 引入 AssetManager

class LocalDatabaseService {
  // 单例模式
  static final LocalDatabaseService _instance =
  LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  Database? _db;

  // 定义 Store (相当于 SQL 里的表)
  // key 是 String (用 msgId), value 是 Map
  final _messageStore = stringMapStoreFactory.store('messages');

  // 1. Define the new Store for Conversation Details
  final _detailStore = stringMapStoreFactory.store('conversation_details');

  // 获取数据库实例
  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  // 初始化
  Future<void> init() async {
    if (_db != null) return; // 防止重复初始化

    if (kIsWeb) {
      // Web 端：直接打开，无路径困扰
      _db = await databaseFactoryWeb.openDatabase('chat_app_v1.db');
    } else {
      //  手机端
      final appDir = await getApplicationDocumentsDirectory();
      await appDir.create(recursive: true);
      final dbPath = join(appDir.path, 'chat_app_v1.db');
      _db = await databaseFactoryIo.openDatabase(dbPath);
    }
  }

  // ================= 业务方法 =================

  //  保存或更新消息
  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    final record = _messageStore.record(msg.id);

    // 1. 先把新数据转成 Map
    Map<String, dynamic> dataToSave = msg.toJson();

    // 2. 查一下旧数据，做防御性合并
    final oldSnapshot = await record.getSnapshot(db);

    if (oldSnapshot != null) {
      final oldData = oldSnapshot.value;

      // 防御 1：如果新数据 previewBytes 没了，把旧的拿回来
      if (dataToSave['previewBytes'] == null &&
          oldData['previewBytes'] != null) {
        dataToSave['previewBytes'] = oldData['previewBytes'];
      }

      // 防御 2：localPath
      if (dataToSave['localPath'] == null && oldData['localPath'] != null) {
        dataToSave['localPath'] = oldData['localPath'];
      }

      // 防御 3：duration
      if (dataToSave['duration'] == null && oldData['duration'] != null) {
        dataToSave['duration'] = oldData['duration'];
      }
    }

    // 3. 保存
    await record.put(db, dataToSave);
  }

  //  批量保存 (性能优化版)
  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;

    debugPrint(
      "📦 [存库检查] 正在存入 ${msgs.length} 条。conv=${msgs.first.conversationId}",
    );

    final db = await database;
    await db.transaction((txn) async {
      for (final msg in msgs) {
        try {
          if (msg.id.trim().isEmpty) continue;

          final json = msg.toJson();
          await _messageStore.record(msg.id).put(txn, json);
        } catch (e) {
          debugPrint("❌ [存库炸了] id=${msg.id} err=$e");
        }
      }
    });
  }

  //  原子替换
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

  // 只更新特定字段
  Future<void> updateMessage(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await _messageStore.record(id).update(db, updates);
  }

  /// 批量将消息标记为已读
  Future<void> markMessagesAsRead(String conversationId, int maxSeqId) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.equals('isMe', true), // 只更新我自己发的
        Filter.lessThanOrEquals('seqId', maxSeqId), // 小于等于对方读到的位置
        Filter.notEquals('status', 'read'), // 还没变成已读的
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
      return ChatUiModel.fromJson(recordSnapshot.value);
    }
    return null;
  }

  //  获取特定会话的所有消息 (一次性拉取，不支持流监听)
  //  注：如果你需要这里也预热，可以手动调用 _prewarmMessages
  Future<List<ChatUiModel>> getMessagesByConversation(
      String conversationId,
      ) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)],
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    final rawList = snapshots
        .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
        .toList();

    //  如果列表页也需要缩略图，建议这里也加上 await _prewarmMessages(rawList);
    // 但通常列表只显示文本，这里为了性能暂且保留原样
    return rawList;
  }

  // ========================================================================
  // 核心重构：监听消息流 (带自动预热)
  // ========================================================================
  Stream<List<ChatUiModel>> watchMessages(String conversationId) async* {
    // 这里需要先获取 database，因为 onSnapshots 需要 database 实例
    // 但 stream 不能 await，所以需要一种技巧，通常 database 会在 init 阶段保证有了
    // 更好的做法是让 database 属性同步化，或者用 await for

    final db = await database;

    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)], // 倒序
      // limit: 50, //  P0-2.4 阶段建议开启分页
    );

    // 将 stream 转换为 BroadcastStream 可能会更安全，取决于 UI 怎么用
    yield* _messageStore
        .query(finder: finder)
        .onSnapshots(db)
        .asyncMap((snapshots) async {
      // 1. Raw Data -> Model List
      final rawModels = snapshots
          .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
          .toList();

      // 2. 并行预热：计算绝对路径
      // 此时是在 IO 线程池里跑，不阻塞 UI
      return await _prewarmMessages(rawModels);
    });
  }

  // ========================================================================
  // ⚙️ 内部引擎：批量路径解析器 (Batch Resolver)
  // ========================================================================
  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    // 使用 Future.wait 实现并行处理 (Parallel Processing)
    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // --- A. 解析主文件路径 ---
      if (msg.localPath != null && msg.localPath!.isNotEmpty) {
        if (msg.localPath!.startsWith('http') || msg.localPath!.startsWith('blob:')) {
          absPath = msg.localPath;
        } else {
          // 耗时 IO：查 AssetID
          absPath = await AssetManager.getFullPath(msg.localPath!, msg.type);
        }
        if (absPath != null) needsUpdate = true;
      }

      // --- B. 解析封面路径 ---
      if (msg.meta != null) {
        final dynamic t = msg.meta!['thumb'];
        if (t != null && t is String && t.isNotEmpty) {
          if (t.startsWith('http')) {
            thumbPath = t;
          } else {
            thumbPath = await AssetManager.getFullPath(t, MessageType.image);
          }
        }

        // 兜底：如果本地 thumb 解析失败，尝试 remote_thumb
        if (thumbPath == null && msg.meta!['remote_thumb'] != null) {
          final String rt = msg.meta!['remote_thumb'];
          if (rt.isNotEmpty) thumbPath = rt;
        }

        if (thumbPath != null) needsUpdate = true;
      }

      // --- C. 组装成品 ---
      if (needsUpdate) {
        // 使用刚刚在 Model 里修复的 copyWith 注入内存字段
        return msg.copyWith(
          resolvedPath: absPath,
          resolvedThumbPath: thumbPath,
        );
      }
      return msg;
    });

    return await Future.wait(futures);
  }

  // ========================================================================

  Future<List<ChatUiModel>> getPendingMessages() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('status', MessageStatus.pending.name),
      sortOrders: [SortOrder('createdAt', true)],
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots
        .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
        .toList();
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