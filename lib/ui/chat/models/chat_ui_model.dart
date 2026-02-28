import 'dart:typed_data';
import 'package:equatable/equatable.dart';
export 'chat_ui_model_ext.dart';
export 'chat_ui_model_mapper.dart';

enum MessageStatus { sending, success, failed, read, pending }

enum MessageType {
  text(0, label:'[Text]'),
  image(1, label:'[Image]'),
  audio(2, label:'[Audio]'),
  video(3, label:'[Video]'),
  recalled(4, label:'[Recalled]'),
  file(5, label:'[File]'),
  location(6, label:'[Location]'),
  system(99, label:'[System]');

  final int value;
  final String label;

  const MessageType(this.value, {required this.label});

  static MessageType fromValue(int value) => MessageType.values.firstWhere(
        (e) => e.value == value,
    orElse: () => MessageType.text,
  );

  /// Generates the preview text for the conversation list.
  /// [content]: The raw message content.
  /// [isRecalled]: High-priority flag indicating the message has been recalled.
  String getPreviewText(String content, {bool isRecalled = false}) {
    // Priority 1: If marked as recalled or type is recalled, return standard recalled text.
    if (isRecalled || this == MessageType.recalled) {
      return '[Message Recalled]';
    }

    // Priority 2: For text or system messages, return the raw content.
    if (this == MessageType.text || this == MessageType.system) {
      return content;
    }

    // Priority 3: For multimedia types, return the predefined label.
    return label;
  }
}

class ChatUiModel extends Equatable {
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

  // Physical resource paths and memory-resident states
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

  @override
  List<Object?> get props => [
    id,
    content,
    status,
    localPath,
    resolvedPath,
    previewBytes,
    meta,
    seqId,
    isRecalled,
  ];

  // --- Persistence Logic ---

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

  /// Merges server-side message data with local state.
  /// Prioritizes local physical resources (localPath, previewBytes) over null server values.
  ChatUiModel merge(ChatUiModel serverMsg) {
    return copyWith(
      // 1. Status: Trust the server (e.g., transition from 'sending' to 'success')
      status: serverMsg.status == MessageStatus.success ? MessageStatus.success : status,

      // 2. Resource Protection: Servers do not provide localPaths; preserve local ones.
      localPath: (serverMsg.localPath != null && serverMsg.localPath!.isNotEmpty)
          ? serverMsg.localPath
          : localPath,

      // 3. In-memory data: Servers rarely provide byte arrays; retain local placeholders.
      previewBytes: (serverMsg.previewBytes != null && serverMsg.previewBytes!.isNotEmpty)
          ? serverMsg.previewBytes
          : previewBytes,

      isRecalled: serverMsg.isRecalled,

      // 4. Overwrite other fields with authoritative server data
      seqId: serverMsg.seqId ?? seqId,
      content: serverMsg.content.isNotEmpty ? serverMsg.content : content,

      // Prevent overwriting existing metadata (dimensions, etc.) if server provides an empty map
      meta: (serverMsg.meta == null || serverMsg.meta!.isEmpty) ? meta : serverMsg.meta,

      createdAt: serverMsg.createdAt > 0 ? serverMsg.createdAt : createdAt,
    );
  }

  // --- CopyWith ---

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

  /// Recall Permission Logic:
  /// 1. Only messages with 'read' or 'success' status can be recalled.
  /// 2. Must be within a 2-minute time window from creation.
  bool get canRecall {
    if (status != MessageStatus.read && status != MessageStatus.success) return false;

    final sendTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
    final now = DateTime.now();
    final diff = now.difference(sendTime);

    return diff.inMinutes < 2;
  }
}