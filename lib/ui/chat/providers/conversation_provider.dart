import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

@Riverpod(keepAlive: true)
class ConversationList extends _$ConversationList {
  StreamSubscription? _conversationSub;
  @override
  FutureOr<List<Conversation>> build() async {
    final currentUserId = ref.watch(userProvider.select((s) => s?.id));

    if (currentUserId == null || currentUserId.isEmpty) {
      return [];
    }

    // 1. 初始化数据库
    await LocalDatabaseService.init(currentUserId);

    final socketService = ref.watch(socketServiceProvider);

    _conversationSub?.cancel();
    _conversationSub = socketService.conversationListUpdateStream.listen(
      _onNewMessage,
    );


    ref.onDispose(() {
      _conversationSub?.cancel();
    });

    // 2. 先加载本地旧数据 (秒开)
    final localData = await LocalDatabaseService().getConversations();
    if (localData.isNotEmpty) {
      state = AsyncData(localData);
      // 3.  [修正 2] 使用 microtask 避免 build 期间 setState 冲突
      Future.microtask(() => _fetchList());
      return localData;
    }

    // 4. 无缓存：走网络请求
    return await _fetchList();
  }

  // ===========================================================================
  //  [修正 3] handleSocketEvent: 统一处理后端的 SyncType 指令
  // ===========================================================================
  void handleSocketEvent(SocketGroupEvent event) async {
    if (!state.hasValue || state.isLoading) return;

    final payload = event.payload; // ChatSocketPayload

    //  [修正 3.1] 使用强类型属性 (不再用 map['key'])
    final String? syncType = payload.syncType;
    final String groupId = event.groupId;

    //  策略 A: REMOVE (被踢、解散)
    if (syncType == 'REMOVE') {
      final newList = state.requireValue.where((c) => c.id != groupId).toList();
      state = AsyncData(newList);
      await LocalDatabaseService().deleteConversation(groupId);
      return;
    }

    //  策略 B: PATCH (改名、禁言等)
    if (syncType == 'PATCH') {
      //  [修正 3.2] 传入 payload.updates Map
      _applyLocalPatch(groupId, payload.updates);
      return;
    }

    //  策略 C: FULL_SYNC (复杂情况兜底)
    if (syncType == 'FULL_SYNC') {
      await Future.delayed(Duration(milliseconds: Random().nextInt(3000)));
      await _fetchList();
      return;
    }
  }

  // 内部 Helper: 只修补内存，不拉接口
  void _applyLocalPatch(String groupId, Map<String, dynamic>? updates) {
    if (!state.hasValue || updates == null) return;

    final currentList = state.requireValue;
    final index = currentList.indexWhere((c) => c.id == groupId);
    if (index == -1) return;

    final oldConv = currentList[index];
    final newConv = oldConv.copyWith(
      name: updates['name'] ?? oldConv.name,
      avatar: updates['avatar'] ?? oldConv.avatar,
    );

    final newList = [...currentList];
    newList[index] = newConv;

    state = AsyncData(newList);
    LocalDatabaseService().saveConversations([newConv]);
  }

  Future<List<Conversation>> _fetchList() async {
    try {
      final list = await Api.chatListApi(page: 1);
      await LocalDatabaseService().saveConversations(list);

      final currentActiveId = ref.read(activeConversationIdProvider);
      debugPrint(" [ConversationList] Synced ${list.length} conversations.");

      final processedList = list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();

      state = AsyncData(processedList);
      return processedList;
    } catch (e) {
      debugPrint(" [ConversationList] Sync failed: $e");
      if (state.hasValue) return state.value!;
      return [];
    }
  }

  Future<void> refresh() async {
    await _fetchList();
  }

  void addConversation(Conversation newItem) {
    if (!state.hasValue || state.isLoading) return;
    final currentList = state.value!;
    if (currentList.any((c) => c.id == newItem.id)) return;
    state = AsyncData([newItem, ...currentList]);
  }

