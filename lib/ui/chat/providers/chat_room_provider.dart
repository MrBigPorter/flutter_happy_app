import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart'; // For XFile
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_app/utils/upload/upload_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';

import '../../../utils/upload/global_upload_service.dart';
import '../models/conversation.dart';
import 'conversation_provider.dart';
import 'package:path/path.dart' as p;

class ChatRoomNotifier extends StateNotifier<AsyncValue<List<ChatUiModel>>> {
  final SocketService _socketService;
  final GlobalUploadService _uploadService;
  final String conversationId;
  final String myUserId;
  final Ref _ref;

  StreamSubscription? _msgSub;
  StreamSubscription? _readStatusSub;
  StreamSubscription? _connectionSub;

  // Rx Pipeline
  final _readReceiptSubject = PublishSubject<void>();

  String? _nextCursor;
  bool _isLoadingMore = false;
  bool _hasPendingRead = false;
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;

  ChatRoomNotifier(
    this._socketService,
    this._uploadService,
    this.conversationId,
    this.myUserId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _setup();
    _setupReadReceiptDebounce();
  }

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((
      _,
    ) {
      if (!mounted) return;
      _executeMarkRead();
    });
  }

  void _executeMarkRead() {
    markAsRead();
    _hasPendingRead = false;
  }

  // ===========================================================================
  // 🚀 1. Basic Setup
  // ===========================================================================
  Future<void> _setup() async {
    _connectionSub = _socketService.onSyncNeeded.listen((_) {
      debugPrint("🔄 [ChatRoom] Socket reconnecting, re-joining room...");
      _joinRoom();
    });

    if (_socketService.isConnected) {
      _joinRoom();
    } else {
      final socket = _socketService.socket;
      if (socket != null && !socket.active) {
        socket.connect();
      }
    }

    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(
      _onReadStatusUpdate,
    );
  }

  void _joinRoom() {
    if (_socketService.isConnected) {
      _socketService.joinChatRoom(conversationId);
    }
  }

  // ===========================================================================
  // 🔄 2. Data Refresh & Loading
  // ===========================================================================
  Future<void> refresh() async {
    try {
      debugPrint("🚀 [ChatRoom] Refreshing data...");
      try {
        markAsRead();
      } catch (_) {}

      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: null,
      );

      final response = await Api.chatMessagesApi(request);

      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      final uiMessages = _mapToUiModels(response.list);
      final processedList = _applyReadStatusStrategy(uiMessages, _maxReadSeqId);

      if (mounted) {
        state = AsyncValue.data(processedList);
      }
    } catch (e, st) {
      debugPrint("❌ Refresh Error: $e");
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    _isLoadingMore = true;

    try {
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: _nextCursor,
      );
      final response = await Api.chatMessagesApi(request);
      _nextCursor = response.nextCursor;

      final moreMessages = _mapToUiModels(response.list);

      state.whenData((currentList) {
        final rawList = [...currentList, ...moreMessages];
        state = AsyncValue.data(
          _applyReadStatusStrategy(rawList, _maxReadSeqId),
        );
      });
    } catch (e) {
      debugPrint("❌ Load more failed: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  // ===========================================================================
  // 📩 3. Sending Logic (Text & Image)
  // ===========================================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final tempMsg = ChatUiModel(
      id: tempId,
      content: text,
      type: MessageType.text,
      // Ensure Enum is correct (usually 1)
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
    );

    _updateState((list) => [tempMsg, ...list]);
    _updateConversationList(text, now);

    await _executeSend(tempId, text, MessageType.text);
  }

  // 📸 Entry point for sending images
  Future<void> sendImage(XFile file) async {
    // A. 搬家：从 tmp 搬到 Documents
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/chat_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final fileName = p.basename(file.path);
    final savedPath = '${imagesDir.path}/$fileName';

    // 复制文件
    final savedFile = await File(file.path).copy(savedPath);

    debugPrint("✅ [搬家成功] 旧路径: ${file.path}");
    debugPrint("✅ [搬家成功] 新路径: ${savedFile.path}");

    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final tempMsg = ChatUiModel(
      id: tempId,
      content: "[Image]",
      type: MessageType.image,
      // Ensure Enum is correct (usually 2)
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      localPath: savedFile.path, // Store local path for optimistic UI
    );

    _updateState((list) => [tempMsg, ...list]);
    _updateConversationList("[Image]", now);

    _executeImageSend(tempId, XFile(savedFile.path));
  }

  //  Internal: Uploads image then sends message
  Future<void> _executeImageSend(String tempId, XFile file) async {
    try {
      // 1. Upload to S3/R2 via UploadService
      // Note: We expect uploadFile to return the CDN URL (finalResultUrl)
      final cdnUrl = await _uploadService.uploadFile(
        file: file,
        module: UploadModule.chat,
        onProgress: (_) {}, // Could add upload progress logic here
      );


      // 2. Send the message protocol with the CDN URL
      // Pass MessageType.image so backend knows it's a picture
      await _executeSend(tempId, cdnUrl, MessageType.image,localPath: file.path );
    } catch (e) {
      debugPrint("❌ Send Image Failed: $e");
      _updateState(
        (list) => list
            .map(
              (m) =>
                  m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m,
            )
            .toList(),
      );
    }
  }

  // Generic underlying send method
  Future<void> _executeSend(
    String tempId,
    String content,
    MessageType type,
  {
    String? localPath,
  }
  ) async {
    try {
      // 1. Call API
      final sentMsg = await Api.sendMessage(
        conversationId,
        content,
        type.value, // Pass the int value (e.g. 1 for Text, 2 for Image)
        tempId,
      );

      // 2. Update local state with server response
      state.whenData((list) {
        // 🔍 步骤 A: 先在当前列表里找这个 tempId
        final tempIndex = list.indexWhere((m) => m.id == tempId);

        // 🛠 构造逻辑优化：
        // 优先用传进来的 localPath，如果没传，再尝试去旧消息里找
        String? finalLocalPath = localPath;
        

        if (finalLocalPath == null && tempIndex != -1) {
          finalLocalPath = list[tempIndex].localPath;
        }


        // 构造新的消息对象
        final updatedMsg = ChatUiModel(
          id: sentMsg.id,
          seqId: sentMsg.seqId,
          content: sentMsg.content,
          type: MessageType.fromValue(sentMsg.type),
          isMe: true,
          status: MessageStatus.success,
          createdAt: sentMsg.createdAt,
          localPath: finalLocalPath,
        );

        List<ChatUiModel> rawList;

        // 🔄 策略分叉：存在的更新，不存在的插入
        final index = list.indexWhere((m) => m.id == tempId);
        

        if(tempIndex != -1){
          //  情况 1: 找到了临时消息 -> 原地替换
          // 使用 List.of 创建副本，防止修改不可变列表报错
          rawList = List.of(list);
          rawList[tempIndex] = updatedMsg;
        }else{
          //  情况 2: 没找到 (极少见) -> 只有这种时候才插入新的
          // 比如：你刚发完消息瞬间切换了页面又切回来，且触发了刷新，导致临时消息丢了
          // 防止重复：检查一下是不是 id 已经存在了 (防止 Socket 已经推过来了)
          final isAlreadyExist = list.any((m) => m.id == sentMsg.id);
          if (isAlreadyExist) {
            // 如果已经存在真实ID的消息，直接返回，啥也不干
            return;
          }
          rawList = [updatedMsg, ...list];
        }
        // 3. 应用已读状态策略
        state = AsyncValue.data(
          _applyReadStatusStrategy(rawList, _maxReadSeqId),
        );
      });
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
      _updateState(
        (list) => list
            .map(
              (m) =>
                  m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m,
            )
            .toList(),
      );
    }
  }

  // 🔄 Resend Logic
  Future<void> resendMessage(String tempId) async {
    state.whenData((list) async {
      final targetMsg = list.firstWhere(
        (e) => e.id == tempId,
        orElse: () => list.first,
      );
      if (targetMsg.id != tempId) return;

      // Optimistically set to sending
      _updateState(
        (current) => current
            .map(
              (m) => m.id == tempId
                  ? m.copyWith(status: MessageStatus.sending)
                  : m,
            )
            .toList(),
      );

      _updateConversationList(
        targetMsg.content,
        DateTime.now().millisecondsSinceEpoch,
      );

      //  Decide strategy based on type
      if (targetMsg.type == MessageType.image && targetMsg.localPath != null) {
        // If it's an image and has a local path, re-run the upload flow
        // Wrap localPath in XFile
        await _executeImageSend(tempId, XFile(targetMsg.localPath!));
      } else {
        // Otherwise, just re-send the protocol (Text or already uploaded image URL)
        await _executeSend(tempId, targetMsg.content, targetMsg.type);
      }
    });
  }

  // ===========================================================================
  // 📡 4. Receiving & Events
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    try {
      final msg = SocketMessage.fromJson(data);
      if (msg.conversationId != conversationId) return;

      final currentUserId = _ref.read(luckyProvider).userInfo?.id ?? "";

      //  Parse message type from int to Enum
      final msgType = MessageType.fromValue(msg.type);

      // A. My own message echo
      if (msg.senderId == currentUserId) {
        if (msg.tempId != null) {
          state.whenData((list) {
            final rawList = list.map((m) {
              if (m.id == msg.tempId) {
                return m.copyWith(
                  id: msg.id,
                  seqId: msg.seqId,
                  status: MessageStatus.success,
                  createdAt: msg.createdAt,
                  content: msg.content,
                  type: msgType,
                );
              }
              return m;
            }).toList();
            state = AsyncValue.data(
              _applyReadStatusStrategy(rawList, _maxReadSeqId),
            );
          });
        }
        return;
      }

      // B. Partner's message
      _hasPendingRead = true;
      _readReceiptSubject.add(null);

      final newUiMsg = ChatUiModel(
        id: msg.id,
        seqId: msg.seqId,
        content: msg.content,
        type: msgType,
        // Use parsed type
        isMe: false,
        status: MessageStatus.success,
        createdAt: msg.createdAt,
        senderName: msg.sender?.nickname,
        senderAvatar: msg.sender?.avatar,
      );

      state.whenData((currentList) {
        if (currentList.any((m) => m.id == newUiMsg.id)) return;
        final rawList = [newUiMsg, ...currentList];
        state = AsyncValue.data(
          _applyReadStatusStrategy(rawList, _maxReadSeqId),
        );
      });
    } catch (e) {
      debugPrint("❌ Socket Parse Error: $e");
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) {
    if (!mounted) return;
    if (event.conversationId != conversationId) return;
    if (event.readerId == myUserId) return;

    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
    }
    state.whenData((list) {
      state = AsyncValue.data(_applyReadStatusStrategy(list, _maxReadSeqId));
    });
  }

  // ===========================================================================
  // 🧠 5. Strategies & Helpers
  // ===========================================================================

  List<ChatUiModel> _applyReadStatusStrategy(
    List<ChatUiModel> currentList,
    int waterLine,
  ) {
    bool hasFoundLatestRead = false;
    return currentList.map((msg) {
      if (!msg.isMe ||
          msg.status == MessageStatus.sending ||
          msg.status == MessageStatus.failed ||
          msg.seqId == null) {
        return msg;
      }
      if (msg.seqId! <= waterLine) {
        if (!hasFoundLatestRead) {
          hasFoundLatestRead = true;
          return msg.copyWith(status: MessageStatus.read);
        } else {
          return msg.copyWith(status: MessageStatus.success);
        }
      }
      return msg.copyWith(status: MessageStatus.success);
    }).toList();
  }

  void markAsRead() {
    if (!mounted) return;
    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}

    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    ).catchError((e) => debugPrint("❌ markRead API: $e"));
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

  void _updateState(List<ChatUiModel> Function(List<ChatUiModel>) action) {
    state.whenData((list) => state = AsyncValue.data(action(list)));
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> dtoList) {
    return dtoList.map((dto) {
      return ChatUiModel.fromApiModel(dto, myUserId);
    }).toList();
  }

  @override
  void dispose() {
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();

    if (_hasPendingRead) {
      Api.messageMarkAsReadApi(
        MessageMarkReadRequest(conversationId: conversationId),
      );
    }
    _readReceiptSubject.close();
    super.dispose();
  }
}

// Provider Definition
final chatRoomProvider = StateNotifierProvider.family
    .autoDispose<ChatRoomNotifier, AsyncValue<List<ChatUiModel>>, String>((
      ref,
      conversationId,
    ) {
      ref.cacheFor(const Duration(minutes: 5));

      final socketService = ref.read(socketServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);
      final myUserId = ref.read(
        luckyProvider.select((state) => state.userInfo?.id),
      );

      return ChatRoomNotifier(
        socketService,
        uploadService,
        conversationId,
        myUserId ?? '',
        ref,
      );
    });
