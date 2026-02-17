import 'dart:async';
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:lpinyin/lpinyin.dart';

import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();

  factory LocalDatabaseService() => _instance;

  LocalDatabaseService._internal();

  static Database? _db;
  static String? _currentUserId;
  static Completer<Database> _dbCompleter = Completer<Database>();

  // Stores
  static final _messageStore = stringMapStoreFactory.store('messages');
  static final _detailStore = stringMapStoreFactory.store('conversation_details');
  static final _conversationStore = stringMapStoreFactory.store('conversations');
  static final _contactStore = stringMapStoreFactory.store('contacts');
  static final _indexStore = StoreRef<String, List<Object?>>('search_index');

  Future<Database> get database async {
    if (_db != null) return _db!;
    if (!_dbCompleter.isCompleted) {
      await _initDatabase();
    }
    return _dbCompleter.future;
  }

  // 初始化
  static Future<void> init(String userId) async {
    if (_db != null && _currentUserId == userId) {
      if (!_dbCompleter.isCompleted) _dbCompleter.complete(_db);
      return;
    }
    await close();
    _currentUserId = userId;
    await _instance._initDatabase();
  }

  Future<void> _initDatabase() async {
    if (_db != null) return;
    final userId = _currentUserId ?? 'guest';
    final dbName = 'chat_app_v1_$userId.db';
    try {
      if (kIsWeb) {
        _db = await databaseFactoryWeb.openDatabase(dbName);
        //  关键修复：Web 端启动时，清理死掉的 Blob 路径
        await _clearDeadBlobs();
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        await appDir.create(recursive: true);
        final dbPath = join(appDir.path, dbName);
        _db = await databaseFactoryIo.openDatabase(dbPath);
      }
      if (!_dbCompleter.isCompleted) _dbCompleter.complete(_db);
    } catch (e) {
      if (!_dbCompleter.isCompleted) _dbCompleter.completeError(e);
      debugPrint("DB Init failed: $e");
    }
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _currentUserId = null;
      _dbCompleter = Completer<Database>();
    }
  }

  // Web 刷新修复逻辑：清理失效的 Blob 
  Future<void> _clearDeadBlobs() async {
    if (!kIsWeb || _db == null) return;
    try {
      // 查找所有以 blob: 开头的 localPath
      final finder = Finder(
        filter: Filter.matches('localPath', '^blob:'),
      );
      final records = await _messageStore.find(_db!, finder: finder);

      if (records.isNotEmpty) {
        debugPrint(" [Web Clean] Found ${records.length} dead blobs. Cleaning...");
        await _db!.transaction((txn) async {
          for (var record in records) {
            // 将 localPath 置空，这样 UI 就会自动去读 content (远程 URL)
            await _messageStore.record(record.key).update(txn, {
              'localPath': null,
              'resolvedPath': null,
              // previewBytes 保留，作为加载远程图时的缩略图
            });
          }
        });
      }
    } catch (e) {
      debugPrint("🧹 [Web Clean] Failed: $e");
    }
  }

  // ========================================================================
  //  核心防守逻辑：Socket 消息入口 (死保本地路径)
  // ========================================================================
  Future<void> handleIncomingMessage(ChatUiModel msg) async {
    final db = await database;

    await db.transaction((txn) async {
      final msgId = msg.id.trim();
      if (msgId.isEmpty) return;

      final record = _messageStore.record(msgId);
      final snapshot = await record.getSnapshot(txn);

      // 如果本地已经有记录，执行防守策略
      final dataToSave = _mergeMessageData(snapshot?.value, msg.toJson());

      await record.put(txn, dataToSave);

      // 更新会话列表
      final convKey = msg.conversationId;
      final convRecord = _conversationStore.record(convKey);
      final convSnap = await convRecord.getSnapshot(txn);

      final int currentUnread = (convSnap?.value['unreadCount'] as int?) ?? 0;
      final bool isNewMsg = (snapshot == null);
      final int newUnread = (isNewMsg && !msg.isMe) ? currentUnread + 1 : currentUnread;

      await convRecord.put(
        txn,
        {
          ...(convSnap?.value ?? {'id': convKey, 'type': 0, 'status': 1}),
          'lastMsgContent': _getPreviewContent(msg),
          'lastMsgTime': msg.createdAt,
          'lastMsgType': msg.type.value,
          'unreadCount': newUnread,
        },
        merge: true,
      );
    });

    _syncGlobalBadge();
  }

  /// 获取单条会话  （状态自愈)
  Future<Conversation?> getConversation(String id) async{
    final db = await database;
    final snapshot = await _conversationStore.record(id).getSnapshot(db);
    return snapshot !=null ? Conversation.fromJson(snapshot.value) : null;
  }

  /// 获取单条消息
  Future<ChatUiModel?> getMessageById(String msgId) async {
    final db = await database;
    final snapshot = await _messageStore.record(msgId).getSnapshot(db);
    return snapshot != null ? ChatUiModel.fromJson(snapshot.value) : null;
  }

  /// 获取所有发送中或失败的消息
  Future<List<ChatUiModel>> getPendingMessages() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.or([
        Filter.equals('status', MessageStatus.sending.name),
        Filter.equals('status', MessageStatus.failed.name),
      ]),
      sortOrders: [SortOrder('createdAt', true)],
    );
    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots.map((e) => ChatUiModel.fromJson(e.value)).toList();
  }

  /// 批量保存会话列表
  Future<void> saveConversations(List<Conversation> list) async {
    if (list.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final keys = list.map((c) => c.id).toList();
      final values = list.map((c) => c.toJson()).toList();
      await _conversationStore.records(keys).put(txn, values);
    });
  }

  /// 获取会话的最大 seqId
  Future<int?> getMaxSeqId(String conversationId) async {
    final db = await database;
    final s = await _messageStore.find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('conversationId', conversationId),
          Filter.notEquals('seqId', null),
        ]),
        sortOrders: [SortOrder('seqId', false)],
        limit: 1,
      ),
    );
    return s.isNotEmpty ? ChatUiModel.fromJson(s.first.value).seqId : null;
  }

  /// 清除未读数
  Future<void> clearUnreadCount(String conversationId) async {
    final db = await database;
    await db.transaction((txn) async {
      await _conversationStore.record(conversationId).update(txn, {
        'unreadCount': 0,
      });
    });
  }


  /// 更新消息状态
  Future<void> updateMessageStatus(String msgId, MessageStatus newStatus) async {
    await _messageStore.record(msgId).update(await database, {
      'status': newStatus.name,
    });
  }

  /// 删除单条消息
  Future<void> deleteMessage(String msgId) async {
    await _messageStore.record(msgId).delete(await database);
  }

  // 事务支持
  Future<T> runTransaction<T>(Future<T> Function(DatabaseClient txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  // ========================================================================
  // 🔍 搜索与联系人功能
  // ========================================================================

  Future<void> saveContacts(List<ChatUser> users) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var u in users) {
        await _contactStore.record(u.id).put(txn, u.toJson());
        await _updateSearchIndex(txn, u.id, u.nickname ?? '', 'user');
      }
    });
  }

  Future<List<ChatUser>> getAllContacts() async {
    final db = await database;
    final records = await _contactStore.find(db);
    return records.map((e) => ChatUser.fromJson(e.value)).toList();
  }

  Future<List<ChatUser>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    final db = await database;
    final k = 'user:${query.toLowerCase()}';

    final s = await _indexStore.record(k).getSnapshot(db);
    if (s != null) {
      final ids = List<String>.from(s.value as List);
      final snapshots = await _contactStore.records(ids).getSnapshots(db);
      return snapshots
          .where((e) => e != null)
          .map((e) => ChatUser.fromJson(e!.value))
          .toList();
    }
    return [];
  }

  Future<void> _updateSearchIndex(
      DatabaseClient txn,
      String id,
      String text,
      String type,
      ) async {
    if (text.isEmpty) return;
    final tokens = <String>{};
    final clean = text.toLowerCase();

    for (int i = 0; i < clean.length; i++) tokens.add(clean[i]);
    tokens.add(clean);

    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(text)) {
      try {
        final pinyin = PinyinHelper.getShortPinyin(text).toLowerCase();
        tokens.add(pinyin);
      } catch (_) {}
    }

    for (var t in tokens) {
      final k = '$type:$t';
      final r = _indexStore.record(k);
      final s = await r.getSnapshot(txn);
      final ids = s != null ? Set<String>.from(s.value as List) : <String>{};
      if (ids.add(id)) {
        await r.put(txn, ids.toList());
      }
    }
  }

  // ========================================================================
  // 📚 消息读取与预热
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
    return rawList;
  }

  Stream<List<ChatUiModel>> watchMessages(String conversationId, {int limit = 50}) async* {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)],
      limit: limit,
    );
    yield* _messageStore.query(finder: finder).onSnapshots(db).map((snapshots) {
      return snapshots.map((e) => ChatUiModel.fromJson(e.value)).toList();
    });
  }

  // ========================================================================
  // 🛠️ 基础 DAO 支持 (Patch, Update, Save)
  // ========================================================================

  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. 先查旧数据 (Snapshot)
      final record = _messageStore.record(msg.id);
      final snapshot = await record.getSnapshot(txn);


      final dataToSave = _mergeMessageData(snapshot?.value, msg.toJson());

      // 4. 保存合并后的数据
      await record.put(txn, dataToSave);

      // 5. 更新会话列表最后一条消息
      await _conversationStore.record(msg.conversationId).update(txn, {
        'lastMsgContent': _getPreviewContent(msg),
        'lastMsgTime': msg.createdAt,
        'lastMsgType': msg.type.value,
      });
    });
  }

  // 批量保存 (ChatViewModel 用)
