import 'chat_ui_model.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

class ChatUiModelMapper {
  static ChatUiModel fromApiModel(
      ChatMessage apiMsg,
      String conversationId, [
        String? currentUserId,
      ]) {
    MessageType uiType = MessageType.fromValue(apiMsg.type);

    // [修正] 严格透传状态，不要跟 MessageType.system 挂钩
    bool isRecalled = apiMsg.isRecalled;

    print('Mapping API message ID: ${apiMsg.id}, type: ${apiMsg.type}, isRecalled: $isRecalled');

    final Map<String, dynamic> meta = apiMsg.meta ?? {};

    bool isMe = apiMsg.isSelf;
    if (currentUserId != null && apiMsg.sender?.id == currentUserId) {
      isMe = true;
    }

    return ChatUiModel(
      id: apiMsg.id.toString(),
      seqId: apiMsg.seqId,
      content: apiMsg.content,
      type: uiType,
      isMe: isMe,
      status: MessageStatus.success,
      createdAt: apiMsg.createdAt,
      senderName: apiMsg.sender?.nickname,
      senderAvatar: apiMsg.sender?.avatar,
      isRecalled: isRecalled,
      conversationId: conversationId,
      duration: meta['duration'] is num ? (meta['duration'] as num).toInt() : null,
      meta: meta,
    );
  }
}