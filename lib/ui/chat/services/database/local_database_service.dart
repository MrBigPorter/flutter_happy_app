import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // Mobile
import 'package:sembast_web/sembast_web.dart'; // Web
import 'package:lpinyin/lpinyin.dart';

import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';
import '../../../../utils/asset/asset_manager.dart';

class LocalDatabaseService {
  /// 构造函数保持为空
  LocalDatabaseService();

  // ---------------------------------------------------------------------------
  //  核心：静态连接管理 & 挂起等待机制 (Completer)
  // ---------------------------------------------------------------------------

  static Database? _db;
  static String? _currentUserId;

  // 这是一个“红绿灯”。如果数据库还没好，所有请求都会在这里排队等待。
  static Completer<Database> _dbCompleter = Completer<Database>();

  //  基础业务 Store
  static final _messageStore = stringMapStoreFactory.store('messages');
  static final _detailStore = stringMapStoreFactory.store('conversation_details');
  static final _conversationStore = stringMapStoreFactory.store('conversations');

  //  通讯录 & 搜索 Store
  static final _contactStore = stringMapStoreFactory.store('contacts');

  //  倒排索引 Store (Value 必须是 List<Object?> 以兼容数组)
  static final _indexStore = StoreRef<String, List<Object?>>('search_index');

  /// [核心修改] 获取数据库实例
  /// 如果数据库未初始化，它不会报错，而是会【卡住等待】，直到 init() 完成。
  Future<Database> get database async {
    // 1. 如果已经好了，直接返回 (最快路径)
    if (_db != null) {
      return _db!;
    }

    // 2. 如果还没好，返回 Future 让调用者等待 (解决 OfflineQueue 报错的关键)
    debugPrint(" [LocalDB] Database not ready yet. Waiting...");
    return _dbCompleter.future;
  }

  /// 初始化：传入 userId，打开专属数据库
  static Future<void> init(String userId) async {
    // 1. 如果已经是这个用户的库，且已就绪
    if (_db != null && _currentUserId == userId) {
      if (!_dbCompleter.isCompleted) _dbCompleter.complete(_db);
      return;
    }

    // 2. 如果之前有别的用户登录，先关掉旧的，并重置等待器
    if (_db != null) {
      debugPrint(" [LocalDB] Closing DB for previous user: $_currentUserId");
      await _db!.close();
      _db = null;
      _dbCompleter = Completer<Database>(); // 重置红绿灯
    }

    _currentUserId = userId;
    final dbName = 'chat_app_v1_$userId.db';

    try {
      debugPrint(" [LocalDB] Opening database: $dbName...");

      Database dbInstance;
      if (kIsWeb) {
        dbInstance = await databaseFactoryWeb.openDatabase(dbName);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        await appDir.create(recursive: true);
        final dbPath = join(appDir.path, dbName);
        dbInstance = await databaseFactoryIo.openDatabase(dbPath);
      }

      _db = dbInstance;

      //  [关键] 通知所有正在等待的组件 (如 OfflineQueue) 继续执行
      if (!_dbCompleter.isCompleted) {
        _dbCompleter.complete(_db);
      }

      debugPrint(" [LocalDB] Initialized successfully: $dbName");
    } catch (e) {
      debugPrint(" [LocalDB] Init failed: $e");
      // 如果失败，告诉等待者出错了，防止永久卡死
      if (!_dbCompleter.isCompleted) _dbCompleter.completeError(e);
      rethrow;
    }
  }

