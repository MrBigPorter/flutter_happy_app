import '../../models/conversation.dart';

extension ChatListExt on List<ChatMember> {
  //  只有 List 才能做的事：根据 ID 找到成员对象
  ChatMember? findMember(String userId) {
    try {
      return firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }
}