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
// 📸 发送图片入口
  Future<void> sendImage(XFile file) async {
    String finalLocalPath;
    XFile fileToUpload;

    // 1. 分平台处理
    if (kIsWeb) {
      //  Web 端逻辑：
      // 浏览器里不能搬家，而且 image_picker 返回的 path 已经是可用的 blob 链接了
      // 直接用就行，不用折腾
      finalLocalPath = file.path;
      fileToUpload = file;
    } else {
      //  手机端逻辑 (iOS/Android)：
      // 1. 准备目录
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/chat_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = p.basename(file.path);
      final savedPath = '${imagesDir.path}/$fileName';
      final saveFile = File(savedPath);

      //  核心修复：改用 readAsBytes + writeAsBytes (flush: true)
      // 1. 先把 tmp 里的数据读进内存 (避开文件锁)
      final bytes = await file.readAsBytes();
      // 2. 写入 Documents，并强制 flush (确保写入磁盘后再继续)
      await saveFile.writeAsBytes(bytes);

      // 3. 双重检查：如果写入后文件还是不存在，抛出异常
      if(!await saveFile.exists()){
        throw Exception("Failed to save image file to $savedPath");
      }

      finalLocalPath = saveFile.path;
      fileToUpload = XFile(savedPath);
    }

    // 2. 正常构建消息
    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final tempMsg = ChatUiModel(
      id: tempId,
      content: "[Image]",
      type: MessageType.image,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      //  这里把刚才判定好的路径传进去 (Web是Blob, 手机是文件路径)
      localPath: finalLocalPath,
    );

    _updateState((list) => [tempMsg, ...list]);
    _updateConversationList("[Image]", now);

    // 3. 执行上传
    // 注意：Web 端上传时，你的 UploadService 内部不能用 File(path)，
    // 必须直接使用 XFile 的 bytes 或者 stream，否则也会报错。
    _executeImageSend(tempId, fileToUpload);
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
      MessageType type, {
        String? localPath,
      }) async {
    try {
      // 1. Call API
      final sentMsg = await Api.sendMessage(
        conversationId,
        content,
        type.value,
        tempId,
      );

      debugPrint(" [HTTP] 发送成功: RealID=${sentMsg.id}, TempID=$tempId");

      // 2. Update local state
      state.whenData((list) {
        // 查找目标：既要找 tempId，也要找 realId (防止 Socket 已经先回来把 ID 改了)
        final tempIndex = list.indexWhere((m) => m.id == tempId);
        final realIndex = list.indexWhere((m) => m.id == sentMsg.id);

        // 只要找到其中一个，就算找到了
        final targetIndex = tempIndex != -1 ? tempIndex : realIndex;

        //  确定 localPath
        // 优先用传进来的参数，如果没有，去旧消息里捞
        String? finalLocalPath = localPath;
        if (finalLocalPath == null && targetIndex != -1) {
          finalLocalPath = list[targetIndex].localPath;
        }

        // 构造新消息
        final updatedMsg = ChatUiModel(
          id: sentMsg.id,
          seqId: sentMsg.seqId,
          content: sentMsg.content,
          type: MessageType.fromValue(sentMsg.type),
          isMe: true,
          status: MessageStatus.success,
          createdAt: sentMsg.createdAt,
          //  确保带上 localPath
          localPath: finalLocalPath,
        );

        List<ChatUiModel> rawList;

        if (targetIndex != -1) {
          //  情况 1: 找到了，原地更新
          rawList = List.of(list);
          rawList[targetIndex] = updatedMsg;
        } else {
          //  情况 2: 没找到 (可能列表刷新了?)，做防重后插入
          if (list.any((m) => m.id == sentMsg.id)) return;
          rawList = [updatedMsg, ...list];
        }

        state = AsyncValue.data(
          _applyReadStatusStrategy(rawList, _maxReadSeqId),
        );
      });
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
      _updateState(
            (list) => list
            .map((m) => m.id == tempId ? m.copyWith(status: MessageStatus.failed) : m)
            .toList(),
      );
    }
  }

  //  Resend Logic
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
      final msgType = MessageType.fromValue(msg.type);

      // A. 重点修复：处理我自己的消息回执
      if (msg.senderId == currentUserId) {
        // 只要 tempId 或 id 有一个能匹配上，就更新它
        state.whenData((list) {
          final rawList = list.map((m) {
            //  核心逻辑：同时检查 tempId 和 realId
            // 防止 HTTP 接口已经把 ID 改成了 realId，导致这里匹配失败
            final isMatch = (msg.tempId != null && m.id == msg.tempId) || (m.id == msg.id);

            if (isMatch) {
              return m.copyWith(
                id: msg.id, // 确保 ID 是最新的
                seqId: msg.seqId,
                status: MessageStatus.success,
                createdAt: msg.createdAt,
                content: msg.content,
                type: msgType,

                // 🔥🔥🔥 死保本地路径！🔥🔥🔥
                // 只有当 m.localPath 有值时才保留，否则看 socket 消息里有没有(通常没有)
                localPath: m.localPath,
              );
            }
            return m;
          }).toList();

          state = AsyncValue.data(
            _applyReadStatusStrategy(rawList, _maxReadSeqId),
          );
        });
        return;
      }

      // B. 对方的消息 (保持不变)
      _hasPendingRead = true;
      _readReceiptSubject.add(null);

      final newUiMsg = ChatUiModel(
        id: msg.id,
        seqId: msg.seqId,
        content: msg.content,
        type: msgType,
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
    final currentUserId = _ref.read(luckyProvider).userInfo?.id ?? "";
    debugPrint("🔄 [Fix] 实时获取 UserID: $currentUserId");
    return dtoList.map((dto) {
      return ChatUiModel.fromApiModel(dto, currentUserId);
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