  /// 关闭数据库
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _currentUserId = null;
      // 重置等待器，确保后续调用会再次等待 init
      _dbCompleter = Completer<Database>();
      debugPrint("🔒 [LocalDB] Database closed.");
    }
  }

  // ========================================================================
  //   搜索引擎内核 (Search Kernel - Sembast Implementation)
  // ========================================================================

  /// 内部方法：更新倒排索引
  Future<void> _updateSearchIndex(DatabaseClient txn, String id, String text, String type) async {
    if (text.isEmpty) return;

    // 1. 分词 (Tokenize)
    final Set<String> tokens = {};
    final cleanText = text.toLowerCase();

    // A. 单字切分
    for (int i = 0; i < cleanText.length; i++) {
      tokens.add(cleanText[i]);
    }

    // B. 拼音处理
    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(text)) {
      try {
        String pinyinShort = PinyinHelper.getShortPinyin(text).toLowerCase();
        String pinyinFull = PinyinHelper.getPinyinE(text, separator: "").toLowerCase();
        tokens.add(pinyinShort);
        if (pinyinFull != pinyinShort) tokens.add(pinyinFull);
      } catch (e) {
        // ignore
      }
    }

    // 2. 写入倒排索引表
    for (final token in tokens) {
      final key = '$type:$token';
      final record = _indexStore.record(key);
      final snapshot = await record.getSnapshot(txn);

      Set<String> idSet = {};
      if (snapshot != null) {
        // 这里的 value 是 List<Object?>，需要强转
        idSet = Set<String>.from(snapshot.value as List);
      }

      if (!idSet.contains(id)) {
        idSet.add(id);
        await record.put(txn, idSet.toList());
      }
    }
  }

  // ========================================================================
  //  联系人 (整合了搜索能力)
  // ========================================================================

  /// 批量保存联系人 -> 自动触发建索引
  Future<void> saveContacts(List<ChatUser> users) async {
    final db = await database; // 这里会等待 init 完成
    await db.transaction((txn) async {
      for (var user in users) {
        // 1. 存原始数据
        await _contactStore.record(user.id).put(txn, user.toJson());
        // 2. 建索引
        await _updateSearchIndex(txn, user.id, user.nickname, 'user');
      }
    });
  }

  /// 获取所有联系人
  Future<List<ChatUser>> getAllContacts() async {
    final db = await database;
    final snapshots = await _contactStore.find(db);
    return snapshots.map((s) => ChatUser.fromJson(s.value)).toList();
  }

  ///  全文检索 (对外暴露接口)
  Future<List<ChatUser>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    final db = await database;
    final cleanQuery = query.toLowerCase();

    // 1. 优先查倒排索引
    final indexKey = 'user:$cleanQuery';
    final indexSnapshot = await _indexStore.record(indexKey).getSnapshot(db);

    Set<String> candidateIds = {};
    if (indexSnapshot != null) {
      candidateIds.addAll(List<String>.from(indexSnapshot.value as List));
    }

    List<ChatUser> results = [];

    if (candidateIds.isNotEmpty) {
      // 命中索引
      final snapshots = await _contactStore.records(candidateIds.toList()).getSnapshots(db);
      results = snapshots
          .where((s) => s != null)
          .map((s) => ChatUser.fromJson(s!.value))
          .toList();
    } else {
      // 未命中索引，走正则兜底
      final finder = Finder(
        filter: Filter.custom((record) {
          final user = ChatUser.fromJson(record.value as Map<String, dynamic>);
          final name = user.nickname.toLowerCase();
          return name.contains(cleanQuery);
        }),
      );
      final snapshots = await _contactStore.find(db, finder: finder);
      results = snapshots.map((s) => ChatUser.fromJson(s.value)).toList();
    }

    return results;
  }

  // ========================================================================
  //  消息相关业务 (CRUD)
  // ========================================================================

  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    await _messageStore.record(msg.id).put(db, msg.toJson());
  }

  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final msg in msgs) {
        if (msg.id.trim().isEmpty) continue;
        await _messageStore.record(msg.id).put(txn, msg.toJson());
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

  Future<void> deleteMessage(String msgId) async {
    final db = await database;
    await _messageStore.record(msgId).delete(db);
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
    final snapshot = await _messageStore.record(msgId).getSnapshot(db);
    if (snapshot != null) {
      final raw = ChatUiModel.fromJson(snapshot.value);
      final list = await _prewarmMessages([raw]);
      return list.first;
    }
    return null;
  }

  Future<List<ChatUiModel>> getPendingMessages() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('status', MessageStatus.pending.name),
      sortOrders: [SortOrder('createdAt', true)],
    );
    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots.map((s) => ChatUiModel.fromJson(s.value)).toList();
  }

  // ========================================================================
  //  会话列表相关
  // ========================================================================

  Future<void> saveConversations(List<Conversation> list) async {
    if (list.isEmpty) return;
    final db = await database;
    final keys = list.map((c) => c.id).toList();
    final values = list.map((c) => c.toJson()).toList();
    await db.transaction((txn) async {
      await _conversationStore.records(keys).put(txn, values);
    });
  }

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final finder = Finder(sortOrders: [SortOrder('lastMsgTime', false)]);
    final snapshots = await _conversationStore.find(db, finder: finder);
    return snapshots.map((s) {
      try {
        return Conversation.fromJson(s.value);
      } catch (e) {
        return null;
      }
    }).whereType<Conversation>().toList();
  }

  Future<void> updateConversation(Conversation item) async {
    final db = await database;
    await _conversationStore.record(item.id).put(db, item.toJson());
  }

  Future<void> saveConversationDetail(ConversationDetail detail) async {
    final db = await database;
    await _detailStore.record(detail.id).put(db, detail.toJson());
  }

  Future<ConversationDetail?> getConversationDetail(String id) async {
    final db = await database;
    final json = await _detailStore.record(id).get(db);
    return json != null ? ConversationDetail.fromJson(json) : null;
  }

  // ========================================================================
  //  流监听
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
    return await _prewarmMessages(rawList);
  }

  Future<void> clearAll() async {
    final db = await database;
    await _messageStore.delete(db);
  }

  // ========================================================================
  //  数据预热 (路径处理)
  // ========================================================================

  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // 处理主文件路径
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

      // 处理缩略图路径
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
}