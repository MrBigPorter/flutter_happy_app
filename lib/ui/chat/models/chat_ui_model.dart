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
  @JsonValue(0) text(0),
  @JsonValue(1) image(1),
  @JsonValue(2) audio(2),
  @JsonValue(3) video(3),
  @JsonValue(4) recalled(4),
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

@JsonSerializable()
class ChatUiModel {
  final String id;
  final int? seqId;
  final String content;
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
  final int? duration;

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
    this.duration,
  });

  factory ChatUiModel.fromJson(Map<String, dynamic> json) =>
      _$ChatUiModelFromJson(json);

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
    int? duration,
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
      duration: duration ?? this.duration,
    );
  }

  //  核心修改在这里
  factory ChatUiModel.fromApiModel(ChatMessage apiMsg, String conversationId, [String? myUserId]) {
    MessageType uiType = MessageType.fromValue(apiMsg.type);
    bool isRecalled = (uiType == MessageType.system) || (apiMsg.isRecalled);

    // 1. 安全提取 meta
    final Map<String, dynamic> meta = apiMsg.meta ?? {};

    // 2. 这里的 duration 从 meta 里取
    // 注意：JSON 里的数字有时候会是 double，强转 int 比较安全
    final int? metaDuration = meta['duration'] is int
        ? meta['duration']
        : (meta['duration'] as num?)?.toInt();

    bool isMe = apiMsg.isSelf;

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
      localPath: null,
      conversationId: conversationId,

      //  赋值：使用从 meta 里拿到的时长
      duration: metaDuration,
    );
  }
}