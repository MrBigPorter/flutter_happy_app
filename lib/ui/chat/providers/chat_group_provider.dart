import 'dart:math';
import 'package:flutter_app/ui/chat/models/group_manage_req.dart';
import 'package:flutter_app/ui/chat/repository/message_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_app/common.dart';
import '../../../core/api/chat_group_api.dart';
import '../../../core/constants/socket_events.dart';
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
      // Use microtask to avoid "Future already completed" during synchronous build
      Future.microtask(() => _fetchAndSync(conversationId));
      return localData;
    }
    return await _fetchAndSync(conversationId);
  }

  // ===========================================================================
  // 1. Passive Socket Event Handling
  // ===========================================================================

  void handleSocketEvent(SocketGroupEvent event) async {
    if (event.groupId != conversationId) return;
    if (!_mounted || !state.hasValue || _isSyncing) return;

    final payload = event.payload;
    final String? syncType = payload.syncType;

    // Strategy A: REMOVE - Local cleanup when group is disbanded or kicked
    if (syncType == 'REMOVE') {
      state = AsyncValue.error('Group removed', StackTrace.current);
      await LocalDatabaseService().deleteConversation(conversationId);
      return;
    }

    // Strategy B: PATCH - Granular local update without full re-fetch
    if (syncType == 'PATCH') {
      _applyLocalPatch(event);
      return;
    }

    // Strategy C: FULL_SYNC - Trigger network fetch with jitter for high-traffic events
    if (syncType == 'FULL_SYNC') {
      _fetchAndSync(conversationId, useJitter: true);
      return;
    }

    _fetchAndSync(conversationId);
  }

  /// Applies atomic updates to the current state based on specific socket events
  void _applyLocalPatch(SocketGroupEvent event) {
    if (!state.hasValue) return;

    final currentDetail = state.requireValue;
    ConversationDetail? newDetail;
    final payload = event.payload;

    switch (event.type) {
      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
        final targetId = payload.targetId;
        if (targetId == null) return;
        final newMembers = currentDetail.members
            .where((m) => m.userId != targetId)
            .toList();

        newDetail = currentDetail.copyWith(members: newMembers);
        break;

      case SocketEvents.memberMuted:
        final targetId = payload.targetId;
        final mutedUntil = payload.mutedUntil;
        if (targetId == null) return;

        final newMembers = currentDetail.members.map((m) {
          return m.userId == targetId ? m.copyWith(mutedUntil: mutedUntil) : m;
        }).toList();
        newDetail = currentDetail.copyWith(members: newMembers);
        break;

      case SocketEvents.groupInfoUpdated:
        final updates = payload.updates;
        newDetail = currentDetail.copyWith(
          name: updates['name'] ?? currentDetail.name,
          announcement: updates['announcement'] ?? currentDetail.announcement,
          isMuteAll: updates['isMuteAll'] ?? currentDetail.isMuteAll,
          avatar: updates['avatar'] ?? currentDetail.avatar,
        );
        break;

      case SocketEvents.memberJoined:
      // Future implementation: Add single member to list
        break;
    }

    if (newDetail != null) {
      state = AsyncData(newDetail);
      LocalDatabaseService().saveConversationDetail(newDetail);
    }
  }

  // ===========================================================================
  // 2. Active Administrative Operations
  // ===========================================================================

  Future<void> kickMember(String targetUserId) async {
    try {
      await ChatGroupApi.kickMember(conversationId, targetUserId);
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          members: currentDetail.members
              .where((m) => m.userId != targetUserId)
              .toList(),
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
      final res = await ChatGroupApi.muteMember(
        conversationId,
        targetUserId,
        duration,
      );
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          members: currentDetail.members
              .map(
                (m) => m.userId == targetUserId
                ? m.copyWith(mutedUntil: res.mutedUntil)
                : m,
          )
              .toList(),
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
      await Api.groupInviteApi(
        InviteToGroupRequest(groupId: conversationId, memberIds: memberIds),
      );
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
          members: currentDetail.members
              .map(
                (m) => m.userId == targetUserId
                ? m.copyWith(
              role: isAdmin ? GroupRole.admin : GroupRole.member,
            )
                : m,
          )
              .toList(),
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  Future<void> updateInfo({
    String? name,
    String? avatar,
    String? announcement,
    bool? isMuteAll,
    bool? joinNeedApproval,
  }) async {
    try {
      final res = await ChatGroupApi.updateGroupInfo(
        conversationId: conversationId,
        name: name,
        announcement: announcement,
        isMuteAll: isMuteAll,
        avatar: avatar,
        joinNeedApproval: joinNeedApproval,
      );
      if (state.hasValue) {
        final currentDetail = state.requireValue;
        final newDetail = currentDetail.copyWith(
          name: res.name,
          announcement: res.announcement,
          isMuteAll: res.isMuteAll,
          avatar: res.avatar,
          joinNeedApproval: res.joinNeedApproval,
        );
        state = AsyncData(newDetail);
        LocalDatabaseService().saveConversationDetail(newDetail);
      }
    } catch (e, stack) {
      return Future.error(e, stack);
    }
  }

  /// Increments the pending request counter locally for real-time red dot updates
  void handleNewJoinRequest() {
    if (!state.hasValue || state.value == null) return;

    final currentDetail = state.requireValue;
    final newCount = currentDetail.pendingRequestCount + 1;
    final newDetail = currentDetail.copyWith(pendingRequestCount: newCount);

    state = AsyncData(newDetail);
    LocalDatabaseService().saveConversationDetail(newDetail);
  }

  /// Resets the pending request counter after viewing or handling requests
  void resetRequestCount() {
    if (!state.hasValue) return;

    final currentDetail = state.requireValue;
    if (currentDetail.pendingRequestCount == 0) return;

    final newDetail = currentDetail.copyWith(pendingRequestCount: 0);
    state = AsyncData(newDetail);
    LocalDatabaseService().saveConversationDetail(newDetail);
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

  // --- 4. Internal Synchronization Helpers ---

  Future<ConversationDetail> _fetchAndSync(
      String id, {
        bool useJitter = false,
      }) async {
    if (_isSyncing || !_mounted)
      return state.value ?? await Api.chatDetailApi(id);
    _isSyncing = true;

    try {
      if (useJitter) {
        // Random delay (0-3s) to prevent thundering herd on server
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
// Group Creation Controller
// ===========================================================================

@riverpod
class GroupCreateController extends _$GroupCreateController {
  @override
  FutureOr<String?> build() => null;

  Future<String?> create({
    required String name,
    required List<String> memberIds,
  }) async {
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

/// Provider for fetching pending join requests for a specific group
@riverpod
Future<List<GroupJoinRequestItem>> groupJoinRequests(
    GroupJoinRequestsRef ref,
    String groupId,
    ) async {
  return await ChatGroupApi.getJoinRequests(groupId);
}

/// Controller responsible for handling individual applications and join actions
@riverpod
class GroupJoinController extends _$GroupJoinController {
  @override
  FutureOr<void> build() {
    // Keep alive to prevent auto-dispose during asynchronous operations
    // which leads to "Bad state: Future already completed" errors.
    ref.keepAlive();
  }

  /// Admin action: Accept or reject a specific join request
  Future<bool> handleRequest({
    required String groupId,
    required String requestId,
    required bool isAccept,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ChatGroupApi.handleJoinRequest(
        requestId: requestId,
        isAccept: isAccept,
      );
      // Invalidate list provider to trigger UI refresh
      ref.invalidate(groupJoinRequestsProvider(groupId));
    });

    return !state.hasError;
  }

  /// User action: Submit an application to join a group
  Future<ApplyToGroupRes?> apply(String groupId, String reason) async {
    state = const AsyncLoading();
    ApplyToGroupRes? result;

    state = await AsyncValue.guard(() async {
      result = await ChatGroupApi.applyToGroup(
        conversationId: groupId,
        reason: reason,
      );
    });
    return result;
  }
}