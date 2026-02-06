import 'dart:typed_data';
export 'chat_ui_model_ext.dart';
export 'chat_ui_model_mapper.dart';

enum MessageStatus { sending, success, failed, read, pending }

enum MessageType {
  text(0),
  image(1),
  audio(2),
  video(3),
  recalled(4),
  file(5),
  location(6),
  system(99);

  final int value;

  const MessageType(this.value);

  static MessageType fromValue(int value) => MessageType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => MessageType.text,
  );
}

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

  // 物理资源与内存状态
  final String? resolvedPath;
  final String? resolvedThumbPath;
  final Uint8List? previewBytes;
  final String? localPath;
  final int? duration;
  final bool isRecalled;
  final Map<String, dynamic>? meta;

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
    this.previewBytes,
    this.duration,
    this.meta,
    this.resolvedPath,
    this.resolvedThumbPath,
  });

  // --- 持久化逻辑 (逻辑保持不变) ---
  Map<String, dynamic> toJson() => {
    'id': id,
    'seqId': seqId,
    'content': content,
    'type': type.name,
    'isMe': isMe,
    'status': status.name,
    'createdAt': createdAt,
    'senderAvatar': senderAvatar,
    'senderName': senderName,
    'conversationId': conversationId,
    'previewBytes': previewBytes?.toList(),
    'localPath': localPath,
    'duration': duration,
    'isRecalled': isRecalled,
    'meta': meta,
  };

  factory ChatUiModel.fromJson(Map<String, dynamic> json) {
    return ChatUiModel(
      id: json['id'] as String,
      seqId: json['seqId'] as int?,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      isMe: json['isMe'] as bool,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.pending,
      ),
      createdAt: json['createdAt'] as int,
      senderAvatar: json['senderAvatar'] as String?,
      senderName: json['senderName'] as String?,
      conversationId: json['conversationId'] as String,
      previewBytes: json['previewBytes'] != null
          ? Uint8List.fromList((json['previewBytes'] as List).cast<int>())
          : null,
      localPath: json['localPath'] as String?,
      duration: json['duration'] as int?,
      isRecalled: json['isRecalled'] as bool? ?? false,
      meta: json['meta'] as Map<String, dynamic>? ?? {},
    );
  }

  // --- CopyWith (保持不变) ---
  ChatUiModel copyWith({
    String? id,
    int? seqId,
    String? content,
    MessageType? type,
    bool? isMe,
    MessageStatus? status,
    int? createdAt,
    String? senderAvatar,
    String? senderName,
    String? conversationId,
    Uint8List? previewBytes,
    String? localPath,
    int? duration,
    bool? isRecalled,
    Map<String, dynamic>? meta,
    String? resolvedPath,
    String? resolvedThumbPath,
  }) {
    return ChatUiModel(
      id: id ?? this.id,
      seqId: seqId ?? this.seqId,
      content: content ?? this.content,
      type: type ?? this.type,
      isMe: isMe ?? this.isMe,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderName: senderName ?? this.senderName,
      conversationId: conversationId ?? this.conversationId,
      previewBytes: previewBytes ?? this.previewBytes,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      isRecalled: isRecalled ?? this.isRecalled,
      meta: meta ?? this.meta,
      resolvedPath: resolvedPath ?? this.resolvedPath,
      resolvedThumbPath: resolvedThumbPath ?? this.resolvedThumbPath,
    );
  }


}
