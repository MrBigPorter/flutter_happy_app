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
  /// Contact request applied
  static const String contactApply = 'contact_apply';
  /// Contact request accepted
  static const String contactAccept = 'contact_accept';
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