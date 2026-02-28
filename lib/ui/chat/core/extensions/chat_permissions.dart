import '../../models/conversation.dart';

extension ChatListExt on List<ChatMember> {
  //  only list can have this method, not ChatMember itself, because we need to search through the list
  ChatMember? findMember(String userId) {
    try {
      return firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }
}