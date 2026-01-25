import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui; // 用于获取图片尺寸
import 'package:camera/camera.dart'; // For XFile
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // For WidgetsBindingObserver
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:path/path.dart' as p;

// 引入你的项目文件
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import '../../../utils/upload/global_upload_service.dart';
import '../../../utils/upload/upload_types.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

// ===========================================================================
//  1. Read: Data Stream Provider
// ===========================================================================
final chatStreamProvider = StreamProvider.family
    .autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
      return LocalDatabaseService().watchMessages(conversationId);
    });

final chatLoadingMoreProvider = StateProvider.family<bool, String>(
  (ref, id) => false,
);

// ===========================================================================
//  2. Write: Business Logic Controller
// ===========================================================================
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

      ref.onDispose(() {
        controller.dispose();
      });

      return controller;
    });

class ChatRoomController with WidgetsBindingObserver {
  final SocketService _socketService;
  final GlobalUploadService _uploadService;
  final String conversationId;
  final Ref _ref;

  // 订阅管理
  StreamSubscription? _msgSub;
  StreamSubscription? _readStatusSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _recallSub;
  StreamSubscription? _dbSubscription;

  // 已读回执防抖
  final _readReceiptSubject = PublishSubject<void>();

  //  [去重] 缓存最近处理过的消息 ID，防止双重广播回声
  final Set<String> _processedMsgIds = {};

  //  [生命周期] 存活标记
  bool _mounted = true;

  String? _nextCursor;
  bool _isLoadingMore = false;
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;

  String get _currentUserId => _ref.read(luckyProvider).userInfo?.id ?? "";

  //  [零抖动] 静态缓存：防止 Web 端/列表刷新时图片路径丢失导致的闪烁
  static final Map<String, String> _sessionPathCache = {};

  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatRoomController(
    this._socketService,
    this._uploadService,
    this.conversationId,
    this._ref,
  ) {
    // 注册生命周期监听 (为了在前台才发已读)
    WidgetsBinding.instance.addObserver(this);
    _setup();
    _setupReadReceiptDebounce();
  }

