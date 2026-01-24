import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui; //  必须引入这个用于获取图片尺寸
import 'package:camera/camera.dart'; // For XFile
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
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
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

// ===========================================================================
//  1. Read: Data Stream Provider
// ===========================================================================
final chatStreamProvider = StreamProvider.family.autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
  return LocalDatabaseService().watchMessages(conversationId);
});

final chatLoadingMoreProvider = StateProvider.family<bool, String>((ref, id) => false);

// ===========================================================================
//  2. Write: Business Logic Controller
// ===========================================================================
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>(
      (ref, conversationId) {
    ref.cacheFor(const Duration(minutes: 5));

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
  },
);

class ChatRoomController {
  final SocketService _socketService;
  final GlobalUploadService _uploadService;
  final String conversationId;
  final Ref _ref;

  StreamSubscription? _msgSub;
  StreamSubscription? _readStatusSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _recallSub;

  final _readReceiptSubject = PublishSubject<void>();

  String? _nextCursor;
  bool _isLoadingMore = false;
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;
  String get _currentUserId => _ref.read(luckyProvider).userInfo?.id ?? "";

  // 静态缓存：防止图片重绘闪烁
  static final Map<String, String> _sessionPathCache = {};
  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatRoomController(
      this._socketService,
      this._uploadService,
      this.conversationId,
      this._ref,
      ) {
    _setup();
    _setupReadReceiptDebounce();
  }

  // ===========================================================================
  //  Setup & Dispose
  // ===========================================================================

  void dispose() {
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();
    _recallSub?.cancel();
    _readReceiptSubject.close();
  }

  Future<void> _setup() async {
    _connectionSub = _socketService.onSyncNeeded.listen((_) => _joinRoom());
    if (_socketService.isConnected) _joinRoom();

    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(_onReadStatusUpdate);
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  void _joinRoom() {
    if (_socketService.isConnected) {
      _socketService.joinChatRoom(conversationId);
    }
  }

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((_) {
      _executeMarkRead();
    });
  }

