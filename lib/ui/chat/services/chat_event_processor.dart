import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/core/store/user_store.dart';
import 'package:flutter_app/ui/modal/base/nav_hub.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/common.dart';
import '../../../core/constants/socket_events.dart';
import '../../../core/providers/socket_provider.dart';
import '../../chat/repository/message_repository.dart';
import '../../chat/providers/conversation_provider.dart';
import '../../chat/providers/chat_group_provider.dart';
import '../models/conversation.dart';

/// Global Provider initialized at App startup to process background chat signals
final chatEventProcessorProvider = Provider<ChatEventProcessor>((ref) {
  return ChatEventProcessor(ref);
});

class ChatEventProcessor {
  final Ref ref;

  ChatEventProcessor(this.ref) {
    _startListening();
  }

  /// Establishes the primary subscription to the group event stream
  void _startListening() {
    final socketService = ref.read(socketServiceProvider);

    socketService.groupEventStream.listen((event) async {
      debugPrint(
        "[ChatEventProcessor] Raw event received: ${event.type} | GroupID: ${event.groupId}",
      );
      await _handleGlobalEvent(event);
    });
  }

  /// Global dispatcher: Handles data persistence, UI state updates, and navigation logic
  Future<void> _handleGlobalEvent(SocketGroupEvent event) async {
    final myId = ref.read(userProvider)?.id;
    final groupId = event.groupId;

    // Use strongly-typed payload to avoid manual map parsing
    final payload = event.payload;
    final repo = ref.read(messageRepositoryProvider);

    if (myId == null) return;

    // Scenario: User invited to a new group (local database currently lacks this record)
    if (event.type == SocketEvents.conversationAdded) {
      try {
        // 1. Fetch comprehensive group details (Metadata + Members)
        final detail = await Api.chatDetailApi(groupId);

        // 2. Persist to local database (MessageRepository)
        await repo.saveGroupDetail(detail);

        // 3. Refresh conversation list to show the new entry
        ref.read(conversationListProvider.notifier).refresh();
      } catch (e) {
        debugPrint("[ChatEventProcessor] Pre-loading new group data failed: $e");
      }
      return;
    }

    // ========================================================
    // 1. Optimistic UI Layer (Immediate State Notification)
    // ========================================================

    // Notify the conversation list to update titles/avatars or remove items immediately
    ref.read(conversationListProvider.notifier).handleSocketEvent(event);

    // Update group-specific states (e.g., muting status, member count)
    ref.read(chatGroupProvider(groupId).notifier).handleSocketEvent(event);

    // ========================================================
    // 2. Data Persistence Layer (Local DB Synchronicity)
    // ========================================================

    switch (event.type) {
    // --- Destructive Events: Cleanup local records ---
      case SocketEvents.groupDisbanded:
        await repo.deleteConversation(groupId);
        ref.read(conversationListProvider.notifier).refresh();
        break;

      case SocketEvents.memberKicked:
      case SocketEvents.memberLeft:
        if (payload.targetId == myId) {
          // Self was kicked or left: purge local conversation records
          await repo.deleteConversation(groupId);
          ref.read(conversationListProvider.notifier).refresh();
        } else {
          // Other member left: perform atomic removal without full API re-fetch
          if (payload.targetId != null) {
            await repo.removeMemberFromGroup(groupId, payload.targetId!);
          }
        }
        break;

    // --- Metadata Updates: Syncing conversation attributes ---
      case SocketEvents.groupInfoUpdated:
        await repo.updateConversationInfo(
          groupId,
          name: payload.updates['name'],
          avatar: payload.updates['avatar'],
          announcement: payload.updates['announcement'],
        );
        break;

    // --- Permission & Membership State Shifts ---
      case SocketEvents.memberMuted:
        if (payload.targetId != null && payload.mutedUntil != null) {
          await repo.updateMemberMuted(
            groupId,
            payload.targetId!,
            payload.mutedUntil!,
          );
        }
        break;

      case SocketEvents.ownerTransferred:
      // Strategic: Atomic transfer of ownership (Old owner -> Admin/Member; New owner -> Owner)
        if (payload.operatorId != null && payload.targetId != null) {
          await repo.transferOwner(
            groupId,
            oldOwnerId: payload.operatorId!,
            newOwnerId: payload.targetId!,
          );
        } else {
          // Fallback to full sync if payload data is insufficient
          _scheduleDetailSync(groupId);
        }
        break;

      case SocketEvents.memberRoleUpdated:
        if (payload.targetId != null && payload.newRole != null) {
          await repo.updateMemberRole(
            groupId,
            payload.targetId!,
            payload.newRole!,
          );
        }
        break;

      case SocketEvents.memberJoined:
      // Optimization: Insert member directly if payload is complete; avoid thundering herd on API
        if (payload.member != null) {
          await repo.addMemberToGroup(groupId, payload.member!);
        } else {
          _scheduleDetailSync(groupId);
        }
        break;

    // --- Group Application System (Membership Approval) ---
      case SocketEvents.groupApplyNew:
      // Trigger invalidation to force re-fetch of joining requests
        ref.invalidate(groupJoinRequestsProvider(groupId));
        ref.read(chatGroupProvider(groupId).notifier).handleNewJoinRequest();
        break;

      case SocketEvents.groupApplyResult:
        if (payload.approved == true) {
          ref.read(conversationListProvider.notifier).refresh();
          ref.invalidate(chatGroupProvider(groupId));
        }
        break;

      case SocketEvents.groupRequestHandled:
      // Sync button states if another administrator handled the request
        ref.invalidate(groupJoinRequestsProvider(groupId));
        break;
    }

    // ========================================================
    // 3. Interaction Layer (Navigation & Side Effects)
    // ========================================================

    _handleNavigationSideEffects(event, myId, payload.targetId);
  }

  /// Evaluates complex state changes for eventual consistency
  void _scheduleDetailSync(String groupId) {
    // Scheduled for eventual consistency: used for high-frequency entry/exit scenarios
    debugPrint("[ChatEventProcessor] Complex change detected; recommending deferred sync for: $groupId");
  }

  /// Manages navigation side effects (e.g., forced exit from a disbanded room)
  void _handleNavigationSideEffects(
      SocketGroupEvent event,
      String myId,
      String? targetId,
      ) {
    final String location = appRouter.routeInformationProvider.value.uri.toString();
    final bool isViewingThisGroup = location.contains(event.groupId!);

    if (!isViewingThisGroup) return;

    final context = NavHub.key.currentContext;
    if (context == null) return;

    switch (event.type) {
      case SocketEvents.memberKicked:
      case SocketEvents.groupDisbanded:
      // Redirect to conversation list if current room is no longer accessible
        appRouter.go('/conversations');
        break;
    }
  }

  /// Force-syncs group detail cache from the remote server
  Future<void> _updateGroupDetailCache(String groupId) async {
    try {
      final repo = ref.read(messageRepositoryProvider);
      final detail = await Api.chatDetailApi(groupId);
      await repo.saveGroupDetail(detail);
    } catch (e) {
      debugPrint("[ChatEventProcessor] Sync group detail failed: $e");
    }
  }
}