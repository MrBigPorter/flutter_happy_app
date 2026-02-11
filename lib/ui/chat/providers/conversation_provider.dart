import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/socket_events.dart';
import '../../../core/providers/socket_provider.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../models/chat_ui_model_mapper.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

final activeConversationIdProvider = StateProvider<String?>((ref) => null);

@Riverpod(keepAlive: true)
class ConversationList extends _$ConversationList {
  StreamSubscription? _conversationSub;
  StreamSubscription? _conversationUpdateSub;

  @override
  FutureOr<List<Conversation>> build() async {
    final currentUserId = ref.watch(
      userProvider.select((s) => s?.id),
    );

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

    _conversationUpdateSub?.cancel();
    _conversationUpdateSub = socketService.conversationUpdateStream.listen(
      _onConversationAttributeUpdate,
    );

    ref.onDispose(() {
      _conversationSub?.cancel();
      _conversationUpdateSub?.cancel();
    });

    // 2. 先加载本地旧数据 (秒开)
    final localData = await LocalDatabaseService().getConversations();
    if (localData.isNotEmpty) {
      state = AsyncData(localData);
    }

    // 3.  修复点 1：启动时同步改用 microtask。
    // 确保 build 方法已经完成了初始返回，避免“Future already completed”报错。
    Future.microtask(() => _fetchList());

    return localData;
  }

  //  新增部分：供 ChatEventProcessor 调用的接口
  void handleSocketEvent(SocketGroupEvent event) {
    //  修复点 2：增加 isLoading 检查。
    // 如果列表正在同步（Loading 状态），忽略增量更新，由 _fetchList 结果统一覆盖，防止崩溃。
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.requireValue;
    final groupId = event.groupId;
    final myId = ref.read(userProvider.select((s) => s?.id));
    print(" [ConversationList] 处理事件: ${event.type} | GroupID: $groupId | MyID: $myId");

    if (groupId == null) return;

    List<Conversation>? newList;

    final payload = event.payload;

    switch (event.type) {
      case SocketEvents.groupInfoUpdated:
        newList = currentList.map((conv) {
          if (conv.id == groupId) {
            return conv.copyWith(
              name: payload.updates['name'] ?? conv.name,
              avatar: payload.updates['avatar'] ?? conv.avatar,
            );
          }
          return conv;
        }).toList();
        break;

      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
      case SocketEvents.groupDisbanded:
        final targetId = payload.targetId;
        bool shouldRemove = false;

        if (event.type == SocketEvents.groupDisbanded) {
          shouldRemove = true;
        } else if (targetId != null && targetId == myId) {
          shouldRemove = true;
        }

        if (shouldRemove) {
          newList = currentList.where((conv) => conv.id != groupId).toList();
        }
        break;

      case SocketEvents.memberJoined:
        final targetId = payload.targetId;
        if (targetId != null && targetId == myId) {
          _fetchList();
          return;
        }
        break;
    }

    if (newList != null) {
      state = AsyncData(newList);
      LocalDatabaseService().saveConversations(newList);
    }
  }

  Future<List<Conversation>> _fetchList() async {
    try {
      final list = await Api.chatListApi(page: 1);
      await LocalDatabaseService().saveConversations(list);

      final currentActiveId = ref.read(activeConversationIdProvider);
      debugPrint(
        " [ConversationList] Synced ${list.length} conversations from server.",
      );

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
    if (!state.hasValue || state.isLoading) return; // 🛡️ 增加保护
    final currentList = state.value!;
    if (currentList.any((c) => c.id == newItem.id)) return;
    state = AsyncData([newItem, ...currentList]);
  }

  void _onNewMessage(SocketMessage msg) async {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final user = ref.read(userProvider);
    final myUserId = user?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

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
        nickname: msg.sender!.nickname ?? 'Unknown',
        avatar: msg.sender!.avatar,
      ),
    );

    final uiMsg = ChatUiModelMapper.fromApiModel(apiMsg, convId);
    await LocalDatabaseService().saveMessage(uiMsg);

    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

      final newUnreadCount = (isMe || isViewingNow)
          ? 0
          : (oldConv.unreadCount + 1);

      final newConv = oldConv.copyWith(
        lastMsgContent: _getPreviewContent(msg.type, msg.content),
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: newUnreadCount,
        lastMsgStatus: MessageStatus.success,
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

  void _onConversationAttributeUpdate(Map<String, dynamic> data) async {
    if (!state.hasValue || state.isLoading) return; // 🛡️ 增加保护

    final String convId = data['id'];
    final updates = data['updates'] ?? data;
    final String? newAvatar = updates['avatar'];
    final String? newName = updates['name'];

    final currentList = state.value!;
    final index = currentList.indexWhere((c) => c.id == convId);

    if (index != -1) {
      final oldConv = currentList[index];
      bool isChanged = false;
      var newConv = oldConv;

      if (newAvatar != null && oldConv.avatar != newAvatar) {
        newConv = newConv.copyWith(avatar: newAvatar);
        isChanged = true;
      }
      if (newName != null && oldConv.name != newName) {
        newConv = newConv.copyWith(name: newName);
        isChanged = true;
      }

      if (isChanged) {
        final newList = [...currentList];
        newList[index] = newConv;
        state = AsyncData(newList);
        await LocalDatabaseService().saveConversations([newConv]);
      }
    }
  }

  void updateLocalItem({
    required String conversationId,
    String? lastMsgContent,
    int? lastMsgTime,
    MessageStatus? lastMsgStatus,
  }) {
    if (!state.hasValue || state.isLoading) return; // 🛡️ 增加保护

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
    if (!state.hasValue || state.isLoading) return; // 🛡️ 增加保护

    final newList = state.value!.map((c) {
      if (c.id == conversationId) return c.copyWith(unreadCount: 0);
      return c;
    }).toList();
    state = AsyncData(newList);
  }

  String _getPreviewContent(dynamic type, String rawContent) {
    final int typeInt = int.tryParse(type.toString()) ?? 0;
    if (typeInt == 1) return '[Image]';
    if (typeInt == 2) return '[Voice]';
    if (typeInt == 3) return '[Video]';
    if (typeInt == 4) return '[File]';
    if (typeInt == 5) return '[Location]';
    if (typeInt == 99) return '[Message recalled]';
    return rawContent;
  }
}

// --- 其他代码保持原样 ---

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
    if (localData == null) throw e;
  }
}