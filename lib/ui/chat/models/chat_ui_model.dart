
import 'package:flutter_app/ui/chat/models/conversation.dart';

enum MessageStatus { sending, success, failed }
enum MessageType { text, image, audio, video, system }

class ChatUiModel {
  final String id;        // 消息唯一ID (前端生成 UUID 或 后端返回 ID)
  final String content;   // 内容
  final MessageType type; // 类型
  final bool isMe;        // 是否是我发的
  final MessageStatus status; // 发送状态
  final int createdAt;    // 时间戳
  final String? senderAvatar; // 对方头像 (群聊用)
  final String? senderName;   // 对方昵称

  ChatUiModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.success,
    required this.createdAt,
    this.senderAvatar,
    this.senderName,
  });

  // 用于更新状态 (例如 sending -> success)
  ChatUiModel copyWith({MessageStatus? status, String? id}) {
    return ChatUiModel(
      id: id ?? this.id,
      content: content,
      type: type,
      isMe: isMe,
      status: status ?? this.status,
      createdAt: createdAt,
      senderAvatar: senderAvatar,
      senderName: senderName,
    );
  }

  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, String myUserId) {

    // 1. 判断是不是我发的
    final isMe = apiMsg.sender?.id == myUserId;

    // 2. 映射类型 (int -> Enum)
    MessageType uiType = MessageType.text;
    if (apiMsg.type == 1) uiType = MessageType.image;
    if(apiMsg.type == 2) uiType = MessageType.audio;
    if(apiMsg.type == 3) uiType = MessageType.video;
    if(apiMsg.type == 99) uiType = MessageType.system;



    return ChatUiModel(
      id: apiMsg.id,
      content: apiMsg.content,
      type: uiType,
      isMe: isMe,
      status: MessageStatus.success, // 来自后端的肯定成功了
      createdAt: apiMsg.createdAt,
      senderName: apiMsg.sender?.nickname, // 直接拿出来，方便 UI 用
      senderAvatar: apiMsg.sender?.avatar,
    );
  }

}