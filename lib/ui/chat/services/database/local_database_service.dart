import 'dart:async';
import 'package:flutter/foundation.dart'; // 用于 kIsWeb
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart'; // 手机端
import 'package:sembast_web/sembast_web.dart';

import '../../models/chat_ui_model.dart';



class LocalDatabaseService {
  // 单例模式
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _db;

  // 定义 Store (相当于 SQL 里的表)
  // key 是 String (用 msgId), value 是 Map
  final _messageStore = stringMapStoreFactory.store('messages');

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
  // Sembast 会根据 Key (msg.id) 自动判断是 Insert 还是 Update
  Future<void> saveMessage(ChatUiModel msg) async {
    final db = await database;
    final record = _messageStore.record(msg.id);

    // 1. 先把新数据转成 Map
    Map<String, dynamic> dataToSave = msg.toJson();

    // 2.  关键操作：查一下旧数据
    final oldSnapshot = await record.getSnapshot(db);

    if (oldSnapshot != null) {
      final oldData = oldSnapshot.value;

      //  防御 1：如果新数据里 previewBytes 是 null，但旧数据里有，赶紧把旧的拿回来！
      if (dataToSave['previewBytes'] == null && oldData['previewBytes'] != null) {
        dataToSave['previewBytes'] = oldData['previewBytes'];
      }

      //  防御 2：localPath 同理（防止上传成功后，服务器回包把本地路径抹了）
      if (dataToSave['localPath'] == null && oldData['localPath'] != null) {
        dataToSave['localPath'] = oldData['localPath'];
      }

      //  防御 3：duration 同理
      if (dataToSave['duration'] == null && oldData['duration'] != null) {
        dataToSave['duration'] = oldData['duration'];
      }
    }

    // 3. 保存最终合并后的数据
    await record.put(db, dataToSave);
  }

  //  批量保存 (性能优化版，适合初次加载历史记录)
  Future<void> saveMessages(List<ChatUiModel> msgs) async {
    if (msgs.isEmpty) return;

    debugPrint("📦 [存库检查] 正在存入 ${msgs.length} 条。conv=${msgs.first.conversationId}");

    final db = await database;
    await db.transaction((txn) async {
      for (final msg in msgs) {
        try {
          // 关键：先验证主键
          if (msg.id.trim().isEmpty) {
            debugPrint("❌ [存库] 空 msg.id，跳过：${msg.toString()}");
            continue;
          }

          // 关键：先转 json（这里最容易炸）
          final json = msg.toJson();

          // 可选：再校验关键字段是否存在
          if (json['conversationId'] == null) {
            debugPrint("❌ [存库] conversationId 为 null：id=${msg.id} json=$json");
          }
          if (json['createdAt'] == null) {
            debugPrint("❌ [存库] createdAt 为 null：id=${msg.id} json=$json");
          }

          await _messageStore.record(msg.id).put(txn, json);
        } catch (e) {
          debugPrint("❌ [存库炸了] id=${msg.id} conv=${msg.conversationId} err=$e");
          debugPrint("❌ msg=$msg");
          // 如果你想更狠：把 msg.toJson() 也单独 try 一下看哪一步炸
          rethrow;
        }
      }
    });
  }

