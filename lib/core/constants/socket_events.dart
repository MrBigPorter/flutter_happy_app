abstract class SocketEvents {
  // Prohibition of instantiation
  SocketEvents._();

  // ----------------------------------------------------------------------
  //  Core: Unified Dispatch Event (Backend emits this event name)
  // ----------------------------------------------------------------------
  static const String dispatch = 'dispatch';

  // ----------------------------------------------------------------------
  //  Event Types (These are now values for the 'type' field in the payload)
  // ----------------------------------------------------------------------

  // --- Chat Related ---
  /// Received new message
  static const String chatMessage = 'chat_message';

  /// Message read receipt
  static const String conversationRead = 'conversation_read';

  /// Message recall notification
  static const String messageRecall = 'message_recalled';

  /// Avatar/Info update notification
  static const String conversationUpdated = 'conversation_updated';
  static const String conversationAdded = 'conversation_added';

  /// Contact request applied
  static const String contactApply = 'contact_apply';

  /// Contact request accepted
  static const String contactAccept = 'contact_accept';

  // --- Group Related ---
  /// Group member role changes (kicked, muted, owner transferred, role updated)
  static const String memberKicked = 'member_kicked';

  /// Group member mute notification
  static const String memberMuted = 'member_muted';

  /// Group owner transferred
  static const String ownerTransferred = 'owner_transferred';

  /// Group member role updated (e.g., promoted to admin)
  static const String memberRoleUpdated = 'member_role_updated';

  /// Group membership changes (joined/left)
  static const String memberJoined = 'member_joined';

  /// Group member left
  static const String memberLeft = 'member_left';

  /// Group disbanded
  static const String groupDisbanded = 'group_disbanded';

  /// Group information updated (name, announcement, global mute, etc.)
  static const String groupInfoUpdated = 'group_info_updated';

  /// New group application received (for groups that require approval)
  static const String groupApplyNew = 'group_apply_new';

  /// Group application result (approved/rejected)
  static const String groupApplyResult = 'group_apply_result';

  /// Group application handled (admin has processed the application)
  static const String groupRequestHandled = 'group_request_handled';

  /// Typing indicator
  static const String typing = 'typing';

  // --- Business/System Notifications ---
  static const String groupSuccess = 'group_success';
  static const String groupFailed = 'group_failed';
  static const String groupUpdate = 'group_update';
  static const String walletChange = 'wallet_change';

  /// Exception error
  static const String error = 'error';

  /// Force logout (kick)
  static const String forceLogout = 'force_logout';

  // ----------------------------------------------------------------------
  //  Client Emission Events (Client emits these to server)
  // ----------------------------------------------------------------------
  /// Join room
  static const String joinChat = 'join_chat';

  /// Leave room
  static const String leaveChat = 'leave_chat';

  /// Join lobby
  static const String joinLobby = 'join_lobby';

  /// Leave lobby
  static const String leaveLobby = 'leave_lobby';

  /// Send message
  static const String sendMessage = 'send_message';
}

class SocketSyncTypes {
  static const String fullSync = 'full_sync'; // 全量同步
  static const String memberSync = 'member_sync'; // 仅同步成员
  static const String infoSync = 'info_sync'; // 仅同步信息
  static const String patch = 'patch'; // 增量更新 (直接用 Payload)
  static const String remove = 'remove'; // 移除
}
