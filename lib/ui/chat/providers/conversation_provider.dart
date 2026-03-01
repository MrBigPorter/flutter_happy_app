import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/socket_provider.dart';
import '../models/chat_ui_model.dart';
import '../models/conversation.dart';
import '../repository/message_repository.dart';
import '../services/database/local_database_service.dart';

part 'conversation_provider.g.dart';

/// Provider to track the currently active chat room ID for unread filtering
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

    // 1. Initialize local storage instance
    await LocalDatabaseService.init(currentUserId);

    final socketService = ref.watch(socketServiceProvider);

    // 2. Subscribe to real-time message stream
    _conversationSub?.cancel();
    _conversationSub = socketService.conversationListUpdateStream.listen(
      _onNewMessage,
    );

    ref.onDispose(() {
      _conversationSub?.cancel();
    });

    // 3. Offline-First: Load cached data for instant UI rendering
    final localData = await LocalDatabaseService().getConversations();
    if (localData.isNotEmpty) {
      state = AsyncData(localData);
      // Use microtask to avoid setState conflicts during the build phase
      Future.microtask(() => _fetchList());
      return localData;
    }

    // 4. Fallback to network fetch if no local cache exists
    return await _fetchList();
  }

  // ===========================================================================
  // 1. Socket Signal Handling (Group Lifecycle & Sync)
  // ===========================================================================

  void handleSocketEvent(SocketGroupEvent event) async {
    if (!state.hasValue || state.isLoading) return;

    final payload = event.payload;
    final String? syncType = payload.syncType;
    final String groupId = event.groupId;

    // Strategy A: REMOVE - Handle group disbandment or expulsion
    if (syncType == 'REMOVE') {
      final newList = state.requireValue.where((c) => c.id != groupId).toList();
      state = AsyncData(newList);
      await LocalDatabaseService().deleteConversation(groupId);
      return;
    }

    // Strategy B: PATCH - Atomic updates for group metadata (Name, Avatar)
    if (syncType == 'PATCH') {
      _applyLocalPatch(groupId, payload.updates);
      return;
    }

    // Strategy C: FULL_SYNC - Trigger network sync with jitter to prevent server spikes
    if (syncType == 'FULL_SYNC') {
      await Future.delayed(Duration(milliseconds: Random().nextInt(3000)));
      await _fetchList();
      return;
    }
  }

  /// Updates memory state and local DB for specific group metadata changes
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

  /// Syncs conversation list with the backend and clears unread for the active room
  Future<List<Conversation>> _fetchList() async {
    try {
      final list = await Api.chatListApi(page: 1);
      await LocalDatabaseService().saveConversations(list);

      final currentActiveId = ref.read(activeConversationIdProvider);
      debugPrint("[ConversationList] Synced ${list.length} conversations.");

      final processedList = list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();

      state = AsyncData(processedList);
      return processedList;
    } catch (e) {
      debugPrint("[ConversationList] Sync failed: $e");
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
  // 2. Real-time Message & Event Processing
  // ===========================================================================

  void _onNewMessage(SocketMessage msg) async {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final user = ref.read(userProvider);
    final myUserId = user?.id ?? "";
    final senderId = msg.sender?.id ?? "";
    final bool isMe = senderId.isNotEmpty && (senderId == myUserId);
    final convId = msg.conversationId;

    // 1. Transform to UI Model and persist to DB
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

    // Metadata extraction for system notification side-effects
    String? newName;
    String? newAvatar;

    if (msg.type == 99 && msg.meta != null) {
      final meta = msg.meta as Map<String, dynamic>;
      if (meta['action'] == 'UPDATE_INFO' && meta['updates'] != null) {
        final updates = meta['updates'] as Map<String, dynamic>;
        newName = updates['name'];
        newAvatar = updates['avatar'];
      }
    }

    // 2. Update specific conversation item in the list
    final index = currentList.indexWhere((conv) => conv.id == convId);
    if (index != -1) {
      final oldConv = currentList[index];
      final currentActiveId = ref.read(activeConversationIdProvider);
      final bool isViewingNow = (currentActiveId == convId);

      final newUnreadCount = (isMe || isViewingNow) ? 0 : (oldConv.unreadCount + 1);

      final newConv = oldConv.copyWith(
        lastMsgContent: _getPreviewContent(msg.type, msg.content, isRecalled: msg.isRecalled ?? false),
        lastMsgTime: DateTime.now().millisecondsSinceEpoch,
        unreadCount: newUnreadCount,
        lastMsgStatus: MessageStatus.success,
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
  // 3. UI Helper Methods
  // ===========================================================================

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

  /// Maps message type and raw content into localized preview text
  String _getPreviewContent(dynamic type, String rawContent, {bool isRecalled = false}) {
    final int typeInt = (type is int) ? type : int.tryParse(type.toString()) ?? 0;
    final typeEnum = MessageType.fromValue(typeInt);
    return typeEnum.getPreviewText(rawContent, isRecalled: isRecalled);
  }
}

// --- Controller Definitions ---

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
    debugPrint("[chatDetail] Local DB Fetch Error: $e");
  }

  try {
    final networkData = await Api.chatDetailApi(conversationId);
    await db.saveConversationDetail(networkData);
    yield networkData;
  } catch (e) {
    debugPrint("[chatDetail] Network Fetch Error: $e");
    if (localData == null) rethrow;
  }
}

@riverpod
class ConversationSettingsController extends _$ConversationSettingsController {
  @override
  FutureOr<void> build() {}

  // 1. 设置免打扰
  Future<void> toggleMute(String conversationId, bool isMuted) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: 这里换成你真实的 API 请求，例如：await Api.setMute(conversationId, isMuted);

      // 完美调用你的 MessageRepository 操作本地数据库
      final repo = ref.read(messageRepositoryProvider);
      final detail = await repo.getGroupDetail(conversationId);

      if (detail != null) {
        await repo.saveGroupDetail(detail.copyWith(isMuted: isMuted));
      }

      // 刷新详情页 UI
      ref.invalidate(chatDetailProvider(conversationId));
    });
  }

  // 2. 设置置顶
  Future<void> togglePin(String conversationId, bool isPinned) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: 这里换成你真实的 API 请求，例如：await Api.setPin(conversationId, isPinned);

      // 完美调用你的 MessageRepository 操作本地数据库
      final repo = ref.read(messageRepositoryProvider);
      final detail = await repo.getGroupDetail(conversationId);

      if (detail != null) {
        await repo.saveGroupDetail(detail.copyWith(isPinned: isPinned));
      }

      // 刷新详情页 UI 和 外部列表 UI (置顶需要重排列表)
      ref.invalidate(chatDetailProvider(conversationId));
      ref.read(conversationListProvider.notifier).refresh();
    });
  }

  // 3. 清空聊天记录
  Future<void> clearHistory(String conversationId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: 调真实 API 通知后端清空，例如：await Api.clearHistory(conversationId);

      // 调用我们在第一步加在 Repository 里的清空方法
      final repo = ref.read(messageRepositoryProvider);
      await repo.clearConversationHistory(conversationId);
    });
  }
}