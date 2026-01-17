import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/cache/cache_for_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';

import '../models/conversation.dart';

class ChatRoomNotifier extends StateNotifier<AsyncValue<List<ChatUiModel>>> {
  final SocketService _socketService;
  final String conversationId;
  final String myUserId;
  StreamSubscription? _msgSub;

  //新增部分：监听连接状态
  StreamSubscription? _connectionSub;

  //  1. 新增：分页游标和加载状态标记
  String? _nextCursor;
  bool _isLoadingMore = false;

  bool get hasMore => _nextCursor != null;

  ChatRoomNotifier(
      this._socketService,
      this.conversationId,
      this.myUserId,
      ) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {

      // ==================================================
      // 核心修复：解决“进房太早，连接未好”以及“断线重连”的问题
      // ==================================================
      // A. 订阅“连接/重连”信号
      // 这里的 onSyncNeeded 是我们在 SocketService 里新加的流
      // 无论是第一次连接成功，还是断线重连成功，这里都会触发
      
      _connectionSub = _socketService.onSyncNeeded.listen((_){
        debugPrint("🔄 [ChatRoom] 监听到 Socket 连接/重连，正在加入房间...");
        _joinRoom();
      });

      // B. 立即检查当前状态 (双重保险)
      // 如果进页面时 socket 已经是好的，直接进房，不用等回调
      // Step A: Socket 进房
      if (_socketService.isConnected) {
        _joinRoom();
      }else{
        debugPrint("⏳ [ChatRoom] Socket 未连接，等待连接...");

        // 新增：如果 Socket 处于“死鱼”状态（既没连接，也没在尝试连接），强制连一下
        // 注意：这需要你在 SocketService 暴露 socket 实例或者 connect 方法
        // 如果 socket 为空，说明 init 还没跑，这通常不会发生
        final socket = _socketService.socket;
        if (socket != null && !socket.active) {
          debugPrint("🔌 [ChatRoom] 检测到 Socket 休眠，尝试强制连接...");
          socket.connect();
        }
      }

      // Step B: HTTP 拉取第一页
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: null, // 第一页传 null
      );

      final response = await Api.chatMessagesApi(request);

      //  2. 保存下一页的游标
      _nextCursor = response.nextCursor;

      // Step C: DTO 转 UI Model
      final uiMessages = _mapToUiModels(response.list);

      // Step D: 更新状态
      if (mounted) {
        state = AsyncValue.data(uiMessages);
      }

      // Step E: 开启监听
      _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);

    } catch (e, st) {
      debugPrint("❌ ChatRoom Init Error: $e");
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  // 抽离出的进房逻辑
  void _joinRoom() {
    // 只有真的连上了才发指令
    if (_socketService.isConnected) {
      // debugPrint("🚪 [ChatRoom] 发送 join_chat: $conversationId");
      _socketService.joinChatRoom(conversationId);
    }
  }

  //  3. 新增：加载更多历史消息
  Future<void> loadMore() async {
    // 如果没有下一页了 (cursor为null) 或者正在加载中，直接返回
    if (_nextCursor == null || _isLoadingMore) return;

    _isLoadingMore = true;

    try {
      final request = MessageHistoryRequest(
        conversationId: conversationId,
        pageSize: 20,
        cursor: _nextCursor, // 传入上一页保存的游标
      );

      final response = await Api.chatMessagesApi(request);

      // 更新游标，为下一次做准备
      _nextCursor = response.nextCursor;

      // 转换数据
      final moreMessages = _mapToUiModels(response.list);

      // 将旧消息追加到列表末尾 (因为列表是倒序的: [新 ... 旧])
      state.whenData((currentList) {
        state = AsyncValue.data([...currentList, ...moreMessages]);
      });

    } catch (e) {
      debugPrint("❌ Load more failed: $e");
      // 这里可以选择是否提示用户，或者仅打印日志，不破坏当前 UI
    } finally {
      _isLoadingMore = false;
    }
  }

  // 💡 抽取公共的映射逻辑，避免代码重复
  List<ChatUiModel> _mapToUiModels(List<dynamic> dtoList) {
    return dtoList.map((dto) {
      return ChatUiModel(
        id: dto.id,
        content: dto.content,
        type: MessageType.text,
        isMe: dto.isSelf,
        status: MessageStatus.success,
        createdAt: dto.createdAt,
        senderName: dto.sender?.nickname,
        senderAvatar: dto.sender?.avatar,
      );
    }).toList();
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    
    //核心修复：如果页面已经销毁，直接停止，不要再去碰 state
    if(!mounted) return;


    try{
     // 核心改变：第一步先转成强类型对象
      // 如果数据格式极其离谱，这里可能会报错，但被 try-catch 捕获，不会崩 app

      final message = SocketMessage.fromJson(data);

      // 2. 逻辑判断变得非常易读
      if (message.conversationId != conversationId) return; // 非本会话消息，忽略
      if (message.senderId == myUserId) return; // 自己发的消息

      // 再次检查mounted状态，确保安全
      if(!mounted) return;

      final newMsg = ChatUiModel(
        id: message.id,
        content:message.content,
        type: MessageType.text,
        isMe: false,
        status: MessageStatus.success,
        createdAt: message.createdAt,
        senderName: message.sender?.nickname,
        senderAvatar: message.sender?.avatar,
      );

      // 访问 state 前最后一次检查
      if (!mounted) return;
      state.whenData((currentList) {
        if (!currentList.any((m) => m.id == newMsg.id)) {
          state = AsyncValue.data([newMsg, ...currentList]);
        }
      });
    } catch(e){
      debugPrint("❌ Error in _onSocketMessage: $e");
      return;
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = const Uuid().v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final tempMsg = ChatUiModel(
      id: tempId,
      content: text,
      type: MessageType.text,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: timestamp,
      senderName: "Me",
    );

    final currentList = state.value ?? [];
    state = AsyncValue.data([tempMsg, ...currentList]);

    try {
      final sentMsg = await Api.sendMessage(conversationId, text);

      state.whenData((list) {
        final newList = list.map((msg) {
          if (msg.id == tempId) {
            return msg.copyWith(
              id: sentMsg.id,
              status: MessageStatus.success,
              createdAt: sentMsg.createdAt,
            );
          }
          return msg;
        }).toList();
        state = AsyncValue.data(newList);
      });
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
      state.whenData((list) {
        final newList = list.map((msg) {
          if (msg.id == tempId) {
            return msg.copyWith(status: MessageStatus.failed);
          }
          return msg;
        }).toList();
        state = AsyncValue.data(newList);
      });
    }
  }

  @override
  void dispose() {
    // 1. 离开房间 (告诉后端)
    _socketService.leaveChatRoom(conversationId);

    // 2. 取消消息监听
    _connectionSub?.cancel();
    //  3. 取消连接状态监听 (防止内存泄漏)
    _msgSub?.cancel();
    super.dispose();
  }
}

// Provider 定义
final chatRoomProvider = StateNotifierProvider.family
    .autoDispose<ChatRoomNotifier, AsyncValue<List<ChatUiModel>>, String>((
    ref,
    conversationId,
    ) {

  // 新增：设置一个保活时间 (比如 5 分钟)
  // 这样用户在聊天列表和详情页反复横跳时，不会每次都重新加载
   ref.cacheFor(const Duration(minutes: 5));
  final socketService = ref.watch(socketServiceProvider);

  // 从 Store 获取当前用户信息
  final myUserId = ref.watch(luckyProvider.select((state) => state.userInfo?.id));

  return ChatRoomNotifier(socketService, conversationId, myUserId ?? '');
});