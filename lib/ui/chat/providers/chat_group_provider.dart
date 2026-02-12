import 'dart:math';
import 'package:flutter_app/ui/chat/repository/message_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import '../../../core/api/chat_group_api.dart';
import '../../../core/constants/socket_events.dart';
import '../../../core/store/user_store.dart';
import '../models/conversation.dart';
import '../models/group_role.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

part 'chat_group_provider.g.dart';

@riverpod
class ChatGroup extends _$ChatGroup {
  bool _isSyncing = false;
  bool _mounted = true;

  @override
  Future<ConversationDetail> build(String conversationId) async {
    _mounted = true;
    ref.onDispose(() => _mounted = false);

    final repo = ref.read(messageRepositoryProvider);
    final localData = await repo.getGroupDetail(conversationId);

    if (localData != null) {
      // 解决 Future already completed 崩溃
      Future.microtask(() => _fetchAndSync(conversationId));
      return localData;
    }
    return await _fetchAndSync(conversationId);
  }

  // ===========================================================================
  // 1. 被动响应 Socket 事件
  // ===========================================================================
  void handleSocketEvent(SocketGroupEvent event) async {
    if (event.groupId != conversationId) return;
    if (!_mounted || !state.hasValue || _isSyncing) return;

    final payload = event.payload; // 这是 ChatSocketPayload 对象

    //  修正点：使用点语法 .syncType
    final String? syncType = payload.syncType;

    // 策略 A: REMOVE
    if (syncType == 'REMOVE') {
      state = AsyncValue.error('Group removed', StackTrace.current);
      await LocalDatabaseService().deleteConversation(conversationId);
      return;
    }

    //  策略 B: PATCH
    if (syncType == 'PATCH') {
      _applyLocalPatch(event);
      return;
    }

    // 策略 C: FULL_SYNC
    if (syncType == 'FULL_SYNC') {
      _fetchAndSync(conversationId, useJitter: true);
      return;
    }

    _fetchAndSync(conversationId);
  }

  //  内部补丁方法
  void _applyLocalPatch(SocketGroupEvent event) {
    if (!state.hasValue) return;

    final currentDetail = state.requireValue;
    ConversationDetail? newDetail;
    final payload = event.payload; // ChatSocketPayload 对象

    switch (event.type) {
      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
      //  修正点：使用 .targetId
        final targetId = payload.targetId;
        if (targetId == null) return;
        final newMembers = currentDetail.members
            .where((m) => m.userId != targetId)
            .toList();

        newDetail = currentDetail.copyWith(members: newMembers);
        break;

      case SocketEvents.memberMuted:
      //  修正点：使用 .targetId 和 .mutedUntil
        final targetId = payload.targetId;
        final mutedUntil = payload.mutedUntil;
        if (targetId == null) return;

        final newMembers = currentDetail.members.map((m) {
          return m.userId == targetId ? m.copyWith(mutedUntil: mutedUntil) : m;
        }).toList();
        newDetail = currentDetail.copyWith(members: newMembers);
        break;

      case SocketEvents.groupInfoUpdated:
      // 修正点：使用 .updates (假设它是一个 Map<String, dynamic>?)
        final updates = payload.updates;

        newDetail = currentDetail.copyWith(
          name: updates['name'] ?? currentDetail.name,
          announcement: updates['announcement'] ?? currentDetail.announcement,
          isMuteAll: updates['isMuteAll'] ?? currentDetail.isMuteAll,
          avatar: updates['avatar'] ?? currentDetail.avatar,
        );
        break;

      case SocketEvents.memberJoined:
      // 如果 payload.member 存在
        break;
    }

    if (newDetail != null) {
      state = AsyncData(newDetail);
      LocalDatabaseService().saveConversationDetail(newDetail);
    }
  }

  // ===========================================================================
  // 2. 主动操作 (保持逻辑不变)
  // ===========================================================================

  Future<void> kickMember(String targetUserId) async {
    try {
      await ChatGroupApi.kickMember(conversationId, targetUserId);
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          members: currentDetail.members.where((m) => m.userId != targetUserId).toList(),
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  Future<void> muteMember(String targetUserId, int duration) async {
    try {
      final res = await ChatGroupApi.muteMember(conversationId, targetUserId, duration);
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
            members: currentDetail.members.map((m) =>
            m.userId == targetUserId ? m.copyWith(mutedUntil: res.mutedUntil) : m
            ).toList()
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  Future<bool> inviteMembers(List<String> memberIds) async {
    try {
      await Api.groupInviteApi(InviteToGroupRequest(groupId: conversationId, memberIds: memberIds));
      await _fetchAndSync(conversationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> setAdmin(String targetUserId, bool isAdmin) async {
    try {
      await ChatGroupApi.setAdmin(conversationId, targetUserId, isAdmin);
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
            members: currentDetail.members.map((m) =>
            m.userId == targetUserId ? m.copyWith(role: isAdmin ? GroupRole.admin : GroupRole.member) : m
            ).toList()
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  Future<void> updateInfo({String? name, String? announcement, bool? isMuteAll}) async {
    try {
      final res = await ChatGroupApi.updateGroupInfo(
        conversationId: conversationId,
        name: name,
        announcement: announcement,
        isMuteAll: isMuteAll,
      );
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          name: res.name,
          announcement: res.announcement,
          isMuteAll: res.isMuteAll,
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  Future<bool> leaveGroup() async {
    try {
      final res = await ChatGroupApi.leaveGroup(conversationId);
      return res.success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> disbandGroup() async {
    try {
      await ChatGroupApi.disbandGroup(conversationId);
      ref.invalidate(conversationListProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  // --- 4. 辅助方法 (核心同步逻辑) ---

  Future<ConversationDetail> _fetchAndSync(String id, {bool useJitter = false}) async {
    if (_isSyncing || !_mounted) return state.value ?? await Api.chatDetailApi(id);
    _isSyncing = true;

    try {
      if (useJitter) {
        // 随机延迟 0~3 秒
        await Future.delayed(Duration(milliseconds: Random().nextInt(3000)));
      }

      final networkData = await Api.chatDetailApi(id);
      await LocalDatabaseService().saveConversationDetail(networkData);

      if (_mounted) {
        state = AsyncData(networkData);
      }
      return networkData;
    } catch (e) {
      if (state.hasValue) return state.value!;
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }
}

// ===========================================================================
// 建群控制器
// ===========================================================================
@riverpod
class GroupCreateController extends _$GroupCreateController {
  @override
  FutureOr<String?> build() => null;

  Future<String?> create({required String name, required List<String> memberIds}) async {
    state = const AsyncLoading();
    final newState = await AsyncValue.guard(() async {
      final res = await Api.createGroupApi(name, memberIds);
      return res.id;
    });
    state = newState;
    if (newState.hasValue) {
      ref.invalidate(conversationListProvider);
    }
    return newState.value;
  }
}