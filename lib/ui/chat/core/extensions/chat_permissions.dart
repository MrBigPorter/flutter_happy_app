import 'package:flutter_app/ui/chat/models/conversation.dart';

extension ChatPermissions on List<ChatMember> {

  // it's me
  ChatMember? me(String myUserId) {
    try {
      return firstWhere((m) => m.userId == myUserId);
    } catch (_) {
      return null;
    }
  }

  bool canManage(String myUserId, ChatMember target) {
    final myMember = me(myUserId);
    if (myMember == null) return false;
    if (target.userId == myUserId) return false; // 不能动自己

    return myMember.role.canManageMembers(target.role);
  }
}