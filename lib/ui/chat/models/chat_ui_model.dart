
import 'package:flutter_app/ui/chat/models/conversation.dart';

enum MessageStatus { sending, success, failed, read }
enum MessageType {
  text(1),
  image(2),
  audio(3),
  video(4),
  system(99);

  // 1. 定义一个成员变量存数值
  final int value;

  // 2. 构造函数 (必须是 const)
  const MessageType(this.value);

  // 4. 🛠️ 辅助方法: 从 int 转回 Enum (给 fromApiModel 用)
  static MessageType fromValue(int value){
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text, // 默认兜底
    );
  }
}

class ChatUiModel {
  final String id;        // 消息唯一ID (前端生成 UUID 或 后端返回 ID)
  final int? seqId;     // 可选的序列号 (用于有序消息),这是水位线比对的关键
  final String content;   // 内容
  final MessageType type; // 类型
  final bool isMe;        // 是否是我发的
  final MessageStatus status; // 发送状态
  final int createdAt;    // 时间戳
  final String? senderAvatar; // 对方头像 (群聊用)
  final String? senderName;   // 对方昵称

  //  新增：本地文件路径 (用于发送图片时的“乐观更新”)
  // 当 localPath 不为空时，UI 优先渲染 File(localPath)，而不是 NetworkImage(content)
  final String? localPath;

  //  新增：图片宽高 (可选，用于优化列表跳动问题)
  final double? width;
  final double? height;

  ChatUiModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.success,
    required this.createdAt,
    this.senderAvatar,
    this.senderName,
    this.seqId,
    this.localPath,
    this.width,
    this.height,
  });

  // 用于更新状态 (例如 sending -> success)
  ChatUiModel copyWith({
    String? id,
    String? content,
    MessageType? type,
    bool? isMe,
    MessageStatus? status,
    int? createdAt,
    String? senderAvatar,
    String? senderName,
    int? seqId,
    String? localPath,
    double? width,
    double? height,
  }) {
    return ChatUiModel(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
      seqId: seqId ?? this.seqId,
      localPath: localPath ?? this.localPath,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, String myUserId) {

    // 1. 判断是不是我发的
    final isMe = apiMsg.sender?.id == myUserId;

    //  修正点：直接调用 Enum 自带的转换方法
    // 不要再手写 _mapIntToType 了，容易写错
    MessageType uiType = MessageType.fromValue(apiMsg.type);

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