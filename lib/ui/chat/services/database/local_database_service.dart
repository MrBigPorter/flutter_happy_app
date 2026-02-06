import 'dart:async';
import 'dart:convert';
import 'dart:io'; // [Modified] Added for File checking
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // Mobile
import 'package:sembast_web/sembast_web.dart'; // Web
import 'package:lpinyin/lpinyin.dart';

import '../../../../utils/media/media_path.dart';
import '../../models/chat_ui_model.dart';
import '../../models/conversation.dart';
import '../../../../utils/asset/asset_manager.dart';

class LocalDatabaseService {
  /// Constructor remains empty
  LocalDatabaseService();

  // ---------------------------------------------------------------------------
  //  Core: Static Connection Management & Suspension/Wait Mechanism (Completer)
  // ---------------------------------------------------------------------------

  static Database? _db;
  static String? _currentUserId;

  // This is a "traffic light". If the database is not ready, all requests will queue here.
  static Completer<Database> _dbCompleter = Completer<Database>();

  //  Basic Business Stores
  static final _messageStore = stringMapStoreFactory.store('messages');
  static final _detailStore = stringMapStoreFactory.store(
    'conversation_details',
  );
  static final _conversationStore = stringMapStoreFactory.store(
    'conversations',
  );

  //  Contacts & Search Store
  static final _contactStore = stringMapStoreFactory.store('contacts');

  //  Inverted Index Store (Value must be List<Object?> to be compatible with arrays)
  static final _indexStore = StoreRef<String, List<Object?>>('search_index');