  // ===========================================================================
  //  Setup & Dispose
  // ===========================================================================

  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this); // 移除监听

    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();
    _recallSub?.cancel();
    _dbSubscription?.cancel();
    _readReceiptSubject.close();
  }

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
    if (_socketService.isConnected) {
      _socketService.joinChatRoom(conversationId);
    }
  }

  // ===========================================================================
  //  Read Receipt Logic (生命周期感知)
  // ===========================================================================

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((
      _,
    ) {
      // 🔒 只有当前 Controller 存活，且 App 处于前台时，才真正发送网络请求
      if (_mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _executeMarkRead();
      }
    });
  }

  // 公开方法：进页面时强刷一次
  void markAsRead() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _executeMarkRead();
    }
  }

  void _executeMarkRead() {
    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}
    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    );
  }

  // ===========================================================================
  //  Data Refresh
  // ===========================================================================

  Future<void> refresh() async {
    try {
      markAsRead(); // 进门消红
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: null,
      );
      final response = await Api.chatMessagesApi(request);

      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      final uiMessages = _mapToUiModels(response.list);
      final processedList = _applyReadStatusLocally(uiMessages, _maxReadSeqId);

      await LocalDatabaseService().saveMessages(processedList);
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    _isLoadingMore = true;
    _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = true;

    try {
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: _nextCursor,
      );
      final response = await Api.chatMessagesApi(request);
      _nextCursor = response.nextCursor;

      final moreMessages = _mapToUiModels(response.list);
      final processedList = _applyReadStatusLocally(
        moreMessages,
        _maxReadSeqId,
      );

      await LocalDatabaseService().saveMessages(processedList);
    } catch (e) {
      debugPrint("Load more failed: $e");
    } finally {
      _isLoadingMore = false;
      _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = false;
    }
  }

  // ===========================================================================
  //  🚀 [核心管道] 统一发送入口 (Pipeline)
  // ===========================================================================

  /// 1. 发送文本
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msg = _createBaseMessage(content: text, type: MessageType.text);

    await _handleOptimisticSend(
      msg,
      networkTask: () async =>
          Api.sendMessage(msg.id, conversationId, text, MessageType.text.value),
    );
  }

  /// 2. 发送图片
  Future<void> sendImage(XFile file) async {
    // A. 预处理：算宽高、存本地
    final processed = await _processLocalImage(file);

    // B. 构造模型
    final msg = _createBaseMessage(
      content: "[Image]",
      type: MessageType.image,
      localPath: processed.finalPath,
      meta: processed.meta,
    );

    // C. 进入管道
    await _handleOptimisticSend(
      msg,
      networkTask: () async {
        // 先传 CDN
        final cdnUrl = await _uploadService.uploadFile(
          file: processed.fileToUpload,
          module: UploadModule.chat,
          onProgress: (_) {},
        );
        // 再调 API (携带宽高)
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

  /// 3. 发送语音
  Future<void> sendVoiceMessage(String path, int duration) async {
    final msg = _createBaseMessage(
      content: "[Voice]",
      type: MessageType.audio,
      localPath: path,
      duration: duration,
    );

    await _handleOptimisticSend(
      msg,
      networkTask: () async {
        final fileToUpload = XFile(
          path,
          name: '${const Uuid().v4()}.m4a',
          mimeType: 'audio/mp4',
        );
        final cdnUrl = await _uploadService.uploadFile(
          file: fileToUpload,
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

  /// 4. 重发逻辑 (复用管道)
  Future<void> resendMessage(String msgId) async {
    final targetMsg = await LocalDatabaseService().getMessageById(msgId);
    if (targetMsg == null) return;

    // 刷新时间，重置状态
    final newTime = DateTime.now().millisecondsSinceEpoch;
    final sendingMsg = targetMsg.copyWith(
      status: MessageStatus.sending,
      createdAt: newTime,
    );

    await _handleOptimisticSend(
      sendingMsg,
      networkTask: () async {
        // 根据类型分发任务
        if (targetMsg.type == MessageType.image &&
            targetMsg.localPath != null) {
          final w = (targetMsg.meta?['w'] as num?)?.toInt();
          final h = (targetMsg.meta?['h'] as num?)?.toInt();
          final file = XFile(targetMsg.localPath!);

          // 重新上传 (生产环境可优化为检查 CDN 是否有效)
          final cdnUrl = await _uploadService.uploadFile(
            file: file,
            module: UploadModule.chat,
            onProgress: (_) {},
          );
          return Api.sendMessage(
            msgId,
            conversationId,
            cdnUrl,
            MessageType.image.value,
            width: w,
            height: h,
          );
        } else if (targetMsg.type == MessageType.audio &&
            targetMsg.localPath != null) {
          final file = XFile(targetMsg.localPath!, mimeType: 'audio/mp4');
          final cdnUrl = await _uploadService.uploadFile(
            file: file,
            module: UploadModule.chat,
            onProgress: (_) {},
          );
          return Api.sendMessage(
            msgId,
            conversationId,
            cdnUrl,
            MessageType.audio.value,
            duration: targetMsg.duration,
          );
        } else {
          // 文本直接发
          return Api.sendMessage(
            msgId,
            conversationId,
            targetMsg.content,
            MessageType.text.value,
          );
        }
      },
    );
  }

  // ===========================================================================
  //  ⚙️ [底层引擎] 统一处理管道
  // ===========================================================================

  /// 构造基础 UI 模型
  ChatUiModel _createBaseMessage({
    required String content,
    required MessageType type,
    String? localPath,
    Map<String, dynamic>? meta,
    int? duration,
  }) {
    return ChatUiModel(
      id: const Uuid().v4(),
      // 终身 ID
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localPath: localPath,
      meta: meta,
      duration: duration,
    );
  }

  /// 核心管道：负责存库、上屏、网络请求、状态流转
  Future<void> _handleOptimisticSend(
    ChatUiModel msg, {
    required Future<ChatMessage> Function() networkTask,
  }) async {
    try {
      // 1. 缓存 Session 图片路径 (防止闪烁)
      if (msg.localPath != null) {
        _sessionPathCache[msg.id] = msg.localPath!;
      }

      // 2. 乐观 UI 更新 (存库 + 更新列表)
      await LocalDatabaseService().saveMessage(msg);
      _updateConversationList(msg.content, msg.createdAt);

      // 3. 执行具体网络任务
      final serverMsg = await networkTask();

      // 4. 时间校准 (防止乱序)
      int finalTime = serverMsg.createdAt;
      if (finalTime < msg.createdAt) {
        finalTime = msg.createdAt;
      }

      // 5. 成功：更新状态 (Zero Jitter Update)
      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': finalTime,
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': serverMsg.content,
      });
    } catch (e) {
      debugPrint("❌ Send Failed [${msg.type}]: $e");

      // 6. 失败：统一标记为 Pending (等待 QueueManager 处理)
      // 注意：这里没有标 failed，所以不会出红叹号，而是进入“离线等待”状态
      await LocalDatabaseService().updateMessageStatus(
        msg.id,
        MessageStatus.pending,
      );
    }
  }

  // ===========================================================================
  //  🖼️ 图片预处理逻辑
  // ===========================================================================

  Future<
    ({
      String finalPath,
      XFile fileToUpload,
      int width,
      int height,
      Map<String, dynamic> meta,
    })
  >
  _processLocalImage(XFile file) async {
    String finalLocalPath;
    XFile fileToUpload;

    if (kIsWeb) {
      finalLocalPath = file.path;
      fileToUpload = file;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/chat_images');
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
      final fileName = p.basename(file.path);
      final savedPath = '${imagesDir.path}/$fileName';
      await File(savedPath).writeAsBytes(await file.readAsBytes());
      finalLocalPath = savedPath;
      fileToUpload = XFile(savedPath);
    }

    int w = 0;
    int h = 0;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      w = frameInfo.image.width;
      h = frameInfo.image.height;
    } catch (_) {}

    final Map<String, dynamic> meta = {};
    if (w > 0) {
      meta['w'] = w;
      meta['h'] = h;
    }

    return (
      finalPath: finalLocalPath,
      fileToUpload: fileToUpload,
      width: w,
      height: h,
      meta: meta,
    );
  }

  // ===========================================================================
  //  Socket & Events
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    if (!_mounted) return; // 僵尸防御

    try {
      final msg = SocketMessage.fromJson(data);
      if (msg.conversationId != conversationId) return;

      //  [去重] 双重广播回声消除
      if (_processedMsgIds.contains(msg.id)) return;

      _processedMsgIds.add(msg.id);
      if (_processedMsgIds.length > 20)
        _processedMsgIds.remove(_processedMsgIds.first);

      if (msg.sender?.id == _currentUserId) return;

      // 只要在前台，就触发已读
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _readReceiptSubject.add(null);
      }

      final apiMsg = ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
      );

      final uiMsg = ChatUiModel.fromApiModel(
        apiMsg,
        conversationId,
      ).copyWith(conversationId: conversationId);
      await LocalDatabaseService().saveMessage(uiMsg);
    } catch (e) {
      debugPrint(" Socket Parse Error: $e");
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (!_mounted) return;
    if (event.conversationId != conversationId ||
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

  // ===========================================================================
  //  Other Operations
  // ===========================================================================

  Future<void> recallMessage(String messageId) async {
    try {
      final response = await Api.messageRecallApi(
        MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId,
        ),
      );
      await LocalDatabaseService().doLocalRecall(messageId, response.tip);
      _updateConversationList(
        "[message recalled]",
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint("Recall failed: $e");
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
      debugPrint("Delete failed: $e");
    }
  }

  List<ChatUiModel> _applyReadStatusLocally(
    List<ChatUiModel> list,
    int waterLine,
  ) {
    return list.map((msg) {
      if (msg.isMe &&
          msg.status == MessageStatus.success &&
          msg.seqId != null) {
        if (msg.seqId! <= waterLine)
          return msg.copyWith(status: MessageStatus.read);
      }
      return msg;
    }).toList();
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

  List<ChatUiModel> _mapToUiModels(List<dynamic> dtoList) {
    return dtoList
        .map(
          (dto) =>
              ChatUiModel.fromApiModel(dto, conversationId, _currentUserId),
        )
        .toList();
  }
}
