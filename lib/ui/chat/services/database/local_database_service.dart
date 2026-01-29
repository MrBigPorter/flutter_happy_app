import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb, kDebugMode, kReleaseMode
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // 手机端
import 'package:sembast_web/sembast_web.dart';

import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../../../utils/image_url.dart'; // 必须引入，用于处理 uploads/

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();

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
  /// [limit]: 默认 50，核心性能优化点。
  /// UI 层通过 ChatViewModel 动态增加这个值来实现"无感加载更多"。
  Stream<List<ChatUiModel>> watchMessages(String conversationId, {int limit = 50}) async* {
    final db = await database;

    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)], // 倒序：最新的在前面
      limit: limit, //  关键：限制数量，防止大群卡死
    );

    // 使用 asyncMap 将预热逻辑注入到流中
    yield* _messageStore
        .query(finder: finder)
        .onSnapshots(db)
        .asyncMap((snapshots) async {
      // 1. 转为原始 Model
      final rawModels = snapshots
          .map((snapshot) => ChatUiModel.fromJson(snapshot.value))
          .toList();

      // 2. 并行预热 (路径计算、Gateway拼接、HTTPS升级)
      // 这一步完成后，UI 拿到的就是"热数据"，直接渲染即可
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
    final rawList = snapshots.map((e) => ChatUiModel.fromJson(e.value)).toList();

    // 同样需要预热
    return await _prewarmMessages(rawList);
  }

  // ========================================================================
  // 内部引擎：批量数据预热 (Pre-warming Service)
  // ========================================================================
  // 这一步彻底解放了 UI 线程。UI 组件不需要做任何 IO 或逻辑判断。
  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    // 1. 提前获取网关 (根据环境判断 dev/prod)
    final gw = ImageUrl.gateway(useProd: kReleaseMode);

    // 2. 并行处理所有消息
    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // --- A. 预处理主文件路径 ---
      if (msg.localPath != null && msg.localPath!.isNotEmpty) {
        // 如果已经是网络路径或Blob，只做 HTTPS 检查
        if (msg.localPath!.startsWith('http') || msg.localPath!.startsWith('blob:')) {
          absPath = _ensureHttps(msg.localPath!);
        } else {
          // 如果是 AssetID，进行 IO 解析 (最耗时的一步，在这里做完)
          absPath = await AssetManager.getFullPath(msg.localPath!, msg.type);
        }
      } else {
        // 没有本地路径，看 content
        if (msg.content.startsWith('http')) {
          absPath = _ensureHttps(msg.content);
        } else if (msg.content.startsWith('uploads/')) {
          // 自动补全 Gateway
          absPath = _ensureHttps('$gw/${msg.content}');
        }
      }

      if (absPath != null) needsUpdate = true;

      // --- B. 预处理封面路径 ---
      if (msg.meta != null) {
        String? t = msg.meta!['thumb'];
        if (t == null || t.isEmpty) {
          t = msg.meta!['remote_thumb'];
        }

        if (t != null && t.isNotEmpty) {
          if (t.startsWith('http')) {
            thumbPath = _ensureHttps(t);
          } else if (t.startsWith('uploads/')) {
            thumbPath = _ensureHttps('$gw/$t');
          } else {
            thumbPath = await AssetManager.getFullPath(t, MessageType.image);
          }
        }
        if (thumbPath != null) needsUpdate = true;
      }

      // --- C. 组装成品 ---
      if (needsUpdate) {
        // 注入到内存字段 resolvedPath/resolvedThumbPath 中
        return msg.copyWith(
          resolvedPath: absPath,
          resolvedThumbPath: thumbPath,
        );
      }
      return msg;
    });

    return await Future.wait(futures);
  }

  //  辅助：环境感知 HTTPS 转换 (解决 iOS 播放报错)
  String _ensureHttps(String url) {
    // 1. 本地开发模式 (Debug) -> 允许 HTTP，不做处理，方便调试
    if (kDebugMode) {
      return url;
    }

    // 2. 线上发布模式 (Release) -> 强制 HTTPS (满足 iOS ATS)
    // 如果是 http://dev.joyminis.com... 强制转 https://
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }

    return url;
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
    final finder = Finder(filter: Filter.equals('conversationId', conversationId));
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