  //  [新增] 原子替换：在一个事务里完成删旧和存新
  // 完美解决发送成功瞬间的消息闪烁问题
  Future<void> replaceMessage(String oldId, ChatUiModel newMsg) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. 删除旧 ID (使用 txn 操作)
      await _messageStore.record(oldId).delete(txn);
      // 2. 写入新 ID (使用 txn 操作)
      await _messageStore.record(newMsg.id).put(txn, newMsg.toJson());
    });
  }
  Future<void> updateMessageStatus(String msgId, MessageStatus newStatus) async {

    final db = await database;
    //仅仅更新状态字段
    await _messageStore.record(msgId).update(db, {
      'status': newStatus.name,
    });
  }

  // 作用：只更新消息的特定字段（如 status, seqId, createdAt），不删旧记录，不改 ID
  // 结果：UI 组件不会销毁重建，彻底解决闪烁
  Future<void> updateMessage(String id, Map<String, dynamic> updates) async {
    final db = await database;
    // record.update 会合并 updates 到现有数据中，只修改你传的字段
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
        Filter.notEquals('status', 'read') // 还没变成已读的
      ]),
    );

    // 查出来
    final records = await _messageStore.find(db, finder: finder);

    // 批量更新
    for (var record in records) {
      // 保持原有数据，只改 status
      var map = Map<String, dynamic>.from(record.value);
      map['status'] = 'read'; // 对应 MessageStatus.read.name
      await _messageStore.record(record.key).put(db, map);
    }
  }

  Future<void> doLocalRecall(String messageId, String tip) async {
    // 1. 先查出旧消息 (为了保留 createdAt, sender 等信息)
    final existingMsg = await getMessageById(messageId);
    if (existingMsg == null) return;

    //修改属性
    final recalledMsg = existingMsg.copyWith(
      content: tip,
      type: MessageType.system,
      isRecalled: true,
      status: MessageStatus.success
    );

    // 3. 覆盖存入数据库 -> UI 自动监听到变化并刷新
    await saveMessage(recalledMsg);
  }

  //  [新增] 根据 ID 获取单条消息 (用于重发逻辑)
  Future<ChatUiModel?> getMessageById(String msgId) async {
    final db = await database;
    final recordSnapshot = await _messageStore.record(msgId).getSnapshot(db);
    if (recordSnapshot != null) {
      return ChatUiModel.fromJson(recordSnapshot.value);
    }
    return null;

  }

  //  获取特定会话的所有消息
  // 必须传入 conversationId，否则会把所有人的消息都查出来
  Future<List<ChatUiModel>> getMessagesByConversation(String conversationId) async {
    final db = await database;
    print("📥 获取会话 $conversationId 的消息");

    final finder = Finder(
      // 1. 过滤：只找当前会话的消息
      filter: Filter.equals('conversationId', conversationId),
      // 2. 排序：按时间倒序 (最新的在前面，适合聊天列表)
      sortOrders: [SortOrder('createdAt', false)],
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots.map((snapshot) => ChatUiModel.fromJson(snapshot.value)).toList();
  }

  // 监听特定会话的消息流 (Riverpod 用)
  // 只要这个会话有新消息存入，UI 会自动刷新
  Stream<List<ChatUiModel>> watchMessages(String conversationId) async* {

    //  [埋点 1] 打印正在查询的 ID，看看是否有空格或类型不对
    debugPrint(" [DB] 正在监听会话 ID: '$conversationId' (长度: ${conversationId.length})");

    // 确保数据库已初始化
    final db = await database;

    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
      sortOrders: [SortOrder('createdAt', false)], // 倒序
    );

    // query.onSnapshots 会返回一个流
    yield* _messageStore.query(finder: finder).onSnapshots(db).map((snapshots) {
      //  [埋点 2] 打印查到了多少条
      return snapshots.map((snapshot) {
        //  [埋点 3] (可选) 如果查到了但 UI 没显示，打印第一条看看数据结构对不对
        // debugPrint(" [DB] 第一条数据: ${snapshot.value}");
        return ChatUiModel.fromJson(snapshot.value);
      }).toList();
    });
  }
  // 即使重启 App，这些消息也能被捞出来重发
  Future<List<ChatUiModel>> getPendingMessages() async {
    final db = await database;
    final finder = Finder(
      filter: Filter.equals('status', MessageStatus.pending.name),
      sortOrders: [SortOrder('createdAt', true)], // 先发的先重试,正序
    );

    final snapshots = await _messageStore.find(db, finder: finder);
    return snapshots.map((snapshot) => ChatUiModel.fromJson(snapshot.value)).toList();
  }

  ////  [新增] 专门用于更新状态的方法 (比 updateMessage 更安全)
  Future<void> markMessageAsPending(String msgId) async {
    await updateMessageStatus(msgId, MessageStatus.pending);
  }


  //  删除单条消息
  Future<void> deleteMessage(String msgId) async {
    final db = await database;
    await _messageStore.record(msgId).delete(db);
  }

  //  清空某个会话的记录
  Future<void> clearConversation(String conversationId) async {
    final db = await database;
    final finder = Finder(filter: Filter.equals('conversationId', conversationId));
    await _messageStore.delete(db, finder: finder);
  }

  //  彻底清库 (退出登录用)
  Future<void> clearAll() async {
    final db = await database;
    await _messageStore.delete(db);
  }
}