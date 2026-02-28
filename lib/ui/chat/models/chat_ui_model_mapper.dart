import 'chat_ui_model.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

class ChatUiModelMapper {
  /// Maps a raw API ChatMessage entity into a standardized ChatUiModel for the view layer.
  static ChatUiModel fromApiModel(
      ChatMessage apiMsg,
      String conversationId, [
        String? currentUserId,
      ]) {

    // Determine the strongly-typed MessageType from the raw integer value
    MessageType uiType = MessageType.fromValue(apiMsg.type);

    // Architectural Defense: Strictly pass through the recalled status
    // without coupling it to MessageType.system.
    bool? isRecalled = apiMsg.isRecalled;

    final Map<String, dynamic> meta = apiMsg.meta ?? {};

    // Identity check: Determine if the message was sent by the current user
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
      // API messages are assumed to be successfully delivered
      status: MessageStatus.success,
      createdAt: apiMsg.createdAt,
      senderName: apiMsg.sender?.nickname,
      senderAvatar: apiMsg.sender?.avatar,
      isRecalled: isRecalled ?? false,
      conversationId: conversationId,
      // Safely parse duration from metadata if present (common for audio/video)
      duration: meta['duration'] is num ? (meta['duration'] as num).toInt() : null,
      meta: meta,
    );
  }
}