// 批量保存 (ChatViewModel 用)
  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      for (final msg in msgs) {
        if (msg.id.trim().isEmpty) continue;

        final record = _messageStore.record(msg.id);
        final snapshot = await record.getSnapshot(txn);

        final dataToSave = _mergeMessageData(snapshot?.value, msg.toJson());

        await record.put(txn, dataToSave);
      }
    });
  }

  Future<void> patchFields(String id, Map<String, dynamic> updates) async {
    final db = await database;
    await db.transaction((txn) async {
      await _messageStore.record(id).update(txn, updates);
    });
  }

  // 别名方法
  Future<void> updateMessage(String id, Map<String, dynamic> updates) async =>
      patchFields(id, updates);

  Future<void> markMessagesAsRead(String conversationId, int maxSeqId) async {
    final db = await database;
    await db.transaction((txn) async {
      final finder = Finder(
        filter: Filter.and([
          Filter.equals('conversationId', conversationId),
          Filter.equals('isMe', false),
          Filter.lessThanOrEquals('seqId', maxSeqId),
          Filter.notEquals('status', 'read'),
        ]),
      );
      final records = await _messageStore.find(txn, finder: finder);
      for (var record in records) {
        await _messageStore.record(record.key).update(txn, {'status': 'read'});
      }

      final unreadFilter = Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.equals('isMe', false),
        Filter.notEquals('status', 'read'),
      ]);
      final remaining = await _messageStore.count(txn, filter: unreadFilter);
      await _conversationStore.record(conversationId).update(txn, {'unreadCount': remaining});
    });
    _syncGlobalBadge();
  }

  // ========================================================================
  // 📦 其他辅助方法
  // ========================================================================

  String _getPreviewContent(ChatUiModel msg) {
    switch (msg.type) {
      case MessageType.image: return '[图片]';
      case MessageType.video: return '[视频]';
      case MessageType.audio: return '[语音]';
      case MessageType.file: return '[文件]';
      case MessageType.location: return '[位置]';
      default: return msg.content;
    }
  }

  Future<void> _syncGlobalBadge() async {
    try {
      final db = await database;
      final snapshots = await _conversationStore.find(db);
      int total = 0;
      for (var snap in snapshots)
        total += (snap.value['unreadCount'] as int?) ?? 0;
      if (await AppBadgePlus.isSupported())
        total > 0 ? AppBadgePlus.updateBadge(total) : AppBadgePlus.updateBadge(0);
    } catch (_) {}
  }

  Future<void> clearAll() async => await _messageStore.delete(await database);

  Future<List<Conversation>> getConversations() async {
    final db = await database;
    final s = await _conversationStore.find(db, finder: Finder(sortOrders: [SortOrder('lastMsgTime', false)]));
    return s.map((e) => Conversation.fromJson(e.value)).toList();
  }

  Future<void> saveConversationDetail(ConversationDetail detail) async =>
      await _detailStore.record(detail.id).put(await database, detail.toJson());

  Future<ConversationDetail?> getConversationDetail(String id) async {
    final json = await _detailStore.record(id).get(await database);
    return json != null ? ConversationDetail.fromJson(json) : null;
  }

  /// 删除指定会话 (用于解散群、被踢)
  Future<void> deleteConversation(String id) async {
    final db = await database;
    await _conversationStore.record(id).delete(db);
  }

  /// 更新会话字段 (用于改名、改头像)
  Future<void> updateConversation(String id, Map<String, dynamic> updates) async {
    final db = await database;
    // 使用 update 只更新指定字段，不覆盖整个对象
    await _conversationStore.record(id).update(db, updates);
  }

  Future<void> doLocalRecall(String messageId, String tip) async {
    final db = await database;
    await db.transaction((txn) async {
      final record = _messageStore.record(messageId);
      final snapshot = await record.getSnapshot(txn);
      if (snapshot != null) {
        final oldMsg = ChatUiModel.fromJson(snapshot.value);
        final recalledMsg = oldMsg.copyWith(
          type: MessageType.recalled,
          content: tip,
          status: MessageStatus.success,
          localPath: null,
          resolvedPath: null,
        );
        await record.put(txn, recalledMsg.toJson());
      }
    });
  }

  //  [全局核心] 统一处理新旧数据合并
  Map<String, dynamic> _mergeMessageData(Map<String, dynamic>? oldData, Map<String, dynamic> newData) {
    if (oldData == null) return newData;

    // 以新数据（通常是服务器数据）为基准
    final merged = Map<String, dynamic>.from(newData);

    //  关键防守：如果新数据没路径（服务器不返），强行找回本地资产
    final String? oldLocal = oldData['localPath']?.toString();
    if ((merged['localPath'] == null || merged['localPath'].toString().isEmpty) &&
        (oldLocal != null && oldLocal.isNotEmpty && !oldLocal.startsWith('http'))) {
      merged['localPath'] = oldLocal;
      merged['resolvedPath'] = oldData['resolvedPath'];
    }

    //  关键防守：保护封面图和二进制数据
    if (merged['previewBytes'] == null && oldData['previewBytes'] != null) {
      merged['previewBytes'] = oldData['previewBytes'];
    }

    // 关键防守：Meta 信息深度合并 (防止服务器返回的部分 meta 覆盖了本地解析的宽高)
    final oldMeta = oldData['meta'] as Map<String, dynamic>? ?? {};
    final newMeta = merged['meta'] as Map<String, dynamic>? ?? {};
    merged['meta'] = {...oldMeta, ...newMeta};

    return merged;
  }
}