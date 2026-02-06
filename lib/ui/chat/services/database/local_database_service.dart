import 'dart:async';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
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

  /// [Core Modification] Get database instance
  /// If the database is not initialized, it won't throw an error but will [pause and wait] until init() completes.
  Future<Database> get database async {
    // 1. If already ready, return directly (fastest path)
    if (_db != null) {
      return _db!;
    }

    // 2. If not ready, return Future to let the caller wait (Key to solving OfflineQueue errors)
    debugPrint(" [LocalDB] Database not ready yet. Waiting...");
    return _dbCompleter.future;
  }

  /// Initialize: Open exclusive database for the passed userId
  static Future<void> init(String userId) async {
    // 1. If it's already this user's DB and it's ready
    if (_db != null && _currentUserId == userId) {
      if (!_dbCompleter.isCompleted) _dbCompleter.complete(_db);
      return;
    }

    // 2. If a previous user was logged in, close the old one and reset the waiter
    if (_db != null) {
      debugPrint(" [LocalDB] Closing DB for previous user: $_currentUserId");
      await _db!.close();
      _db = null;
      _dbCompleter = Completer<Database>(); // Reset traffic light
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

      //  [Key] Notify all waiting components (like OfflineQueue) to proceed
      if (!_dbCompleter.isCompleted) {
        _dbCompleter.complete(_db);
      }

      debugPrint(" [LocalDB] Initialized successfully: $dbName");
    } catch (e) {
      debugPrint(" [LocalDB] Init failed: $e");
      // If failed, tell waiters an error occurred to prevent permanent deadlock
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
      // Reset waiter, ensuring subsequent calls wait for init again
      _dbCompleter = Completer<Database>();
      debugPrint("🔒 [LocalDB] Database closed.");
    }
  }

  // ========================================================================
  //   Search Engine Kernel (Sembast Implementation)
  // ========================================================================

  /// Internal method: Update inverted index
  Future<void> _updateSearchIndex(
      DatabaseClient txn,
      String id,
      String text,
      String type,
      ) async {
    if (text.isEmpty) return;

    // 1. Tokenize
    final Set<String> tokens = {};
    final cleanText = text.toLowerCase();

    // A. Single character splitting
    for (int i = 0; i < cleanText.length; i++) {
      tokens.add(cleanText[i]);
    }

    // B. Pinyin processing
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

    // 2. Write to inverted index store
    for (final token in tokens) {
      final key = '$type:$token';
      final record = _indexStore.record(key);
      final snapshot = await record.getSnapshot(txn);

      Set<String> idSet = {};
      if (snapshot != null) {
        // value here is List<Object?>, needs casting
        idSet = Set<String>.from(snapshot.value as List);
      }

      if (!idSet.contains(id)) {
        idSet.add(id);
        await record.put(txn, idSet.toList());
      }
    }
  }

  // ========================================================================
  //   [New] Global Message Handling (Dedicated to Global Handler)
  // ========================================================================

  /// Atomic operation: Save message + Path protection + Update conversation summary + Accumulate unread count
  Future<void> handleIncomingMessage(ChatUiModel msg) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Prepare new data (This is from Socket/Sync, contains only URL, no localPath)
      var finalJson = msg.toJson();
      final msgId = msg.id;

      // ---------------------------------------------------------
      // 🛡️ Core Fix 1: Path Protection (Retrieve lost localPath)
      // ---------------------------------------------------------

      // A. Check existing record
      final existingRecord = await _messageStore.record(msgId).getSnapshot(txn);
      final exists = existingRecord != null; // Flag if already exists

      if (exists) {
        final oldData = existingRecord.value;
        final oldLocalPath = oldData['localPath'] as String?;

        // B. If old data has path, and new data doesn't, force restore it!
        if (oldLocalPath != null && oldLocalPath.isNotEmpty) {
          final newPath = finalJson['localPath'] as String?;
          if (newPath == null || newPath.isEmpty) {
            finalJson['localPath'] = oldLocalPath; // 👈 Rescued!
            // debugPrint("🛡️ [DB] Successfully preserved local path: $oldLocalPath");
          }
        }
      }

      // 2. Save blended perfect data (Overwrites old, but path is preserved)
      await _messageStore.record(msgId).put(txn, finalJson);

      // ---------------------------------------------------------
      // 🛡️ Core Fix 2: Anti-Chaos Red Dot (Prevent double counting)
      // ---------------------------------------------------------

      final convKey = msg.conversationId;
      final snapshot = await _conversationStore.record(convKey).getSnapshot(txn);

      // A. Get old unread count
      int currentUnread = 0;
      if (snapshot != null) {
        currentUnread = (snapshot.value['unreadCount'] as int?) ?? 0;
      }

      // B. Only allow +1 if message [did not exist before] AND [is not from me]
      // (Prevents unread count explosion due to Socket reconnects or duplicate FCM pushes)
      final shouldIncrement = !exists && !msg.isMe;
      final newUnread = shouldIncrement ? currentUnread + 1 : currentUnread;

      // 3. Update conversation store (Merge mode)
      await _conversationStore.record(convKey).put(txn, {
        ...(snapshot?.value ?? {'id': convKey, 'type': 0, 'status': 1}),
        'lastMsgContent': _getPreviewContent(msg),
        'lastMsgTime': msg.createdAt,
        'lastMsgType': msg.type.value,
        'unreadCount': newUnread,
      }, merge: true);
    });

    // 4. Finally refresh global badge
    _syncGlobalBadge();
  }

  /// [New] Private method: Calculate total unread and update desktop badge
  Future<void> _syncGlobalBadge() async {
    try {
      final db = await database;
      final snapshots = await _conversationStore.find(db);

      int total = 0;
      for (var snap in snapshots) {
        final count = (snap.value['unreadCount'] as int?) ?? 0;
        total += count;
      }

      if(kIsWeb){
        final String title = total > 0 ? '($total) ' : '';
        // 1. Modification: Directly modify document.title to show unread count
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(
            label: '$title Chat',
            primaryColor: 0xFF000000,
          ),
        );
        return;
      }

      // Directly call native layer update, works even if App is in background
      if (await FlutterAppBadger.isAppBadgeSupported()) {
        if (total > 0) {
          FlutterAppBadger.updateBadgeCount(total);
          debugPrint(" [DB] Background badge update success: $total");
        } else {
          FlutterAppBadger.removeBadge();
        }
      }
    } catch (e) {
      debugPrint(" [DB] Badge update failed: $e");
    }
  }

  /// Helper method: Generate preview text for conversation list
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

  /// Specifically for Chat Page: Clear unread count when entering room or receiving message
  Future<void> clearUnreadCount(String conversationId) async {
    final db = await database;
    // Directly update field, Sembast stream will automatically detect
    await _conversationStore.record(conversationId).update(db, {
      'unreadCount': 0,
    });
  }

  // ========================================================================
  //  Contacts (Integrated Search Capability)
  // ========================================================================

  /// Batch save contacts -> Automatically triggers indexing
  Future<void> saveContacts(List<ChatUser> users) async {
    final db = await database; // Waits for init completion
    await db.transaction((txn) async {
      for (var user in users) {
        // 1. Save raw data
        await _contactStore.record(user.id).put(txn, user.toJson());
        // 2. Build index
        await _updateSearchIndex(txn, user.id, user.nickname, 'user');
      }
    });
  }

  /// Get all contacts
  Future<List<ChatUser>> getAllContacts() async {
    final db = await database;
    final snapshots = await _contactStore.find(db);
    return snapshots.map((s) => ChatUser.fromJson(s.value)).toList();
  }

  /// Full-text search (Exposed interface)
  Future<List<ChatUser>> searchContacts(String query) async {
    if (query.isEmpty) return [];
    final db = await database;
    final cleanQuery = query.toLowerCase();

    // 1. Prioritize inverted index search
    final indexKey = 'user:$cleanQuery';
    final indexSnapshot = await _indexStore.record(indexKey).getSnapshot(db);

    Set<String> candidateIds = {};
    if (indexSnapshot != null) {
      candidateIds.addAll(List<String>.from(indexSnapshot.value as List));
    }

    List<ChatUser> results = [];

    if (candidateIds.isNotEmpty) {
      // Index hit
      final snapshots = await _contactStore
          .records(candidateIds.toList())
          .getSnapshots(db);
      results = snapshots
          .where((s) => s != null)
          .map((s) => ChatUser.fromJson(s!.value))
          .toList();
    } else {
      // Index miss, fallback to regex
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
  //  Message Related Business (CRUD)
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

    await db.transaction((txn) async {
      // 1. Find messages that need to be marked as read (Finder is correct here as find() needs Finder)
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

      // 2. Batch update status
      for (var record in records) {
        var map = Map<String, dynamic>.from(record.value);
        map['status'] = 'read';
        await _messageStore.record(record.key).put(txn, map);
      }

      // -----------------------------------------------------------
      // 🔥 Correction: Use Filter directly when counting remaining unread!
      // -----------------------------------------------------------

      final unreadFilter = Filter.and([
        Filter.equals('conversationId', conversationId),
        Filter.equals('isMe', false),
        Filter.notEquals('status', 'read'),
      ]);

      // ✅ Corrected: Parameter name is filter, not finder
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

    // 5. Refresh badge
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

  /// Get max seqId for the conversation in local DB (Audit)
  Future<int?> getMaxSeqId(String conversationId) async {
    final db = await database;

    final finder = Finder(
      filter: Filter.and([
        Filter.equals('conversationId', conversationId),
        // Must have seqId to count. Sending temp messages have null seqId, excluded from audit.
        Filter.notEquals('seqId', null),
      ]),
      // Take the first one by seqId descending order (Max value)
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
  //  Data Pre-warming (Path Processing)
  // ========================================================================

  Future<List<ChatUiModel>> _prewarmMessages(List<ChatUiModel> models) async {
    if (models.isEmpty) return [];

    final futures = models.map((msg) async {
      String? absPath;
      String? thumbPath;
      bool needsUpdate = false;

      // Process main file path
      if (msg.localPath != null && msg.localPath!.isNotEmpty) {
        bool isDeadBlob =
            kIsWeb &&
                msg.localPath!.startsWith('blob:') &&
                msg.status == MessageStatus.success;

        if (!isDeadBlob) {
          if (msg.localPath!.startsWith('http') ||
              msg.localPath!.startsWith('blob:')) {
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

      // Process thumbnail path
      if (msg.meta != null) {
        String? t = msg.meta!['thumb'] ?? msg.meta!['remote_thumb'];
        if (t != null && t.isNotEmpty) {
          if (t.startsWith('http') ||
              t.startsWith('blob:') ||
              t.contains('/')) {
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