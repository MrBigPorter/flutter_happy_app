abstract class SocketEvents {
  // 🚫 禁止实例化
  SocketEvents._();

  //聊天相关
  /// 收到新消息
  static const String chatMessage = 'chat_message';
  /// 消息已读回执 (对方读了我的消息)
  static const String conversationRead = 'conversation_read';

   /// 对方正在输入... (未来扩展)
   static const String typing = 'typing';

  /// 加入房间 (连接成功后必须加入)
   static const String joinChat = 'join_chat';

   /// 离开房间
  static const String leaveChat = 'leave_chat';

  /// 加入大厅 (连接成功后必须加入)
  static const String joinLobby = 'join_lobby';
  /// 离开大厅
  static const String leaveLobby = 'leave_lobby';

  /// 消息发送结果
  static const String sendMessage = 'send_message';

  // ==========================
  // 📢 系统通知 (System)
  // ==========================
  /// 异常报错
  static const String error = 'error';

  /// 强制下线 (多端登录互踢)
  static const String forceLogout = 'force_logout';
}