  void _executeMarkRead() {
    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}
    Api.messageMarkAsReadApi(MessageMarkReadRequest(conversationId: conversationId));
  }

  // ===========================================================================
  //  Data Refresh
  // ===========================================================================

  Future<void> refresh() async {
    try {
      _executeMarkRead();
      final request = MessageHistoryRequest(conversationId: conversationId, pageSize: 20, cursor: null);
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
      final request = MessageHistoryRequest(conversationId: conversationId, pageSize: 20, cursor: _nextCursor);
      final response = await Api.chatMessagesApi(request);
      _nextCursor = response.nextCursor;

      final moreMessages = _mapToUiModels(response.list);
      final processedList = _applyReadStatusLocally(moreMessages, _maxReadSeqId);

      await LocalDatabaseService().saveMessages(processedList);
    } catch (e) {
      debugPrint("Load more failed: $e");
    } finally {
      _isLoadingMore = false;
      _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = false;
    }
  }

  // ===========================================================================
  //   核心发送逻辑 (客户端生成 ID)
  // ===========================================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final msgId = const Uuid().v4(); // 终身 ID
    final now = DateTime.now().millisecondsSinceEpoch;

    final newMsg = ChatUiModel(
      id: msgId,
      content: text,
      type: MessageType.text,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      conversationId: conversationId,
    );

    // 存库 -> UI 立即上屏
    await LocalDatabaseService().saveMessage(newMsg);
    _updateConversationList(text, now);

    // 发送
    await _executeSend(
      msgId,
      text,
      MessageType.text,
      originalCreatedAt: now,
    );
  }

  Future<void> sendImage(XFile file) async {
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

    final msgId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    //  1. 获取图片宽高 (修复后的逻辑)
    int w = 0;
    int h = 0;
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes); //  正确 API
      final frameInfo = await codec.getNextFrame();
      w = frameInfo.image.width;
      h = frameInfo.image.height;
    } catch (e) {
      debugPrint("Get image size failed: $e");
    }

    //  2. 构造 Meta 存本地
    final Map<String, dynamic> meta = {};
    if (w > 0 && h > 0) {
      meta['w'] = w;
      meta['h'] = h;
    }

    final newMsg = ChatUiModel(
      id: msgId,
      content: "[Image]",
      type: MessageType.image,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      localPath: finalLocalPath,
      conversationId: conversationId,
      meta: meta, //  存入宽高
    );

    await LocalDatabaseService().saveMessage(newMsg);
    _updateConversationList("[Image]", now);

    _executeImageSend(msgId, fileToUpload, now, w, h);
  }

  Future<void> sendVoiceMessage(String path, int duration) async {
    final msgId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final newMsg = ChatUiModel(
      id: msgId,
      content: "[Voice]",
      type: MessageType.audio,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      localPath: path,
      duration: duration,
      conversationId: conversationId,
    );

    await LocalDatabaseService().saveMessage(newMsg);
    _updateConversationList("[Voice]", now);

    _executeVoiceSend(msgId, path, duration);
  }

  // ===========================================================================
  //  执行层 (Upload & API)
  // ===========================================================================

  Future<void> _executeImageSend(String id, XFile file, int createdTime, int w, int h) async {
    try {
      final cdnUrl = await _uploadService.uploadFile(
        file: file,
        module: UploadModule.chat,
        onProgress: (_) {},
      );

      await _executeSend(
        id,
        cdnUrl,
        MessageType.image,
        localPath: file.path,
        originalCreatedAt: createdTime,
        width: w,  //  传给后端
        height: h, //  传给后端
      );
    } catch (e) {
      debugPrint(" Send Image Failed: $e");
      _updateMessageStatus(id, MessageStatus.failed);
    }
  }

  Future<void> _executeVoiceSend(String id, String localPath, int duration) async {
    try {
      final fileToUpload = XFile(
        localPath,
        name: '${const Uuid().v4()}.m4a',
        mimeType: 'audio/mp4',
      );

      final cdnUrl = await _uploadService.uploadFile(
        file: fileToUpload,
        module: UploadModule.chat,
        onProgress: (_) {},
      );

      final sentMsg = await Api.sendMessage(
        id, //  传 ID
        conversationId,
        cdnUrl,
        MessageType.audio.value,
        duration: duration,
      );

      // 仅更新状态，不换 ID
      await LocalDatabaseService().updateMessage(id, {
        'status': MessageStatus.success.name,
        'seqId': sentMsg.seqId,
        'createdAt': sentMsg.createdAt,
        'content': cdnUrl,
      });

    } catch (e) {
      debugPrint(" Voice Send Failed: $e");
      _updateMessageStatus(id, MessageStatus.failed);
    }
  }

  Future<void> _executeSend(
      String id,
      String content,
      MessageType type, {
        String? localPath,
        int? originalCreatedAt,
        int? width,
        int? height,
        int? duration,
      }) async {
    try {
      if (localPath != null) {
        _sessionPathCache[id] = localPath;
      }

      final sentMsg = await Api.sendMessage(
        id, // 传 ID 给后端
        conversationId,
        content,
        type.value,
        duration: duration,
        width: width,
        height: height,
      );

      // 时间校准
      int finalTime = sentMsg.createdAt;
      if (originalCreatedAt != null && finalTime < originalCreatedAt) {
        finalTime = originalCreatedAt;
      }

      //  UPDATE 操作 (零抖动)
      await LocalDatabaseService().updateMessage(id, {
        'status': MessageStatus.success.name,
        'seqId': sentMsg.seqId,
        'createdAt': finalTime,
        if (sentMsg.meta != null) 'meta': sentMsg.meta,
      });

    } catch (e) {
      debugPrint(' sendMessage error: $e');
      _updateMessageStatus(id, MessageStatus.failed);
    }
  }

  Future<void> _updateMessageStatus(String id, MessageStatus status) async {
    await LocalDatabaseService().updateMessageStatus(id, status);
  }

  // ===========================================================================
  //  Resend Logic (Fixed)
  // ===========================================================================
  Future<void> resendMessage(String msgId) async {
    final targetMsg = await LocalDatabaseService().getMessageById(msgId);
    if (targetMsg == null) {
      debugPrint(" Resend Failed: Message not found $msgId");
      return;
    }

    final newTime = DateTime.now().millisecondsSinceEpoch;
    final sendingMsg = targetMsg.copyWith(
      status: MessageStatus.sending,
      createdAt: newTime,
    );
    await LocalDatabaseService().saveMessage(sendingMsg);
    _updateConversationList(targetMsg.content, newTime);

    if (targetMsg.type == MessageType.image && targetMsg.localPath != null) {
      debugPrint(" Resend Image: ${targetMsg.localPath}");

      //  提取之前存的宽高
      int w = 0;
      int h = 0;
      if (targetMsg.meta != null) {
        w = (targetMsg.meta!['w'] as num?)?.toInt() ?? 0;
        h = (targetMsg.meta!['h'] as num?)?.toInt() ?? 0;
      }

      //  传递所有必要参数
      await _executeImageSend(
          msgId,
          XFile(targetMsg.localPath!),
          newTime,
          w,
          h
      );
    } else {
      debugPrint(" Resend Text: ${targetMsg.content}");
      await _executeSend(
        msgId,
        targetMsg.content,
        targetMsg.type,
        originalCreatedAt: newTime,
      );
    }
  }

  // ===========================================================================
  //  Other Features
  // ===========================================================================

  Future<void> recallMessage(String messageId) async {
    try {
      final response = await Api.messageRecallApi(MessageRecallRequest(conversationId: conversationId, messageId: messageId));
      await LocalDatabaseService().doLocalRecall(messageId, response.tip);
      _updateConversationList("[message recalled]", DateTime.now().millisecondsSinceEpoch);
    } catch (e) { debugPrint("Recall failed: $e"); }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await LocalDatabaseService().deleteMessage(messageId);
      await Api.messageDeleteApi(MessageDeleteRequest(messageId: messageId, conversationId: conversationId));
    } catch (e) { debugPrint("Delete failed: $e"); }
  }

  void _onSocketMessage(Map<String, dynamic> data) async {
    try {
      final msg = SocketMessage.fromJson(data);
      if (msg.conversationId != conversationId) return;

      //  回声消除：如果是我发的，直接忽略
      if (msg.sender?.id == _currentUserId) return;

      final apiMsg = ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
      );

      final uiMsg = ChatUiModel.fromApiModel(apiMsg, conversationId).copyWith(conversationId: conversationId);
      await LocalDatabaseService().saveMessage(uiMsg);
      if (!uiMsg.isMe) _readReceiptSubject.add(null);
    } catch (e) { debugPrint(" Socket Parse Error: $e"); }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (event.conversationId != conversationId || event.readerId == _currentUserId) return;
    if (event.lastReadSeqId > _maxReadSeqId) _maxReadSeqId = event.lastReadSeqId;
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf ? "You unsent a message" : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateConversationList(tip, DateTime.now().millisecondsSinceEpoch);
  }

  List<ChatUiModel> _applyReadStatusLocally(List<ChatUiModel> list, int waterLine) {
    return list.map((msg) {
      if (msg.isMe && msg.status == MessageStatus.success && msg.seqId != null) {
        if (msg.seqId! <= waterLine) return msg.copyWith(status: MessageStatus.read);
      }
      return msg;
    }).toList();
  }

  void _updateConversationList(String text, int time) {
    try {
      _ref.read(conversationListProvider.notifier).updateLocalItem(
        conversationId: conversationId,
        lastMsgContent: text,
        lastMsgTime: time,
      );
    } catch (_) {}
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> dtoList) {
    return dtoList.map((dto) => ChatUiModel.fromApiModel(dto, conversationId, _currentUserId)).toList();
  }
}