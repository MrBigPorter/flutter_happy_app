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
import '../database/local_database_service.dart';
import '../models/conversation.dart';
import 'conversation_provider.dart';
import 'package:path/path.dart' as p;

// ===========================================================================
//  1. 读：数据流提供者 (UI 监听这个)
// ===========================================================================
final chatStreamProvider = StreamProvider.family.autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
  // 只要数据库变动，UI 自动刷新
  return LocalDatabaseService().watchMessages(conversationId);
});

// 专门负责分页加载状态的提供者
final chatLoadingMoreProvider = StateProvider.family<bool, String>((ref, id) => false);

// ===========================================================================
//  2. 写：业务控制器 (UI 调用这个)
// ===========================================================================
final chatControllerProvider = Provider.family.autoDispose<ChatRoomController, String>(
      (ref, conversationId) {

    // 保持缓存，避免频繁销毁
    ref.cacheFor(const Duration(minutes: 5));

    final socketService = ref.read(socketServiceProvider);
    final uploadService = ref.read(uploadServiceProvider);

    final controller = ChatRoomController(
      socketService,
      uploadService,
      conversationId,
      ref,
    );

    // 关键：当 Provider 销毁时，自动释放资源
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

  // Rx Pipeline (用于已读回执去抖动)
  final _readReceiptSubject = PublishSubject<void>();

  String? _nextCursor;
  bool _isLoadingMore = false;

  // 记录最大的已读 ID，用于处理已读状态
  int _maxReadSeqId = 0;

  bool get hasMore => _nextCursor != null;

  String get _currentUserId => _ref.read(luckyProvider).userInfo?.id ?? "";

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
    _connectionSub = _socketService.onSyncNeeded.listen((_) {
      debugPrint(" [ChatRoom] Socket reconnecting, re-joining room...");
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

    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    ).catchError((e) => debugPrint(" markRead API: $e"));
  }

  // ===========================================================================
  //  Data Refresh & Loading
  // ===========================================================================

  Future<void> refresh() async {
    try {
      _executeMarkRead();
      
      print("🔄 [ChatRoomController] Refreshing messages for conversation $conversationId");

      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: null,
      );

      final response = await Api.chatMessagesApi(request);

      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;

      // 转换模型
      final uiMessages = _mapToUiModels(response.list);

      //  存入数据库 (Sembast 会自动去重/更新)
      // 注意：这里最好先把状态处理一下再存
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

      //  存入数据库 -> UI 自动显示更多
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
  //  Sending Logic
  // ===========================================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. 构建临时消息
    final tempMsg = ChatUiModel(
      id: tempId,
      content: text,
      type: MessageType.text,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      conversationId: conversationId,
    );

    //  2. 存库 -> UI 立即上屏
    await LocalDatabaseService().saveMessage(tempMsg);
    _updateConversationList(text, now);

    // 3. 调接口
    await _executeSend(tempId, text, MessageType.text);
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
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final fileName = p.basename(file.path);
      final savedPath = '${imagesDir.path}/$fileName';
      final saveFile = File(savedPath);
      final bytes = await file.readAsBytes();
      await saveFile.writeAsBytes(bytes);
      finalLocalPath = saveFile.path;
      fileToUpload = XFile(savedPath);
    }

    final tempId = const Uuid().v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final tempMsg = ChatUiModel(
      id: tempId,
      content: "[Image]",
      type: MessageType.image,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: now,
      localPath: finalLocalPath, // 本地路径用于回显
      conversationId: conversationId,
    );

    // 存库
    await LocalDatabaseService().saveMessage(tempMsg);
    _updateConversationList("[Image]", now);

    _executeImageSend(tempId, fileToUpload);
  }

  Future<void> _executeImageSend(String tempId, XFile file) async {
    try {
      final cdnUrl = await _uploadService.uploadFile(
        file: file,
        module: UploadModule.chat,
        onProgress: (_) {},
      );

      // 上传成功后发送消息，带上本地路径防止图片闪烁
      await _executeSend(
        tempId,
        cdnUrl,
        MessageType.image,
        localPath: file.path,
      );
    } catch (e) {
      debugPrint(" Send Image Failed: $e");
      //  失败：更新数据库状态
      _updateMessageStatus(tempId, MessageStatus.failed);
    }
  }

  Future<void> _executeSend(
      String tempId,
      String content,
      MessageType type, {
        String? localPath,
      }) async {
    try {
      final sentMsg = await Api.sendMessage(
        conversationId,
        content,
        type.value,
        tempId,
      );


      // 2. 存入正式消息 (用 Real ID)
      final successMsg = ChatUiModel.fromApiModel(sentMsg).copyWith(
        localPath: localPath, // 保持本地路径
        conversationId: conversationId,
        status: MessageStatus.success,
      );


      //  [新代码] 使用事务原子替换
      await LocalDatabaseService().replaceMessage(tempId, successMsg);

    } catch (e) {
      debugPrint(' sendMessage error: $e');
      // ❌ 失败
      _updateMessageStatus(tempId, MessageStatus.failed);
    }
  }

  // 辅助方法：只更新状态
  Future<void> _updateMessageStatus(String id, MessageStatus status) async {
    await LocalDatabaseService().updateMessageStatus(id, status);
  }

  // ===========================================================================
  //  Resend / Recall / Delete
  // ===========================================================================

  // ===========================================================================
  //  Resend Logic (完整补全版)
  // ===========================================================================
  Future<void> resendMessage(String tempId) async {
    // 1.  从数据库里把这条消息查出来
    final targetMsg = await LocalDatabaseService().getMessageById(tempId);

    if (targetMsg == null) {
      debugPrint(" 重发失败：数据库里找不到这条消息 $tempId");
      return;
    }

    // 2.  乐观更新：先把它改成 "Sending" 状态，UI 会立刻转圈圈
    final sendingMsg = targetMsg.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch, // 更新时间让它浮到最下面？(可选)
    );
    await LocalDatabaseService().saveMessage(sendingMsg);

    // 3.  更新会话列表预览
    _updateConversationList(
      targetMsg.content,
      DateTime.now().millisecondsSinceEpoch,
    );

    // 4.  根据类型重新触发发送
    if (targetMsg.type == MessageType.image && targetMsg.localPath != null) {
      // 图片消息：如果有本地路径，重新上传 + 发送
      // 注意：这里要把 String path 转回 XFile
      debugPrint(" 重发图片: ${targetMsg.localPath}");
      await _executeImageSend(tempId, XFile(targetMsg.localPath!));
    } else {
      // 文本消息：直接重发
      debugPrint(" 重发文本: ${targetMsg.content}");
      await _executeSend(tempId, targetMsg.content, targetMsg.type);
    }
  }

  Future<void> recallMessage(String messageId) async {
    try {
      final response = await Api.messageRecallApi(
        MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId,
        ),
      );

      //  撤回成功：直接更新数据库
      // 严谨写法：LocalDatabaseService 应该提供 updateMessage(id, changes)

      // 临时方案：我们知道撤回变文本，直接用 ID 覆盖
      // 但这样会丢失原有的 createdAt 等信息，所以最好是 fetchById
      // 这里作为演示，仅打印，你需要去 LocalDatabaseService 加 update 方法
      debugPrint("需实现 DB update: 把 $messageId 内容改为 ${response.tip}");
      await LocalDatabaseService().doLocalRecall(messageId, response.tip);

      _updateConversationList("[message recalled]", DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint("撤回失败: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      //  立即从库里删掉 -> UI 消失
      await LocalDatabaseService().deleteMessage(messageId);

      await Api.messageDeleteApi(
        MessageDeleteRequest(
          messageId: messageId,
          conversationId: conversationId,
        ),
      );

      // TODO: 更新会话列表预览 (取库里最新一条)
    } catch (e) {
      debugPrint("删除消息失败: $e");
    }
  }

  // ===========================================================================
  //  Socket Events
  // ===========================================================================

  void _onSocketMessage(Map<String, dynamic> data) async {
    try {
      final msg = SocketMessage.fromJson(data);
      if (msg.conversationId != conversationId) return;

      final senderId = msg.sender?.id ?? "";
      final bool isMe = senderId.isNotEmpty && (senderId == _currentUserId);

      final uiMsg = ChatUiModel.fromApiModel(ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: isMe,
      )).copyWith(
        conversationId: conversationId,
        // 这里可以尝试保留本地已有的 localPath (如果是自己发的)
      );

      //  存库
      // 如果是自己的消息回执，Sembast 会根据 ID 覆盖，从而把 status 变为 success
      await LocalDatabaseService().saveMessage(uiMsg);

      // 5. 如果是对方发的，触发已读回执逻辑
      if (!uiMsg.isMe) {
        _readReceiptSubject.add(null);
      }
    } catch (e) {
      debugPrint(" Socket Parse Error: $e");
    }
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (event.conversationId != conversationId) return;
    if (event.readerId == _currentUserId) return;

    if (event.lastReadSeqId > _maxReadSeqId) {
      _maxReadSeqId = event.lastReadSeqId;
      //  触发数据库批量更新
      // 这里需要一个 LocalDatabaseService 方法：
      // updateReadStatus(conversationId, maxSeqId)
      // 暂时省略实现细节
    }
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf ? "You unsent a message" : "This message was unsent";

    //  存库覆盖
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
     _updateConversationList(tip, DateTime.now().millisecondsSinceEpoch);
  }

  // ===========================================================================
  //  Helpers
  // ===========================================================================

  // 本地处理已读状态 (在存入数据库之前)
  List<ChatUiModel> _applyReadStatusLocally(List<ChatUiModel> list, int waterLine) {
    return list.map((msg) {
      if (msg.isMe && msg.status == MessageStatus.success && msg.seqId != null) {
        if (msg.seqId! <= waterLine) {
          return msg.copyWith(status: MessageStatus.read);
        }
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
    return dtoList.map((dto) {
      final uiMsg = ChatUiModel.fromApiModel(dto,_currentUserId);
      return uiMsg.copyWith(
        conversationId: conversationId,
      );
    }).toList();
  }
}