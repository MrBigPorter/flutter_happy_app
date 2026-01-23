import 'package:json_annotation/json_annotation.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';

part 'chat_ui_model.g.dart';

enum MessageStatus {
  @JsonValue('sending') sending,
  @JsonValue('success') success,
  @JsonValue('failed') failed,
  @JsonValue('read') read
}

enum MessageType {
  @JsonValue(0) text(0),     // 👈 改为 0
  @JsonValue(1) image(1),    // 👈 改为 1
  @JsonValue(2) audio(2),    // 👈 改为 2
  @JsonValue(3) video(3),    // 👈 改为 3
  @JsonValue(4) recalled(4), // 👈 新增撤回类型，对应后端 4
  @JsonValue(99) system(99);

  final int value;
  const MessageType(this.value);

  static MessageType fromValue(int value) {
    return MessageType.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

@JsonSerializable() //  1. 加上这个注解
class ChatUiModel {
  final String id;
  final int? seqId;
  final String content;

  // 这里的 Enum 会被自动转成 @JsonValue 里定义的数字
  final MessageType type;
  final bool isMe;
  final MessageStatus status;
  final int createdAt;
  final String? senderAvatar;
  final String? senderName;
  final String conversationId;
  final String? localPath;
  final double? width;
  final double? height;
  final bool isRecalled;

  ChatUiModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.success,
    required this.createdAt,
    required this.conversationId,
    this.isRecalled = false,
    this.senderAvatar,
    this.senderName,
    this.seqId,
    this.localPath,
    this.width,
    this.height,
  });

  //  2. Sembast 读取数据时必须要用的方法
  factory ChatUiModel.fromJson(Map<String, dynamic> json) =>
      _$ChatUiModelFromJson(json);

  //  3. Sembast 存入数据时必须要用的方法
  Map<String, dynamic> toJson() => _$ChatUiModelToJson(this);


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
    bool? isRecalled,
    String? conversationId,
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
      isRecalled: isRecalled ?? this.isRecalled,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, [String? myUserId]) {
    MessageType uiType = MessageType.fromValue(apiMsg.type);
    bool isRecalled = (uiType == MessageType.system) || (apiMsg.isRecalled);
    final String senderId = apiMsg.sender?.id?.toString() ?? "";
    final String currentId = myUserId?.toString() ?? "";

    //  完美逻辑：有 isSelf 用 isSelf，没有就比对 ID
    bool isMe = apiMsg.isSelf ?? (senderId.isNotEmpty && senderId == currentId);

    return ChatUiModel(
      id: apiMsg.id.toString(),
      seqId: apiMsg.seqId,
      content: apiMsg.content ?? "",
      type: uiType,
      isMe: isMe,
      status: MessageStatus.success,
      createdAt: apiMsg.createdAt ?? 0,
      senderName: apiMsg.sender?.nickname,
      senderAvatar: apiMsg.sender?.avatar,
      isRecalled: isRecalled,
      localPath: null,
      conversationId: "",
    );
  }
}