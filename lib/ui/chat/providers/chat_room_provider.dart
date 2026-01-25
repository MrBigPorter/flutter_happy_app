import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import '../../../utils/upload/global_upload_service.dart';
import '../../../utils/upload/upload_types.dart';
import '../models/conversation.dart';
import '../services/compression/image_compression_service.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

// --- Providers ---
final chatStreamProvider = StreamProvider.family
    .autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
      return LocalDatabaseService().watchMessages(conversationId);
    });

final chatLoadingMoreProvider = StateProvider.family<bool, String>(
  (ref, id) => false,
);

final chatControllerProvider = Provider.family
    .autoDispose<ChatRoomController, String>((ref, conversationId) {
      final socketService = ref.read(socketServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);
      final controller = ChatRoomController(
        socketService,
        uploadService,
        conversationId,
        ref,
      );
      ref.onDispose(() => controller.dispose());
      return controller;
    });

class ChatRoomController with WidgetsBindingObserver {
  final SocketService _socketService;
  final GlobalUploadService _uploadService;
  final String conversationId;
  final Ref _ref;

  StreamSubscription? _msgSub, _readStatusSub, _connectionSub, _recallSub;
  final _readReceiptSubject = PublishSubject<void>();
  final Set<String> _processedMsgIds = {};
  bool _mounted = true;
  String? _nextCursor;
  bool _isLoadingMore = false;
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;

  String get _currentUserId => _ref.read(luckyProvider).userInfo?.id ?? "";