  // ===========================================================================
  //  [修正 4] _onNewMessage: 处理新消息 + 系统消息副作用
  // ===========================================================================
  void _onNewMessage(SocketMessage msg) async {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final user = ref.read(userProvider);
    final myUserId = user?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

    // 1. 转 UI Model 并入库
    final apiMsg = ChatMessage(
      id: msg.id,
      content: msg.content,
      type: msg.type,
      seqId: msg.seqId,
      createdAt: msg.createdAt,
      isSelf: isMe,
      meta: msg.meta,
      sender: msg.sender == null
          ? null
          : ChatSender(
        id: msg.sender!.id,
        nickname: msg.sender!.nickname,
        avatar: msg.sender!.avatar,
      ),
    );

    final uiMsg = ChatUiModelMapper.fromApiModel(apiMsg, convId);
    await LocalDatabaseService().saveMessage(uiMsg);

    //  [修正 4.1] 检查 meta 数据，提取改名信息
    String? newName;
    String? newAvatar;

    if (msg.type == 99 && msg.meta != null) {
      // 强转 Map 防止 dynamic 问题
      final meta = msg.meta as Map<String, dynamic>;
      if (meta['action'] == 'UPDATE_INFO' && meta['updates'] != null) {
        final updates = meta['updates'] as Map<String, dynamic>;
        newName = updates['name'];
        newAvatar = updates['avatar'];
      }
    }

    // 2. 更新列表项
    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

      final newUnreadCount = (isMe || isViewingNow) ? 0 : (oldConv.unreadCount + 1);

      final newConv = oldConv.copyWith(
        //  [修正 4.2] 传入 isRecalled 参数
        lastMsgContent: _getPreviewContent(msg.type, msg.content, isRecalled: msg.isRecalled ?? false),
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: newUnreadCount,
        lastMsgStatus: MessageStatus.success,

        //  [修正 4.3] 如果是系统改名消息，顺便更新会话的名字/头像
        name: newName ?? oldConv.name,
        avatar: newAvatar ?? oldConv.avatar,
      );

      final newList = [...currentList];
      newList.removeAt(index);
      newList.insert(0, newConv);

      state = AsyncData(newList);
      await LocalDatabaseService().saveConversations([newConv]);
    } else {
      _fetchList();
    }
  }

  // ===========================================================================
  //  [修正 5] 辅助方法清理
  // ===========================================================================

  // 删除了嵌套错误的 _onNewMessage，修复了 updateLocalItem
  void updateLocalItem({
    required String conversationId,
    String? lastMsgContent,
    int? lastMsgTime,
    MessageStatus? lastMsgStatus,
  }) {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final index = currentList.indexWhere((conv) => conversationId == conv.id);

    if (index != -1) {
      final oldConv = currentList[index];
      final newConv = oldConv.copyWith(
        lastMsgContent: lastMsgContent ?? oldConv.lastMsgContent,
        lastMsgTime: lastMsgTime ?? oldConv.lastMsgTime,
        lastMsgStatus: lastMsgStatus ?? oldConv.lastMsgStatus,
      );
      final newList = [...currentList];
      newList.removeAt(index);
      newList.insert(0, newConv);
      state = AsyncData(newList);
    } else {
      _fetchList();
    }
  }

  void clearUnread(String conversationId) {
    if (!state.hasValue || state.isLoading) return;

    final newList = state.value!.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = AsyncData(newList);
  }

  //  [修正 6] 修复了语法错误，使用 Enum 获取文本
  String _getPreviewContent(dynamic type, String rawContent, {bool isRecalled = false}) {
    final int typeInt = (type is int) ? type : int.tryParse(type.toString()) ?? 0;

    // 使用你定义的 MessageType Enum
    final typeEnum = MessageType.fromValue(typeInt);

    // 返回处理后的字符串
    return typeEnum.getPreviewText(rawContent, isRecalled: isRecalled);
  }
}

// --- 其他代码 (CreateDirectChatController, chatDetail) 保持不变，可以照抄原文件 ---
@riverpod
class CreateDirectChatController extends _$CreateDirectChatController {
  @override
  AsyncValue<ConversationIdResponse?> build() {
    return const AsyncData(null);
  }

  Future<ConversationIdResponse?> createDirectChat(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await Api.chatDirectApi(userId);
    });
    if (state.hasError) return null;
    return state.value;
  }
}

@riverpod
Stream<ConversationDetail> chatDetail(
    ChatDetailRef ref,
    String conversationId,
    ) async* {
  final userId = ref.watch(userProvider.select((s) => s?.id));

  if (userId != null && userId.isNotEmpty) {
    await LocalDatabaseService.init(userId);
  }

  final db = LocalDatabaseService();

  ConversationDetail? localData;
  try {
    localData = await db.getConversationDetail(conversationId);
    if (localData != null) {
      yield localData;
    }
  } catch (e) {
    debugPrint(" [chatDetail] Local DB Fetch Error: $e");
  }

  try {
    final networkData = await Api.chatDetailApi(conversationId);
    await db.saveConversationDetail(networkData);
    yield networkData;
  } catch (e) {
    debugPrint(" [chatDetail] Network Fetch Error: $e");
    // 如果没有本地数据且网络也失败，才抛出异常
    if (localData == null) rethrow;
  }
}