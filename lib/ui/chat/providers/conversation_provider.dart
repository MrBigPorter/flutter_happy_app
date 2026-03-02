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

    final repo = ref.read(messageRepositoryProvider);

    // 1. Initialize repository (which internally inits DB)
    await repo.initDatabase(currentUserId);

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
    final localData = await repo.getAllConversations();
    if (localData.isNotEmpty) {
      _sortAndEmit(localData);

      // Use microtask to avoid setState conflicts during the build phase
      Future.microtask(() => _fetchList());
      return state.requireValue;
    }

    // 4. Fallback to network fetch if no local cache exists
    return await _fetchList();
  }

  /// Centralized sorting and state emission method to ensure consistent ordering logic
  void _sortAndEmit(List<Conversation> list) {
    final sortedList = List<Conversation>.from(list);

    sortedList.sort((a, b) {
      // sort by pinned status first
      final aPinned = (a.isPinned == true) ? 1 : 0;
      final bPinned = (b.isPinned == true) ? 1 : 0;

      if (aPinned != bPinned) {
        return bPinned.compareTo(aPinned);
      }

      // then sort by last message time
      final aTime = a.lastMsgTime ?? 0;
      final bTime = b.lastMsgTime ?? 0;
      return bTime.compareTo(aTime);
    });

    state = AsyncData(sortedList);
  }

  void updateConversationPin(String conversationId, bool isPinned) {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final index = currentList.indexWhere((conv) => conversationId == conv.id);

    if (index != -1) {
      final oldConv = currentList[index];
      final newConv = oldConv.copyWith(isPinned: isPinned);

      final newList = [...currentList];
      newList[index] = newConv;

      _sortAndEmit(newList);

      ref.read(messageRepositoryProvider).updateConversationField(conversationId, {'isPinned': isPinned});
    }
  }

  void updateConversationMute(String conversationId, bool isMuted) {
    if (!state.hasValue || state.isLoading) return;

    final currentList = state.value!;
    final index = currentList.indexWhere((conv) => conversationId == conv.id);

    if (index != -1) {
      final oldConv = currentList[index];
      final newConv = oldConv.copyWith(isMuted: isMuted);

      final newList = [...currentList];
      newList[index] = newConv;

      _sortAndEmit(newList);

      ref.read(messageRepositoryProvider).updateConversationField(conversationId, {'isMuted': isMuted});
    }
  }

  // ===========================================================================
  // 1. Socket Signal Handling (Group Lifecycle & Sync)
  // ===========================================================================

  void handleSocketEvent(SocketGroupEvent event) async {
    if (!state.hasValue || state.isLoading) return;

    final payload = event.payload;
    final String? syncType = payload.syncType;
    final String groupId = event.groupId;
    final repo = ref.read(messageRepositoryProvider);

    if (syncType == 'REMOVE') {
      final newList = state.requireValue.where((c) => c.id != groupId).toList();
      _sortAndEmit(newList);
      await repo.deleteConversation(groupId); // 🚀 使用 Repo
      return;
    }

    if (syncType == 'PATCH') {
      _applyLocalPatch(groupId, payload.updates);
      return;
    }

    if (syncType == 'FULL_SYNC') {
      await Future.delayed(Duration(milliseconds: Random().nextInt(3000)));
      await _fetchList();
      return;
    }
  }

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

    _sortAndEmit(newList);
    ref.read(messageRepositoryProvider).saveConversations([newConv]);
  }

  Future<List<Conversation>> _fetchList() async {
    try {
      final list = await Api.chatListApi(page: 1);
      final repo = ref.read(messageRepositoryProvider);

      await repo.saveConversations(list);

      final currentActiveId = ref.read(activeConversationIdProvider);
      debugPrint("[ConversationList] Synced ${list.length} conversations.");

      final processedList = list.map((c) {
        if (c.id == currentActiveId) return c.copyWith(unreadCount: 0);
        return c;
      }).toList();

      _sortAndEmit(processedList);
      return state.requireValue;
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

    _sortAndEmit([newItem, ...currentList]);
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
    final repo = ref.read(messageRepositoryProvider);

    // 1. Transform to UI Model and persist to DB via Repo
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
    await repo.saveOrUpdate(uiMsg);

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
      newList.add(newConv);

      _sortAndEmit(newList);
      await repo.saveConversations([newConv]);
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
      newList.add(newConv);

      _sortAndEmit(newList);
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

    _sortAndEmit(newList);
  }

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
class ChatDetail extends _$ChatDetail {
  @override
  FutureOr<ConversationDetail> build(String conversationId) async {
    final userId = ref.watch(userProvider.select((s) => s?.id));
    final repo = ref.read(messageRepositoryProvider);

    if (userId != null && userId.isNotEmpty) {
      await repo.initDatabase(userId);
    }

    final localData = await repo.getGroupDetail(conversationId);

    if (localData != null) {
      _syncNetworkData(conversationId, repo);
      return localData;
    }

    final networkData = await Api.chatDetailApi(conversationId);
    await repo.saveGroupDetail(networkData);
    return networkData;
  }

  Future<void> _syncNetworkData(String conversationId, MessageRepository repo) async {
    try {
      final networkData = await Api.chatDetailApi(conversationId);
      await repo.saveGroupDetail(networkData);
      if (state.hasValue) {
        state = AsyncData(networkData);
      }
    } catch (e) {
      debugPrint("[ChatDetail] Network sync failed: $e");
    }
  }

  void updateState(ConversationDetail newDetail) {
    state = AsyncData(newDetail);
  }
}

@riverpod
class ConversationSettingsController extends _$ConversationSettingsController {
  @override
  FutureOr<void> build() {}

  Future<void> toggleMute(String conversationId, bool isMuted) async {
    await Api.setConversationMute(conversationId, isMuted);

    final repo = ref.read(messageRepositoryProvider);
    final detail = await repo.getGroupDetail(conversationId);

    if (detail != null) {
      final newDetail = detail.copyWith(isMuted: isMuted);
      await repo.saveGroupDetail(newDetail);
      ref.read(chatDetailProvider(conversationId).notifier).updateState(newDetail);
    }
    ref.read(conversationListProvider.notifier).updateConversationMute(conversationId, isMuted);
  }

  Future<void> togglePin(String conversationId, bool isPinned) async {
    await Api.setConversationPin(conversationId, isPinned);

    final repo = ref.read(messageRepositoryProvider);
    final detail = await repo.getGroupDetail(conversationId);

    if (detail != null) {
      final newDetail = detail.copyWith(isPinned: isPinned);
      await repo.saveGroupDetail(newDetail);
      ref.read(chatDetailProvider(conversationId).notifier).updateState(newDetail);
    }

    ref.read(conversationListProvider.notifier).updateConversationPin(conversationId, isPinned);
  }

  Future<void> clearHistory(String conversationId) async {
    await Api.clearConversationHistory(conversationId);

    final repo = ref.read(messageRepositoryProvider);
    await repo.clearConversationHistory(conversationId);

    final detail = await repo.getGroupDetail(conversationId);
    if (detail != null) {
      ref.read(chatDetailProvider(conversationId).notifier).updateState(detail);
    }
  }
}