  /// Get database instance
  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    debugPrint(" [LocalDB] Database not ready yet. Waiting...");
    return _dbCompleter.future;
  }

  /// Initialize: Open exclusive database for the passed userId
  static Future<void> init(String userId) async {
    if (_db != null && _currentUserId == userId) {
      if (!_dbCompleter.isCompleted) _dbCompleter.complete(_db);
      return;
    }

    if (_db != null) {
      debugPrint(" [LocalDB] Closing DB for previous user: $_currentUserId");
      await _db!.close();
      _db = null;
      _dbCompleter = Completer<Database>();
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

      if (!_dbCompleter.isCompleted) {
        _dbCompleter.complete(_db);
      }

      debugPrint(" [LocalDB] Initialized successfully: $dbName");
    } catch (e) {
      debugPrint(" [LocalDB] Init failed: $e");
      if (!_dbCompleter.isCompleted) _dbCompleter.completeError(e);
      rethrow;
    }
  }

  /// Close database
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _currentUserId = null;
      _dbCompleter = Completer<Database>();
      debugPrint("🔒 [LocalDB] Database closed.");
    }
  }

  // ========================================================================
  //   Search Engine Kernel (Sembast Implementation)
  // ========================================================================

  Future<void> _updateSearchIndex(
      DatabaseClient txn,
      String id,
      String text,
      String type,
      ) async {
    if (text.isEmpty) return;

    final Set<String> tokens = {};
    final cleanText = text.toLowerCase();

    for (int i = 0; i < cleanText.length; i++) {
      tokens.add(cleanText[i]);
    }

    if (RegExp(r'[\u4e00-\u9fa5]').hasMatch(text)) {
      try {
        String pinyinShort = PinyinHelper.getShortPinyin(text).toLowerCase();
        String pinyinFull = PinyinHelper.getPinyinE(
          text,
          separator: "",
        ).toLowerCase();
        tokens.add(pinyinShort);
        if (pinyinFull != pinyinShort) tokens.add(pinyinFull);
      } catch (e) {
        // ignore
      }
    }

    for (final token in tokens) {
      final key = '$type:$token';
      final record = _indexStore.record(key);
      final snapshot = await record.getSnapshot(txn);

      Set<String> idSet = {};
      if (snapshot != null) {
        idSet = Set<String>.from(snapshot.value as List);
      }

      if (!idSet.contains(id)) {
        idSet.add(id);
        await record.put(txn, idSet.toList());
      }
    }
  }

  // ========================================================================
  //   Global Message Handling (Dedicated to Global Handler)
  // ========================================================================

  /// Atomic operation: Save message + Path protection + Update conversation summary + Accumulate unread count
  Future<void> handleIncomingMessage(ChatUiModel msg) async {
    debugPrint("SOCKET msgId=${msg.id} conversationId=${msg.conversationId}");
    final db = await database;
    print(" [DB] Handling incoming message: ${msg.id} in conversation ${msg.conversationId}");

    await db.transaction((txn) async {
      final msgId = msg.id;
      final existingRecord = await _messageStore.record(msgId).getSnapshot(txn);

      Map<String, dynamic> finalJson = msg.toJson();

      if (existingRecord != null) {
        // [Preserved Fix] If record exists, merge new data with existing to protect paths
        finalJson = _mergeData(existingRecord.value, finalJson);
      }

      // 确保存入的是合并后的 finalJson
      await _messageStore.record(msgId).put(txn, finalJson);

      // Update conversation summary and unread count
      final convKey = msg.conversationId;
      final snapshot = await _conversationStore.record(convKey).getSnapshot(txn);
      int currentUnread = (snapshot?.value['unreadCount'] as int?) ?? 0;
      final exists = existingRecord != null;
      final newUnread = (!exists && !msg.isMe) ? currentUnread + 1 : currentUnread;

      await _conversationStore.record(convKey).put(txn, {
        ...(snapshot?.value ?? {'id': convKey, 'type': 0, 'status': 1}),
        'lastMsgContent': _getPreviewContent(msg),
        'lastMsgTime': msg.createdAt,
        'lastMsgType': msg.type.value,
        'unreadCount': newUnread,
      }, merge: true);
    });
    _syncGlobalBadge();
  }
  /// Private method: Calculate total unread and update desktop badge
  Future<void> _syncGlobalBadge() async {
    try {
      final db = await database;
      final snapshots = await _conversationStore.find(db);

      int total = 0;
      for (var snap in snapshots) {
        final count = (snap.value['unreadCount'] as int?) ?? 0;
        total += count;
      }

      if (kIsWeb) {
        final String title = total > 0 ? '($total) ' : '';
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(
            label: '$title Chat',
            primaryColor: 0xFF000000,
          ),
        );
        return;
      }

      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (total > 0) {
          FlutterAppBadger.updateBadgeCount(total);
        } else {
          FlutterAppBadger.removeBadge();
        }
      }
    } catch (e) {
      debugPrint(" [DB] Badge update failed: $e");
    }
  }

  String _getPreviewContent(ChatUiModel msg) {
    switch (msg.type) {
      case MessageType.image: return '[Image]';
      case MessageType.audio: return '[Voice]';
      case MessageType.video: return '[Video]';
      case MessageType.file: return '[File]';
      case MessageType.location: return '[Location]';
      case MessageType.recalled: return '[Message Recalled]';
      default: return msg.content;
    }
  }

  Future<void> clearUnreadCount(String conversationId) async {
    final db = await database;
    await _conversationStore.record(conversationId).update(db, {
      'unreadCount': 0,
    });
  }

  // ========================================================================
  //  Contacts
  // ========================================================================

  Future<void> saveContacts(List<ChatUser> users) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var user in users) {
        await _contactStore.record(user.id).put(txn, user.toJson());
        await _updateSearchIndex(txn, user.id, user.nickname, 'user');
      }
    });
  }

  Future<List<ChatUser>> getAllContacts() async {
    final db = await database;
    final snapshots = await _contactStore.find(db);
    return snapshots.map((s) => ChatUser.fromJson(s.value)).toList();
  }

  Future<List<ChatUser>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    final db = await database;
    final cleanQuery = query.toLowerCase();

    final indexKey = 'user:$cleanQuery';
    final indexSnapshot = await _indexStore.record(indexKey).getSnapshot(db);

    Set<String> candidateIds = {};
    if (indexSnapshot != null) {
      candidateIds.addAll(List<String>.from(indexSnapshot.value as List));
    }

    List<ChatUser> results = [];

    if (candidateIds.isNotEmpty) {
      final snapshots = await _contactStore
          .records(candidateIds.toList())
          .getSnapshots(db);
      results = snapshots
          .where((s) => s != null)
          .map((s) => ChatUser.fromJson(s!.value))
          .toList();
    } else {
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
  //  Message CRUD
  // ========================================================================

  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    await db.transaction((txn) async {
      final msgId = msg.id;
      final existingRecord = await _messageStore.record(msgId).getSnapshot(txn);

      Map<String, dynamic> finalJson = msg.toJson();

      if (existingRecord != null) {
        finalJson = _mergeData(existingRecord.value, finalJson);
      }

      await _messageStore.record(msgId).put(txn, finalJson);
    });
  }

  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;
    final db = await database;

    await db.transaction((txn) async {
      for (final msg in msgs) {
        final id = msg.id.trim();
        if (id.isEmpty) continue;

        final record = _messageStore.record(id);
        final snapshot = await record.getSnapshot(txn);

        Map<String, dynamic> json = msg.toJson();
        if (snapshot != null) {
          json = _mergeData(snapshot.value, json); // 保护 localPath/resolvedPath
        }


        await record.put(txn, json);
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
    await db.transaction((txn) async {
      final record = _messageStore.record(id);
      final snapshot = await record.getSnapshot(txn);

      Map<String, dynamic> finalUpdates = updates;

      if (snapshot != null) {
        //  这里会保护已经存入数据库的 resolvedPath
        finalUpdates = _mergeData(snapshot.value, updates);
      }

      //  确保存入的是合并后的 finalUpdates
      await record.put(txn, finalUpdates, merge: true);
    });
  }

  Future<void> markMessagesAsRead(String conversationId, int maxSeqId) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Find messages to mark as read
      final finder = Finder(
        filter: Filter.and([
          Filter.equals('conversationId', conversationId),
          Filter.equals('isMe', false),
          Filter.lessThanOrEquals('seqId', maxSeqId),
          Filter.notEquals('status', 'read'),
        ]),
      );

      final records = await _messageStore.find(txn, finder: finder);

      if (records.isEmpty) return;

      // 2. Batch update
      for (var record in records) {
        var map = Map<String, dynamic>.from(record.value);
        map['status'] = 'read';
        await _messageStore.record(record.key).put(txn, map);
      }

      // -----------------------------------------------------------
      // [Preserved Fix] Count remaining unread using Filter (not Finder)
      // -----------------------------------------------------------
      final unreadFilter = Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.equals('isMe', false),
        Filter.notEquals('status', 'read'),
      ]);

      final remainingUnreadCount = await _messageStore.count(txn, filter: unreadFilter);

      // 4. Update conversation table
      final convRecord = _conversationStore.record(conversationId);
      final convSnapshot = await convRecord.getSnapshot(txn);

      if (convSnapshot != null) {
        await convRecord.update(txn, {
          'unreadCount': remainingUnreadCount,
        });
        debugPrint(" [DB] Read Sync: Conversation $conversationId unread count corrected to $remainingUnreadCount");
      }
    });

    _syncGlobalBadge();
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

  Future<int?> getMaxSeqId(String conversationId) async {
    final db = await database;
    final finder = Finder(
      filter: Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.notEquals('seqId', null),
      ]),
      sortOrders: [SortOrder('seqId', false)],
      limit: 1,
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    if (snapshots.isNotEmpty) {
      final msg = ChatUiModel.fromJson(snapshots.first.value);
      return msg.seqId;
    }
    return null;
  }

  // ========================================================================
  //  Conversation List Related
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
    return snapshots
        .map((s) {
      try {
        return Conversation.fromJson(s.value);
      } catch (e) {
        return null;
      }
    })
        .whereType<Conversation>()
        .toList();
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
  //  Stream Listeners
  // ========================================================================

  Stream<List<ChatUiModel>> watchMessages(
      String conversationId, {
        int limit = 50,
      }) async* {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)],
      limit: limit,
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

  Future<void> clearAll() async {
    final db = await database;
    await _messageStore.delete(db);
  }

  // ========================================================================
  //  [Modified] Data Pre-warming (Refactored Path Processing)
  //  Divided into: Entry -> ResolveMain -> ResolveThumb -> Helpers
  // ========================================================================

  /// Entry method: Iterates and dispatches resolution
  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    final futures = models.map((msg) async {
      // 1. Resolve Main File Path
      final String? resolvedPath = await _resolveMainPath(msg);
      print(" [Prewarm] Message ${msg.id} resolvedPath: $resolvedPath");

      // 2. Resolve Thumbnail Path
      final String? thumbPath = await _resolveThumbPath(msg);

      // 3. Performance Optimization: Only copyWith if changed
      if (resolvedPath != msg.resolvedPath || thumbPath != msg.resolvedThumbPath) {
        return msg.copyWith(
          resolvedPath: resolvedPath,
          resolvedThumbPath: thumbPath,
        );
      }
      return msg;
    });

    return await Future.wait(futures);
  }

  // ---------------------------------------------------------------------------
  //  Core 1: Main Path Resolution Strategy
  // ---------------------------------------------------------------------------

  bool _isLocalAbs(String s) => s.startsWith('/') || s.startsWith('file://') || s.startsWith('blob:');

  Future<String?> _resolveMainPath(ChatUiModel msg) async {
    final rp = msg.resolvedPath;
    if (rp != null && _isLocalAbs(rp)) return rp;

    final lp = msg.localPath;
    if (lp != null && lp.isNotEmpty) {
      final localHit = await _tryFindLocalFile(lp, msg.type);
      if (localHit != null) return localHit; // 返回本地绝对路径
    }

    return _resolveRemoteUrlByType(msg.type, msg.content); // 只返回远端 URL
  }


  // ---------------------------------------------------------------------------
  //  Core 2: Thumbnail Resolution Strategy
  // ---------------------------------------------------------------------------

  Future<String?> _resolveThumbPath(ChatUiModel msg) async {
    if (msg.meta == null) return null;

    // Prioritize 'thumb' field, then 'remote_thumb'
    final String? t = msg.meta!['thumb'] ?? msg.meta!['remote_thumb'];
    if (t == null || t.isEmpty) return null;

    // A. Priority 1: Brute-force check local file
    final String? localHit = await _tryFindLocalFile(t, MessageType.image);
    if (localHit != null) return localHit;

    // B. Priority 2: Generate Network URL
    return UrlResolver.resolveImage(null, t);
  }

  // ---------------------------------------------------------------------------
  //  Common Helper: Try Find Local File (Clean Logic)
  // ---------------------------------------------------------------------------

  /// Accepts a path or ID, attempts to return a real existing local absolute path.
  /// Returns null if not found.
  Future<String?> _tryFindLocalFile(String rawPath, MessageType type) async {
    // 1. Web Logic (Trust blindly as file system is inaccessible)
    if (kIsWeb) {
      if (rawPath.startsWith('blob:') || rawPath.length > 50) {
        return rawPath;
      }
      return null;
    }

    // 2. Ignore HTTP links
    if (rawPath.startsWith('http')) return null;

    // 2. Direct File Check
    final file = File(rawPath);
    if (file.existsSync()) return rawPath;

    // 3. Mobile Logic: Use AssetManager to resolve potential local paths
    final String? assetPath = await AssetManager.getFullPath(rawPath, type);
    if (assetPath != null) {
      bool exists = File(assetPath).existsSync();
      //  Log 4: 追踪 AssetManager 结果
      //debugPrint(" [LocalDB-Finder] AssetManager: $rawPath -> $assetPath (Exists: $exists)");
      if (exists) return assetPath;
    }

    // 4. Fallback Directory Check
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final subDir = type == MessageType.video ? 'chat_video' : 'chat_images';
      final fallback = join(docDir.path, subDir, rawPath);
      if (File(fallback).existsSync()) {
       // debugPrint(" [LocalDB-Finder] Subdir Hit: $fallback");
        return fallback;
      }
    } catch (_) {}

    return null; // Really no local file found
  }

  // ---------------------------------------------------------------------------
  //  Common Helper: Network URL Mapping
  // ---------------------------------------------------------------------------

  String? _resolveRemoteUrlByType(MessageType type, String? content) {
    if (content == null || content.isEmpty) return null;

    switch (type) {
      case MessageType.image:
        return UrlResolver.resolveImage(null, content);
      case MessageType.video:
        return UrlResolver.resolveVideo(content);
      case MessageType.audio:
      case MessageType.file:
      case MessageType.location: // Location usually has no remote url, or content is url
        return UrlResolver.resolveFile(content);
      default:
        return content;
    }
  }

  // ---------------------------------------------------------------------------
  //  [Modified] Data Merge Helper (For Future Use, Not Currently Invoked)
  //  This can be used in future update scenarios to intelligently merge new data with existing records
  // ---------------------------------------------------------------------------
  //  CHANGED: 本地优先合并策略（远端不能覆盖本地）
  Map<String, dynamic> _mergeData(Map<String, dynamic> oldData, Map<String, dynamic> newData) {
    final Map<String, dynamic> merged = Map<String, dynamic>.from(newData);

    //  这些字段属于“本地资产锚点”，必须本地优先
    final protectedKeys = ['localPath', 'resolvedPath', 'resolvedThumbPath'];

    for (final key in protectedKeys) {
      final newVal = (newData[key] ?? '').toString().trim();
      final oldVal = (oldData[key] ?? '').toString().trim();

      if (oldVal.isEmpty) continue;

      // 1) 新值为空：保旧（你原来的逻辑）
      if (newVal.isEmpty) {
        merged[key] = oldVal;
        continue;
      }

      // 2)  本地优先：旧值本地，新值远端 → 保旧
      if (MediaPath.isLocal(oldVal) && MediaPath.isRemote(newVal)) {
        merged[key] = oldVal;
        continue;
      }

      // 3) = 旧值是“更具体”的本地绝对路径，新值只是 uploads key → 保旧
      // （这是最常见的：本地 /var/... 被服务端 uploads/... 覆盖）
      if (MediaPath.classify(oldVal) == MediaPathType.localAbs &&
          MediaPath.classify(newVal) == MediaPathType.uploads) {
        merged[key] = oldVal;
        continue;
      }

      // 4)  同为远端：统一成 key（uploads/...），避免时而存完整域名、时而存 key
      // （可选但推荐，能减少“比较/去重/缓存命中”的混乱）
      if (MediaPath.isRemote(oldVal) && MediaPath.isRemote(newVal)) {
        merged[key] = MediaPath.normalizeRemoteKey(newVal);
        continue;
      }
    }

    return merged;
  }
}