  static final Map<String, String> _sessionPathCache = {};

  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatRoomController(
    this._socketService,
    this._uploadService,
    this.conversationId,
    this._ref,
  ) {
    WidgetsBinding.instance.addObserver(this);
    _setup();
    _setupReadReceiptDebounce();
  }

  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();
    _recallSub?.cancel();
    _readReceiptSubject.close();
  }

  // --- Initialization & Socket ---
  Future<void> _setup() async {
    _connectionSub = _socketService.onSyncNeeded.listen((_) => _joinRoom());
    if (_socketService.isConnected) _joinRoom();
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(
      _onReadStatusUpdate,
    );
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  void _joinRoom() {
    if (_socketService.isConnected) _socketService.joinChatRoom(conversationId);
  }

  // --- Read Receipts ---
  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((
      _,
    ) {
      if (_mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _executeMarkRead();
      }
    });
  }

  void markAsRead() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
      _executeMarkRead();
  }

  void _executeMarkRead() {
    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}
    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    );
  }

  // --- Data Refresh & Pagination (修复丢失的方法) ---
  Future<void> refresh() async {
    try {
      markAsRead();
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 20,
          cursor: null,
        ),
      );
      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      final uiMsgs = _applyReadStatusLocally(
        _mapToUiModels(response.list),
        _maxReadSeqId,
      );
      await LocalDatabaseService().saveMessages(uiMsgs);
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    _isLoadingMore = true;
    _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = true;
    try {
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 20,
          cursor: _nextCursor,
        ),
      );
      _nextCursor = response.nextCursor;
      final uiMsgs = _applyReadStatusLocally(
        _mapToUiModels(response.list),
        _maxReadSeqId,
      );
      await LocalDatabaseService().saveMessages(uiMsgs);
    } catch (e) {
      debugPrint("Load More Error: $e");
    } finally {
      _isLoadingMore = false;
      _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = false;
    }
  }

  // --- Message Sending (修复丢失的方法) ---
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _createBaseMessage(content: text, type: MessageType.text);
    await _handleOptimisticSend(
      msg,
      networkTask: () async =>
          Api.sendMessage(msg.id, conversationId, text, MessageType.text.value),
    );
  }

  Future<void> sendImage(XFile file) async {
    final msgId = const Uuid().v4();

    // 1. 并发处理：生成微缩图 + 物理搬家
    final results = await Future.wait([
     ImageCompressionService.getTinyThumbnail(file),// 生成 <50KB 字节流
     _processLocalImage(file)// 物理落户 chat_images/
    ]);


    // 2. 等待微缩图生成 (极快)，用于首屏渲染
    final Uint8List previewBytes = results[0] as Uint8List;
    final processed = results[1] as dynamic; // 包含 relativePath, absolutePath, meta
    // 3. 缓存绝对路径
    _sessionPathCache[msgId] = processed.absolutePath; // 内存缓存存绝对路径防止闪烁

    // 4. 创建消息模型并乐观发送
    final msg = _createBaseMessage(
      id: msgId,
      content: "[Image]",
      type: MessageType.image,
      localPath: processed.relativePath,
      previewBytes: previewBytes, //  写入数据库的关键字节
      meta: processed.meta,
    );

    // 5. 处理乐观发送逻辑
    await _handleOptimisticSend(
      msg,
      networkTask: () async {
        final cdnUrl = await _uploadService.uploadFile(
          file: XFile(processed.absolutePath),
          module: UploadModule.chat,
          onProgress: (_) {},
        );
        return Api.sendMessage(
          msg.id,
          conversationId,
          cdnUrl,
          MessageType.image.value,
          width: processed.width,
          height: processed.height,
        );
      },
    );
  }

  ///
  Future<void> sendVoiceMessage(String path, int duration) async {
    // A. 预处理：将语音从临时目录搬到持久化目录，获取文件名
    final processed = await _processLocalAudio(path);
    final msgId = const Uuid().v4();

    _sessionPathCache[msgId] = processed.absolutePath; // 内存缓存存绝对路径防止闪烁

    final msg = _createBaseMessage(
      content: "[Voice]",
      type: MessageType.audio,
      localPath: processed.relativePath, // 存入 DB 的是文件名
      duration: duration,
    );
    await _handleOptimisticSend(
      msg,
      networkTask: () async {
        final cdnUrl = await _uploadService.uploadFile(
          file: XFile(
            processed.absolutePath,
            name: '${const Uuid().v4()}.m4a',
            mimeType: 'audio/mp4',
          ),
          module: UploadModule.chat,
          onProgress: (_) {},
        );
        return Api.sendMessage(
          msg.id,
          conversationId,
          cdnUrl,
          MessageType.audio.value,
          duration: duration,
        );
      },
    );
  }

  // --- Message Recall & Delete (修复丢失的方法) ---
  Future<void> recallMessage(String messageId) async {
    try {
      final res = await Api.messageRecallApi(
        MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId,
        ),
      );
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
      _updateConversationList(
        "[message recalled]",
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint("Recall Error: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await LocalDatabaseService().deleteMessage(messageId);
      await Api.messageDeleteApi(
        MessageDeleteRequest(
          messageId: messageId,
          conversationId: conversationId,
        ),
      );
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  Future<void> resendMessage(String msgId) async {
    final target = await LocalDatabaseService().getMessageById(msgId);
    if (target == null) return;
    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _handleOptimisticSend(
      msg,
      networkTask: () async {
        final appDir = await getApplicationDocumentsDirectory();
        if (target.type == MessageType.image && target.localPath != null) {
          final absPath = p.join(appDir.path, 'chat_images', target.localPath!);
          final cdnUrl = await _uploadService.uploadFile(
            file: XFile(absPath),
            module: UploadModule.chat,
            onProgress: (_) {},
          );
          return Api.sendMessage(
            msgId,
            conversationId,
            cdnUrl,
            MessageType.image.value,
            width: (target.meta?['w'] as num?)?.toInt(),
            height: (target.meta?['h'] as num?)?.toInt(),
          );
        }else if(target.type == MessageType.audio && target.localPath != null) {
          final absPath = p.join(appDir.path, 'chat_audio', target.localPath!);
          final cdnUrl = await _uploadService.uploadFile(
            file: XFile(absPath, mimeType: 'audio/mp4'),
            module: UploadModule.chat,
            onProgress: (_) {},
          );
          return Api.sendMessage(msgId, conversationId, cdnUrl, MessageType.audio.value, duration: target.duration);
        }
        return Api.sendMessage(
          msgId,
          conversationId,
          target.content,
          target.type.value,
        );
      },
    );
  }

  // --- Helpers & Internal Engine ---
  ChatUiModel _createBaseMessage({
    String? id,
    required String content,
    required MessageType type,
    String? localPath,
    Uint8List? previewBytes,
    Map<String, dynamic>? meta,
    int? duration,
  }) {
    return ChatUiModel(
      id: id ?? const Uuid().v4(),
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localPath: localPath,
      previewBytes: previewBytes,
      meta: meta,
      duration: duration,
    );
  }

  Future<void> _handleOptimisticSend(
    ChatUiModel msg, {
    required Future<ChatMessage> Function() networkTask,
  }) async {
    try {
      print("📤 Sending message optimistically: ${msg.previewBytes}");
      await LocalDatabaseService().saveMessage(msg);
      _updateConversationList(msg.content, msg.createdAt);
      final serverMsg = await networkTask();
      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': serverMsg.createdAt,
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': serverMsg.content,
      });
    } catch (e) {
      await LocalDatabaseService().updateMessageStatus(
        msg.id,
        MessageStatus.pending,
      );
      OfflineQueueManager().startFlush();
    }
  }

  //  修复 Record 类型错误
  Future<
    ({
      String relativePath,
      String absolutePath,
      int width,
      int height,
      Map<String, dynamic> meta,
    })
  >
  _processLocalImage(XFile file) async {
    String relPath = "";
    String absPath = "";
    if (kIsWeb) {
      relPath = file.path;
      absPath = file.path;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(appDir.path, 'chat_images'));
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
      relPath = p.basename(file.path);
      absPath = p.join(imagesDir.path, relPath);
      await File(absPath).writeAsBytes(await file.readAsBytes());
    }

    int w = 0, h = 0;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      w = frameInfo.image.width;
      h = frameInfo.image.height;
    } catch (_) {}

    final Map<String, dynamic> metaData = w > 0
        ? {'w': w, 'h': h}
        : <String, dynamic>{};

    return (
      relativePath: relPath, absolutePath: absPath, width: w, height: h,
      meta: metaData, // 这里强制使用了 Map<String, dynamic> 类型
    );
  }

  /// 语音预处理：实现“永久居住证”
  Future<({String relativePath, String absolutePath})> _processLocalAudio(String tempPath) async {
    if (kIsWeb) return (relativePath: tempPath, absolutePath: tempPath);

    // 创建持久化目录
    final appDir = await getApplicationDocumentsDirectory();
    // chat_audio 目录
    final audioDir = Directory(p.join(appDir.path, 'chat_audio'));
    // 确保目录存在
    if (!await audioDir.exists()) await audioDir.create(recursive: true);

    // 生成文件名和绝对路径
    final fileName = p.basename(tempPath);
    // 绝对路径
    final absolutePath = p.join(audioDir.path, fileName);

    // 执行物理搬家
    await File(tempPath).copy(absolutePath);

    return (relativePath: fileName, absolutePath: absolutePath);
  }
  // --- Socket Handlers & Mapping ---
  void _onSocketMessage(Map<String, dynamic> data) async {
    if (!_mounted) return;
    final msg = SocketMessage.fromJson(data);
    if (msg.conversationId != conversationId ||
        _processedMsgIds.contains(msg.id) ||
        msg.sender?.id == _currentUserId)
      return;
    _processedMsgIds.add(msg.id);
    if (_processedMsgIds.length > 50)
      _processedMsgIds.remove(_processedMsgIds.first);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
      _readReceiptSubject.add(null);
    final uiMsg = ChatUiModel.fromApiModel(
      ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
      ),
      conversationId,
      _currentUserId,
    );
    await LocalDatabaseService().saveMessage(uiMsg);
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (!_mounted ||
        event.conversationId != conversationId ||
        event.readerId == _currentUserId)
      return;
    if (event.lastReadSeqId > _maxReadSeqId)
      _maxReadSeqId = event.lastReadSeqId;
    await LocalDatabaseService().markMessagesAsRead(
      conversationId,
      _maxReadSeqId,
    );
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf
        ? "You unsent a message"
        : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateConversationList(tip, DateTime.now().millisecondsSinceEpoch);
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> list) => list
      .map(
        (dto) => ChatUiModel.fromApiModel(dto, conversationId, _currentUserId),
      )
      .toList();

  List<ChatUiModel> _applyReadStatusLocally(
    List<ChatUiModel> list,
    int waterLine,
  ) {
    return list
        .map(
          (msg) =>
              (msg.isMe &&
                  msg.status == MessageStatus.success &&
                  msg.seqId != null &&
                  msg.seqId! <= waterLine)
              ? msg.copyWith(status: MessageStatus.read)
              : msg,
        )
        .toList();
  }

  void _updateConversationList(String text, int time) {
    try {
      _ref
          .read(conversationListProvider.notifier)
          .updateLocalItem(
            conversationId: conversationId,
            lastMsgContent: text,
            lastMsgTime: time,
          );
    } catch (_) {}
  }
}
